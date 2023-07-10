import Foundation
import ReplaceableLogger

public typealias FetchClosure<Item, Filter> = (_ page: Int, _ count: Int, Filter?) async throws -> [Item]

public enum PaginatorLoadingState: Equatable {
	case initial
	/// There is no loading at the moment.
	case notLoading
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
}

public class Paginator<Item, Filter> {

	/**
	 A filter to be applied in `fetchClosure`.
	 */
	var filter: Filter? {
		didSet { onFilterChanged() }
	}
	
	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public internal(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress
	 */
	@Published public private(set) var loadingState = PaginatorLoadingState.initial
	
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
	public private(set) var page: Int
	
	private var fetchClosure: FetchClosure<Item, Filter>
	
	private var logger: Logger
	
	private var fetchTask: Task<Void, Error>?
	
	public init(
		fetchClosure: @escaping FetchClosure<Item, Filter>,
		itemsPerPage: Int = 50,
		firstPageIndex: Int = 0,
		logger: Logger = DefaultLogger(commonPrefix:"📒")
	) {
		self.fetchClosure = fetchClosure
		self.itemsPerPage = itemsPerPage
		self.firstPageIndex = firstPageIndex
		self.page = firstPageIndex
		self.logger = logger
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
			
			let nextPage = try await fetchClosure(page, itemsPerPage, filter)
			
			guard !Task.isCancelled else { return }
			if cleanBeforeUpdate {
				clearPreviouslyFetchedData()
			}
			receive(nextPage)
			if nextPage.count >= itemsPerPage {
				page += 1
			}
		}
		
		try await fetchTask?.value
	}
	
	public func applyFilter(_ filter: Filter?) async throws {
		try await fetchNextPage(cleanBeforeUpdate: true)
	}
	
	// MARK: - Internal
	
	/**
	 The behaviour is extended in `MutablePaginator` subclass to support local edit operations.
	 */
	func receive(
		_ newItems: [Item]
	) {
		// Use map to handle collisions of items with the same ID
		items = (items + newItems)
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
