import Foundation
import ReplaceableLogger

public class Paginator<Item, Filter> {

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
	
	public let firstPageIndex: Int
	
	/**
	 The next page to be loaded
	 */
	public private(set) var page: Int
	
	private var fetchClosure: FetchClosure<Item, Filter>
	
	private var logger: Logger
	
	public init(
		fetchClosure: @escaping FetchClosure<Item, Filter>,
		itemsPerPage: Int = 30,
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
		loadingState = cleanBeforeUpdate ? .refreshing : .fetchingNextPage
		defer { loadingState = .notLoading }
		let nextPage = try await fetchClosure(page, itemsPerPage, filter)
		if cleanBeforeUpdate {
			clearPreviouslyFetchedData()
		}
		receive(nextPage)
		if nextPage.count >= itemsPerPage {
			page += 1
		}
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
		
		Task {
			try? await fetchNextPage(cleanBeforeUpdate: true)
		}
	}
}
