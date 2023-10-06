import Foundation
import OSLog
import Combine

public enum PaginatorError: Error, Equatable {
	case alreadyInProgress(State)
	
	/**
	 The error means that the last loaded page was incomplete, therefore fetching the next one
	 would be meaningless. (since it would either be empty or lead to skipping the elements in between).
	 
	 In this case, you might want to either refresh the whole thing or re-fetch the last page.
	 */
	case noNextPageAvailable
	
	/**
	 Should never happen; indicates a wrong state transition while starting or finishing an operation.
	 Used for unit testing purposes.
	 */
	case notAnOperation(State)
}

open class Paginator<Item, Filter> {
	
	/**
	 A filter to be applied in `fetchClosure`.
	 */
	open var filter: Filter? {
		didSet { onFilterChanged() }
	}
	
	open internal(set) var configuration: Configuration<Item>
	
	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public internal(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress
	 */
	@Published public private(set) var loadingState: State = .initial

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
	private var cancellables = Set<AnyCancellable>()
	
	private let logger = Logger(subsystem: "Paginator", category: "Paginator<\(Item.self)>")
	private let stateLock = NSLock()
	
	public init(
		_ configuration: Configuration<Item> = .init(),
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
		try start(cleanBeforeUpdate ? .refreshing : .fetchingNextPage)
		
		defer {
			finish(as: .interrupted, onlyIfNotYetFinished: true)
			fetchTask = nil
		}
		
		let result = try await fetchClosure(page, configuration.pageSize, filter)
		
		guard !Task.isCancelled else { return }
		if cleanBeforeUpdate {
			clearPreviouslyFetchedData()
		}

		receive(result.items, merge: configuration.nextPageMerge)
		total = result.totalItems
		
		if result.items.count >= configuration.pageSize {
			page += 1
		}
		
		finish(as: .finished, onlyIfNotYetFinished: true)		
	}
	
	// MARK: - Internal
	
	/**
	 The behaviour is extended in `MutablePaginator` subclass to support local edit operations.
	 */
	func receive(
		_ newItems: [Item],
		merge: MergeProcessor<Item>
	) {
		logger.info( "Items recieved: \(newItems)")
		var editableItems = newItems
		
		configuration.pageTransform?.execute(&editableItems)
		merge.execute(&items, editableItems)
		configuration.resultTransform?.execute(&items)
	}
}

// MARK: - Private
private extension Paginator {

	func start(_ newState: State) throws {
		try stateLock.withLock {
			guard newState.inProgress else { throw PaginatorError.notAnOperation(newState) }
			guard !loadingState.inProgress else { throw PaginatorError.alreadyInProgress(loadingState) }
			loadingState = newState
		}
	}
	
	func finish(
		as newState: State,
		onlyIfNotYetFinished: Bool
	) {
		stateLock.withLock {
			guard !onlyIfNotYetFinished || loadingState.inProgress else { return }
			loadingState = newState
		}
	}
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
