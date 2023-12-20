import Foundation
import OSLog
import Combine

public enum PaginatorError: Error & Equatable {
	case wrongStateTransition(from: PaginatorState, to: PaginatorState)
}

// TODO: Rename to `OffsetPaginator`; add `IdPaginator` and extend support / protocols for both
open class Paginator<Item: Identifiable, Filter>: LocalEditsTracker {
	
	/**
	 A filter to be applied in `fetchClosure`.
	 */
	open var filter: Filter? {
		didSet { onFilterChanged() }
	}

	/// See `LocalEditsTrackingProvider` for details.
	open var localEditsDelta = 0
	
	/// `true` if the last fetched page had fewer elements that `configuration.pageSize`.
	open internal(set) var lastPageIsIncomplete = false
	
	/// Defines the merge logic, page size, etc. (see `Configuration` for more details)
	open internal(set) var configuration: PaginatorConfiguration<Item>

	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public internal(set) var items = [Item]()
	
	@Published public private(set) var state: PaginatorState = .initial

	/**
	 The total count of elements on the remote source (if applicable).
	 */
	@Published public private(set) var total: Int?
	
	/**
	 The next page to be loaded. Calculated as `items.count / configuration.pageSize`.
	 */
	@Published public private(set) var page: Int
	
	
	private var fetchClosure: FetchPageClosure<Item, Filter>
	private var backgroundFetchTask: Task<Void, Error>?
	
	private let logger = Logger(subsystem: "Paginator", category: "Paginator<\(Item.self)>")
	private let stateLock = NSLock()
	
	public var cancellables = Set<AnyCancellable>()
	
	public init(
		_ configuration: PaginatorConfiguration<Item> = .init(),
		fetch: @escaping FetchPageClosure<Item, Filter>
	) {
		self.fetchClosure = fetch
		self.page = configuration.firstPageIndex
		self.configuration = configuration
		
		self.setupSubscriptions()
	}
	
	
	// MARK: - Fetch
	
	/**
	 Fetches data in the background.

	 This method is best used for scenarios where the fetch operation should not
	 block the current thread, such as in UI-related code where responsiveness
	 is crucial. It initiates a fetch operation in a background task. If a fetch is
	 already in progress, the method can either cancel the current fetch and start
	 a new one, or simply return, based on the `force` parameter.

	 For an explicit `async` fetch operation, use the `fetch(_:)` method.

	 - Parameters:
	   - type: The type of fetch operation to perform, defaulting to `.nextPage`.
		 This controls whether the fetch should refresh from the beginning or fetch
		 the next page of data.
	   - force: A Boolean value that determines whether to forcibly cancel any
		 ongoing fetch operation and start a new one. If `false` (the default), and
		 a fetch is already in progress, this method will do nothing.

	 The fetch operation's results are not directly returned by this method but
	 should be handled elsewhere, typically through some form of state observation.

	 This method internally uses an asynchronous task to perform the fetch
	 operation without blocking the calling thread. The `backgroundFetchTask`
	 property holds a reference to this task, allowing it to be cancelled if needed.
	 */
	public func fetchInBackground(
		_ type: FetchType = .nextPage,
		force: Bool = false
	) {	//TODO: cancel last queued task as well
		self.backgroundFetchTask = Task {

			if state.fetchInProgress {
				guard force else { return }
				await cancelCurrentFetch()
			}
			await fetch(type)
		}
	}
	
	/**
	 Perform an `async` fetch operation directly.

	 This method is suitable for when you need more control, esp. over cancellation.

	 Unlike `fetchInBackground(_:)`, this method does not use a background task and
	 will directly execute the async fetch operation.

	 - Parameter type: Defines the type of fetch - most commonly it's either fetching
	   the next page, or a refresh operation (see `FetchType` for details).

	 - Note: This method uses async-await and should be called from an asynchronous
	   context. It will await the completion of the fetch operation, handling state
	   changes and data processing.
	 */
	public func fetch(
		_ type: FetchType = .nextPage
	) async {
		do {
			var alreadyRunning = false
			try stateLock.withLock {
				alreadyRunning = state.fetchInProgress
				guard !alreadyRunning else { return }
				try unsafeChangeState(to: .fetching(type))
			}
			guard !alreadyRunning else { return }
			
			let result = try await fetchClosure(page, configuration.pageSize, filter)
			guard !Task.isCancelled else {
				try safeChangeState(to: .cancelled)
				return
			}
			
			if type == .refresh {
				try safeChangeState(to: .discardingOldData)
				clearPreviouslyFetchedData()
			}
			
			try safeChangeState(to: .processingReceivedData)
			receive(result.items)
			total = result.totalItems
			
			try safeChangeState(to: .finished)
		} catch {
			try! safeChangeState(to: .error(error))
		}
	}
}

public extension Paginator where Item: Identifiable {
	
	// MARK: - In-place edits

	func delete(itemWithID id: Item.ID) {
		items.removeAll { $0.id == id }
	}
	
	func update(item: Item) {
		guard let idx = items.firstIndex(where: { $0.id == item.id} ) else {
			logger.error("Item \("\(item)") not found")
			return
		}
		items[idx] = item
	}
	
	func insert(
		item: Item,
		at idx: Int = 0
	) {
		items.insert(item, at: idx)
	}
}

// MARK: - Private
private extension Paginator {

	func safeChangeState(to newState: PaginatorState) throws {
		try stateLock.withLock {
			try unsafeChangeState(to: newState)
		}
	}
	
	func unsafeChangeState(to newState: PaginatorState) throws {
		guard State.transitionValid(from: state, to: newState) else {
			throw PaginatorError.wrongStateTransition(from: state, to: newState)
		}
		
		state = newState
		if !newState.fetchInProgress { self.backgroundFetchTask = nil }
	}
		
	func receive(_ newItems: [Item]) {
		logger.notice( "Items recieved: \(newItems)")

		lastPageIsIncomplete = newItems.count < configuration.pageSize
		
		var editableItems = newItems
		 
		configuration.pageTransform?.execute(self, &editableItems)
		configuration.merge.execute(self, &items, editableItems)
		configuration.resultTransform?.execute(self, &items)
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
		
		backgroundFetchTask?.cancel()
		Task {
			await fetch(.refresh)
		}
	}
	
	func cancelCurrentFetch() async {
		guard state.fetchInProgress else { return }
		await withCheckedContinuation { continuation in
			$state
				.filter { !$0.fetchInProgress }
				.first()
				.sink { _ in continuation.resume() }
				.store(in: &cancellables)
			backgroundFetchTask?.cancel()
		}
	}
	
	func setupSubscriptions() {
		$items
			.sink { [weak self] newValue in
				guard let self else { return }
				
				let adjustedItemsCount = newValue.count + self.localEditsDelta
				self.page = adjustedItemsCount / self.configuration.pageSize
				self.lastPageIsIncomplete = (adjustedItemsCount > 0 
											 && adjustedItemsCount % self.configuration.pageSize != 0)
			}
			.store(in: &cancellables)
		
		$state
			.sink { [weak self] in
				guard let self else { return }
				self.logger.debug("State changed to \($0)")
			}
			.store(in: &cancellables)

	}
}

extension Paginator: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		"""
count = \(items.count); page = \(page); state = \(state);
config = [\(configuration)]
"""
	}
}
