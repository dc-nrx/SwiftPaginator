import Foundation

public func pp(
	_ str: String,
	file: String = #file,
	function: String = #function,
	line: Int = #line,
	funNameMaxLen: Int = 30
) {
	let funAdjusted: String
	if function.count > funNameMaxLen {
		funAdjusted = function.prefix(27) + "..."
//		funAdjusted = function.prefix(14) + "..." + function.suffix(13)
	} else {
		funAdjusted = function
	}
	let lastPathComponentHighlighted = "[" + URL(string: file)!.lastPathComponent.prefix { $0 != "." } + "]"
	let fileUtf8 = (lastPathComponentHighlighted as NSString).utf8String!
	let funUtf8 = (funAdjusted as NSString).utf8String!
	let strUtf8 = (str as NSString).utf8String!
	let str = String(format: "##  %-20s:%-3d %-\(funNameMaxLen)s  --> %-30s ##", fileUtf8, line, funUtf8, strUtf8)
	print(str)	

}

public typealias PaginatorItem = Comparable & Identifiable

public typealias FetchFunction<Item: PaginatorItem, Filter> = (_ count: Int, _ page: Int, Filter?) async throws -> [Item]

public enum PaginatorLoadingState {
	/// There is no loading at the moment.
	case notLoading
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
}

public actor Paginator<Item: PaginatorItem, Filter> {

	var filter: Filter? {
		didSet { onFilterChanged() }
	}
	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public private(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress
	 */
	@Published public private(set) var loadingState = PaginatorLoadingState.notLoading
	
	/**
	 The number of items to be included in a single fetch request page.
	 */
	public let itemsPerPage: Int
	
	/**
	 The next page to be loaded
	 */
	public private(set) var page = 0
	
	private var injectedFetch: FetchFunction<Item, Filter>
	
	init(
		injectedFetch: @escaping FetchFunction<Item, Filter>,
		itemsPerPage: Int = 30
	) {
		self.injectedFetch = injectedFetch
		self.itemsPerPage = itemsPerPage
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
		guard loadingState == .notLoading else { return }
		pp("FETCH START")
		loadingState = cleanBeforeUpdate ? .refreshing : .fetchingNextPage
		defer { loadingState = .notLoading }
		let nextPage = try await injectedFetch(itemsPerPage, page, filter)
		if cleanBeforeUpdate {
			clearPreviouslyFetchedData()
		}
		receive(nextPage)
		if nextPage.count >= itemsPerPage {
			page += 1
		}
		pp("FETCH STOP")
	}
	
	public func applyFilter(_ filter: Filter?) async throws {
		try await fetchNextPage(cleanBeforeUpdate: true)
	}
	
}

// MARK: - Item Change Events Responder
public extension Paginator {
	
	/**
	 Will have effect **only** if `item.updatedAt` is more recent than `updatedAt` of the one with the same `id` from `items`.
	 If an outdated version of`item` is not present in `items`, the result of the behaviour will be the same for `itemAdded()`.
	 */
	func itemUpdatedLocally(_ item: Item) {
		receive([item])
	}
	
	/**
	 Inserts the `item` into `items`, respecting sort order.
	 */
	func itemAddedLocally(_ item: Item) {
		receive([item])
	}
	
	/**
	 Removes `item` from `items` (if it was there).
	 */
	func itemDeletedLocally(_ item: Item) {
		if let indexToDelete = items.firstIndex(where: { $0.id == item.id } ) {
			items.remove(at: indexToDelete)
		}
	}
}

// MARK: - Private
private extension Paginator {
	
	/**
	 Merge with previously fetched `items` (to take care of items with same IDs), sort the resulting array and update `items` value accordingly.
	 
	 If duplicated items are found, the value with the latest `updatedAt` is used, and others are discarded.
	 
	 The sort order is  descending.
	 
	 - Note: The method can be used for any update
	 */
	func receive(
		_ newItems: [Item]
	) {
		// Use map to handle collisions of items with the same ID
		items = (items + newItems)
			.reduce(into: [Item.ID: Item]()) { partialResult, item in
				if let existeditem = partialResult[item.id] {
					partialResult[item.id] = [existeditem, item].max()
				} else {
					partialResult[item.id] = item
				}
			}
			.values
			.sorted(by: >)
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
		
		Task {
			try? await fetchNextPage(cleanBeforeUpdate: true)
		}
	}
}
