import Foundation
import OSLog
import Combine

public enum PaginatorError: Error & Equatable {
	case alreadyInProgress(State)
	
	/**
	 The error means that the last loaded page was incomplete, therefore fetching the next one
	 would be meaningless. (since it would either be empty or lead to skipping the elements in between).
	 
	 In this case, you might want to either refresh the whole thing or re-fetch the last page.
	 */
	case noNextPageAvailable
}

open class Paginator<Item, Filter>: CancellablesOwner {
	
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
	 The state.
	 */
	@Published public private(set) var state: State = .initial

	/**
	 The total count of elements on the remote source (if applicable).
	 */
	@Published public private(set) var total: Int?
	
	/**
	 The next page to be loaded. Calculated as `items.count / configuration.pageSize`.
	 */
	@Published public private(set) var page: Int
	
	
	private var fetchClosure: FetchPageClosure<Item, Filter>
	private var fetchTask: Task<Void, Error>?
	
	private let logger = Logger(subsystem: "Paginator", category: "Paginator<\(Item.self)>")
	private let stateLock = NSLock()
	
	public var cancellables = Set<AnyCancellable>()
	
	public init(
		_ configuration: Configuration<Item> = .init(),
		fetch: @escaping FetchPageClosure<Item, Filter>
	) {
		self.fetchClosure = fetch
		self.page = configuration.firstPageIndex
		self.configuration = configuration
		
		self.setupStateLogging()
		self.setupSubscriptions()
	}
	
	public func requestFetch(
		_ type: FetchType = .fetchNext,
		force: Bool = false
	) {
		Task {
			if force, state.isOperation {
				await cancelCurrentFetch()
			}
			try await fetch(type)
		}
	}
	/**
	 Fetch the next items page.
	 
	 - Parameter cleanBeforeUpdate: If `true`, makes a "fresh fetch" of the 0 page
	 and replaces the current `items` value with the fetched result on success. The `items` value
	 does not get cleared in case of fetch error.
	 */
	public func fetch(_ type: FetchType = .fetchNext) async throws {
		try start(type)
		
		do {
			let result = try await fetchClosure(page, configuration.pageSize, filter)
			guard !Task.isCancelled else {
				finish(as: .cancelled)
				return
			}
			
			if type == .refresh { clearPreviouslyFetchedData() }

			receive(result.items)
			total = result.totalItems
			finish(as: .finished)
		} catch {
			finish(as: .fetchError(error))
		}
	}
	
	// MARK: - Internal
	
	/**
	 The behaviour is extended in `MutablePaginator` subclass to support local edit operations.
	 */
	func receive(_ newItems: [Item]) {
		logger.info( "Items recieved: \(newItems)")
		var editableItems = newItems
		
		configuration.pageTransform?.execute(&editableItems)
		configuration.merge.execute(&items, editableItems)
		configuration.resultTransform?.execute(&items)
	}
}

// MARK: - Private
private extension Paginator {

	func start(_ type: FetchType) throws {
		try stateLock.withLock {
			guard !state.isOperation else { throw PaginatorError.alreadyInProgress(state) }
			state = .active(type)
		}
	}
	
	func finish(as newState: State) {
		stateLock.withLock {
			guard state.isOperation else { return }
			state = newState
			fetchTask = nil
		}
	}
	/**
	 Reset the paginator data to it's initial state. Does not reset `state` or data that is being processed at the moment, but not yet stored.
	 */
	func clearPreviouslyFetchedData() {
		items = []
		page = 0
	}
	
	func onFilterChanged() {
		guard !items.isEmpty else { return }
		
		fetchTask?.cancel()
		Task {
			try? await fetch(.refresh)
		}
	}
	
	func cancelCurrentFetch() async {
		guard state.isOperation else { return }
		await withCheckedContinuation { continuation in
			$state
				.filter { !$0.isOperation }
				.first()
				.sink { _ in continuation.resume() }
				.store(in: &cancellables)
			fetchTask?.cancel()
		}
	}
	
	func setupSubscriptions() {
		$items
			.sink { [weak self] newValue in
				guard let self else { return }
				self.page = newValue.count / self.configuration.pageSize
			}
			.store(in: &cancellables)
	}
	
	func setupStateLogging() {
		$state
			.sink { [weak self] in
				self?.logger.log("State changed to \($0)")
			}
			.store(in: &cancellables)
	}
}
