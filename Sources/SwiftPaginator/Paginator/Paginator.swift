import Foundation
import OSLog
import Combine

public enum PaginatorError: Error & Equatable {
	case wrongStateTransition(from: State, to: State)
}

open class Paginator<Item, Filter>: LocalEditsTracker, CancellablesOwner {
	
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
	open internal(set) var configuration: Configuration<Item>

	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public internal(set) var items = [Item]()
	
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
	private var backgroundFetchTask: Task<Void, Error>?
	
	private let logger = Logger(subsystem: "Paginator", category: "Paginator<\(Item.self)>")
	private let stateLock = NSLock()
	
	public var cancellables = Set<AnyCancellable>()
	
	public init(
		_ configuration: Configuration<Item>,
		fetch: @escaping FetchPageClosure<Item, Filter>
	) {
		self.fetchClosure = fetch
		self.page = configuration.firstPageIndex
		self.configuration = configuration
		
		self.setupStateLogging()
		self.setupSubscriptions()
	}
	
	
	// MARK: - Fetch
	
	public func fetchInBackground(
		_ type: FetchType = .fetchNext,
		force: Bool = false
	) {
		self.backgroundFetchTask = Task {

			if state.fetchInProgress {
				guard force else { return }
				await cancelCurrentFetch()
			}
			try? await fetch(type, force: force)
		}
	}
	/**
	 Perform a fetch.
	 
	 - Parameter type: Defines the type of fetch - most commonly it's either fetching the last page, or refresh.
	 (see `FetchType` for details)
	 - Parameter force: If `true`, canceles the ongoing fetch request (if there's one), and then executes.
	 */
	public func fetch(
		_ type: FetchType = .fetchNext,
		force: Bool = false
	) async throws {
		guard !state.fetchInProgress else { return }
		
		try changeState(to: .fetching(type))
		do {
			let result = try await fetchClosure(page, configuration.pageSize, filter)
			guard !Task.isCancelled else {
				try changeState(to: .cancelled)
				return
			}
			
			if type == .refresh {
				try changeState(to: .discardingOldData)
				clearPreviouslyFetchedData()
			}
			
			try changeState(to: .processingReceivedData)
			receive(result.items)
			total = result.totalItems
			
			try changeState(to: .finished)
		} catch {
			try! changeState(to: .error(error))
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

	func changeState(to newState: State) throws {
		try stateLock.withLock {
			guard State.transitionValid(from: state, to: newState) else {
				throw PaginatorError.wrongStateTransition(from: state, to: newState)
			}
			
			state = newState
			if !newState.fetchInProgress { self.backgroundFetchTask = nil }
		}
	}
		
	func receive(_ newItems: [Item]) {
		logger.info( "Items recieved: \(newItems)")

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
			try? await fetch(.refresh)
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
	}
	
	func setupStateLogging() {
		$state
			.sink { [weak self] in
				self?.logger.log("State changed to \($0)")
			}
			.store(in: &cancellables)
	}
}
