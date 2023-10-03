import Foundation
import OSLog

public enum PaginatorError: Error {
	case mutlipleMergeProcessors
}

open class Paginator<Item: Identifiable, Filter>: ObservableObject {
	
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
	open var postFetchProcessor: PostFetchProcessor<Item>
	
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
	 The number of items to be included in a single fetch request page.
	 */
	public let itemsPerPage: Int
	
	/**
	 In some applications, pagination may start from `1` instead of the usual `0` index.
	 */
	public let firstPageIndex: Int
	
	/**
	 The next page to be loaded
	 */
	@Published public private(set) var page: Int
	
	private var fetchClosure: FetchPageClosure<Item, Filter>
		
	private var fetchTask: Task<Void, Error>?

	private let logger = Logger(subsystem: "Paginator", category: "Paginator<\(Item.self)>")

	public init(
		itemsPerPage: Int = PaginatorDefaults.itemsPerPage,
		firstPageIndex: Int = PaginatorDefaults.firstPageIndex,
		postFetchProcessor: PostFetchProcessor<Item> = PostFetchProcessor<Item>(),
		fetch: @escaping FetchPageClosure<Item, Filter>
	) {
		self.fetchClosure = fetch
		self.itemsPerPage = itemsPerPage
		self.firstPageIndex = firstPageIndex
		self.page = firstPageIndex
		self.postFetchProcessor = postFetchProcessor
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
		guard [.notLoading, .initial].contains(loadingState) else { return }
		
		fetchTask?.cancel()
		loadingState = cleanBeforeUpdate ? .refreshing : .fetchingNextPage
		fetchTask = Task {
			defer {
				loadingState = .notLoading
				fetchTask = nil
			}
			
			let result = try await fetchClosure(page, itemsPerPage, filter)
			
			guard !Task.isCancelled else { return }
			if cleanBeforeUpdate {
				clearPreviouslyFetchedData()
			}
			try receive(result.items)
			if total != result.totalItems {
				total = result.totalItems
			}
			if items.count >= itemsPerPage {
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
	) throws {
		logger.info( "Items recieved: \(newItems)")
		var editableItems = newItems
		
		postFetchProcessor.pre?(&editableItems)
		postFetchProcessor.merge(&items, &editableItems)
		postFetchProcessor.post?(&items)
	}
}

public extension Paginator {
	
	@available(*, deprecated, message: "Use one of 2 other inits instead (one is just the same but with different params order).")
	convenience init(
		fetchClosure: @escaping FetchPageClosure<Item, Filter>,
		itemsPerPage: Int = PaginatorDefaults.itemsPerPage,
		firstPageIndex: Int = PaginatorDefaults.firstPageIndex
	) {
		self.init(itemsPerPage: itemsPerPage, firstPageIndex: firstPageIndex, fetch: fetchClosure)
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
}
