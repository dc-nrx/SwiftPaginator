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
	open internal(set) var reachedEnd = false
	
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
	@Published public private(set) var nextPage: Int
	
	
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
		self.nextPage = configuration.firstPageIndex
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
			
			let pageNo = (type == .nextPage) ? nextPage : configuration.firstPageIndex
			let result = try await fetchClosure(pageNo, configuration.pageSize, filter)
			guard !Task.isCancelled else {
				try safeChangeState(to: .cancelled(type))
				return
			}
			
			if type == .refresh {
				try safeChangeState(to: .discardingOldData(type))
				clearPreviouslyFetchedData()
			}
			
			try safeChangeState(to: .processingReceivedData(type))
            reachedEnd = result.items.count < configuration.pageSize
			receive(result.items)
			total = result.totalItems
			
			try safeChangeState(to: .finished(type))
		} catch {
			try! safeChangeState(to: .error(error))
		}
	}
}

public extension Paginator where Item: Identifiable {
	
	// MARK: - In-place edits

	/**
	 Delete an item manually.
	 
	 The common use is to reflect the corresponding update
	 on the (remote) source, withouth reloading all content.
	 
	 - Note: If there are several paginators, all of which need to perform this operation,
	 you can use `PaginatorNotifier` insted (see docs for details). In such a case, explicit
	 call of this method would be redundant.
	 */
	func delete(itemWithID id: Item.ID) {
        delete(itemsByID: [id])
	}

    func delete(itemsByID ids: any Collection<Item.ID>) {
        let idsSet = Set(ids)
        var tmpItems = items
        
        tmpItems.removeAll { idsSet.contains($0.id) }
        let countDiff = items.count - tmpItems.count
        items = tmpItems
        if let t = total { total = t - countDiff }
    }

	/**
	 Update an item manually.
	 
	 The common use is to reflect the corresponding update
	 on the (remote) source, withouth reloading all content.
	 
	 - Note: If there are several paginators, all of which need to perform this operation,
	 you can use `PaginatorNotifier` insted (see docs for details). In such a case, explicit
	 call of this method would be redundant.
	 */
	func update(
		_ item: Item,
		moveToTop: Bool = false
	) {
		guard let idx = items.index(for: item.id) else {
			logger.debug("Item \("\(item)") not found")
			return
		}
		if moveToTop {
			// TODO: Unit test why didn't work double set
			var updatedItems = items
			updatedItems.remove(at: idx)
			updatedItems.insert(item, at: 0)
			items = updatedItems			
		} else {
			items[idx] = item
		}
	}
	
	/**
	 Insert an item manually.
	 
	 The common use is to reflect the corresponding update
	 on the (remote) source, withouth reloading all content.
	 
	 - Note: If there are several paginators, all of which need to perform this operation,
	 you can use `PaginatorNotifier` insted (see docs for details). In such a case, explicit
	 call of this method would be redundant.
	 */

	func insert(
		_ item: Item,
		at idx: Int = 0
	) {
		guard items.index(for: item.id) == nil else {
			logger.critical("Item \("\(item)") already present")
			return
		}
		items.insert(item, at: idx)
        if let t = total { total = t + 1 }
	}
}

// MARK: - Private
private extension Paginator {

	// TODO: Move to VM ????
	func process(externalEdit: PaginatorNotifier.Operation<Item>) {
        let itemsExist = !Set(items.map(\.id)).intersection(externalEdit.affectedIDs).isEmpty
		switch (externalEdit, itemsExist) {
		case (.add(let item, let itemParentId), false):
            if parentApplicable(itemParentId) { insert(item) }
		case (.edit(let item, let moveToTop), true):
            update(item, moveToTop: moveToTop)
        case (.deleteMultipleIds(let idsCollection, let itemParentId), true):
            if parentApplicable(itemParentId) { delete(itemsByID: idsCollection) }
        case (.deleteId(let id, let itemParentId), true):
            if parentApplicable(itemParentId) { delete(itemWithID: id) }
		case (.delete(let item, let itemParentId), true):
            if parentApplicable(itemParentId) { delete(itemWithID: item.id) }
		default: break
		}
	}
    
    func parentApplicable(
        _ parentId: PaginatorNotifier.ParentID?
    ) -> Bool {
        configuration.parentId == nil || configuration.parentId == parentId
    }

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
		logger.notice( "\(newItems.count) items recieved")
		
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
		nextPage = 0
	}
	
	func onFilterChanged() {
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
				
				let adjustedItemsCount = newValue.count - self.localEditsDelta
				self.nextPage = configuration.firstPageIndex + adjustedItemsCount / self.configuration.pageSize
			}
			.store(in: &cancellables)
		
		$state
			.sink { [weak self] in
				guard let self else { return }
				self.logger.debug("State changed to \($0)")
			}
			.store(in: &cancellables)

		configuration.notifier?.notificationCenter.publisher(for: .paginatorEditOperation)
			.compactMap { $0.object as? PaginatorNotifier.Operation<Item> }
			.sink { [weak self] in self?.process(externalEdit: $0) }
			.store(in: &cancellables)
	}
}

extension Paginator: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		"""
count = \(items.count); page = \(nextPage); state = \(state); lastPageIncomplete = \(reachedEnd)
config = [\(configuration)]
"""
	}
}
