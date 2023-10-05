import Foundation
import OSLog
import Combine

public enum PaginatorError: Error {
	case mutlipleMergeProcessors
}

open class Paginator<Item, Filter> {
	
	/**
	 A filter to be applied in `fetchClosure`.
	 */
	open var filter: Filter? {
		didSet { onFilterChanged() }
	}
	
	/**
	 Operations to apply to newly fetched page, customize merge process, or process the resulting list.
	 Can be used to sort, remove duplicates, etc.
	 */
	open var configuration: PaginatorConfiguration<Item>
	
	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public internal(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress
	 */
	@Published public private(set) var loadingState: PaginatorState = .initial

	/**
	 The total count of elements on the remote source (if applicable).
	 */
	@Published public private(set) var total: Int?
	
	/**
	 The next page to be loaded
	 */
	@Published public private(set) var page: Int
	
	private var fetchClosure: FetchPageClosure<Item, Filter>
	private var fetchTask: Task<Void, Error>?
	private let logger = Logger(subsystem: "Paginator", category: "Paginator<\(Item.self)>")
	private var cancellables = Set<AnyCancellable>()
	private let stateLock = NSLock()
	
	public init(
		_ configuration: PaginatorConfiguration<Item> = .init(),
		fetch: @escaping FetchPageClosure<Item, Filter>
	) {
		self.fetchClosure = fetch
		self.page = configuration.firstPageIndex
		self.configuration = configuration
		
		self.setupStateLogging()
	}
	
	/**
	 Fetch the next items page.
	 
	 - Parameter cleanBeforeUpdate: If `true`, makes a "fresh fetch" of the 0 page
	 and replaces the current `items` value with the fetched result on success. The `items` value
	 does not get cleared in case of fetch error.
	 */
	public func fetchNextPage(
		cleanBeforeUpdate: Bool = false
	) async throws {
		var shouldReturn = false
		stateLock.withLock {
			shouldReturn = loadingState.inProgress
			guard !shouldReturn else { return }
			loadingState = cleanBeforeUpdate ? .refreshing : .fetchingNextPage
		}
		guard !shouldReturn else { return }

		fetchTask?.cancel()
		fetchTask = Task {
			defer {
				loadingState = .finished
				fetchTask = nil
			}
			
			let result = try await fetchClosure(page, configuration.pageSize, filter)
			
			guard !Task.isCancelled else { return }
			if cleanBeforeUpdate {
				clearPreviouslyFetchedData()
			}
			receive(result.items)
			total = result.totalItems
			
			if result.items.count >= configuration.pageSize {
				page += 1
			}
		}
		
		try await fetchTask?.value
	}
	
	// MARK: - Internal
	
	/**
	 The behaviour is extended in `MutablePaginator` subclass to support local edit operations.
	 */
	func receive(
		_ newItems: [Item]
	) {
		logger.info( "Items recieved: \(newItems)")
		var editableItems = newItems
		
		configuration.pageTransform?.execute(&editableItems)
		configuration.merge.execute(&items, editableItems)
		configuration.resultTransform?.execute(&items)
	}
}

// MARK: - Private
private extension Paginator {
	
	/**
	 Reset the paginator data to it's initial state. Does not `loadingState` or data that is being processed at the moment, but not yet stored.
	 */
	func clearPreviouslyFetchedData() {
		items = []
		page = 0
	}
	
	func onFilterChanged() {
		guard !items.isEmpty else { return }
		
		fetchTask?.cancel()
		Task {
			try? await fetchNextPage(cleanBeforeUpdate: true)
		}
	}
	
	func setupStateLogging() {
		$loadingState
			.sink { [weak self] in
				self?.logger.log("State changed to \($0)")
			}
			.store(in: &cancellables)
	}
}
