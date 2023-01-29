import Foundation

public enum PaginatorLoadingState {
	/// There is no loading at the moment.
	case notLoading
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
}


public class Paginator<Item: Comparable & Identifiable> {

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
	public let itemsPerPage = 30
	
	/**
	 The next page to be loaded
	 */
	public private(set) var page = 0
	
	private let fetchService: FetchService<Item>
	
	init(fetchService: FetchService<Item>) {
		self.fetchService = fetchService
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
		print("### \(#file) fetch start")
		guard loadingState == .notLoading else { return }
		loadingState = cleanBeforeUpdate ? .refreshing : .fetchingNextPage
		let nextPage = try await fetchService.fetch(count: itemsPerPage, page: page)
		if cleanBeforeUpdate {
			clearPreviouslyFetchedData()
		}
		if nextPage.count >= itemsPerPage {
			page += 1
		}
		receive(nextPage)
		print("### \(#file) fetch finish")
		loadingState = .notLoading
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
	 Merge with previously fetched `items` (to take care of items with same IDs), sort the resulting array and assign `items` value to it.
	 
	 If duplicated items are found, the value with the latest `updatedAt` is used, and others are discarded.
	 
	 The sort order is  descending, by `updatedAt`. Can be parametrized in case of need.
	 */
	func receive(_ newItemsPage: [Item]) {
		let itemsConcatenated = items + newItemsPage
		// Use map to handle collisions of items with the same ID
		let idToitemMap = itemsConcatenated.reduce(into: [Item.ID: Item]()) { partialResult, item in
			if let existeditem = partialResult[item.id] {
				partialResult[item.id] = [existeditem, item].max()
			} else {
				partialResult[item.id] = item
			}
		}
		items = idToitemMap.values.sorted(by: >)
	}
	
	func clearPreviouslyFetchedData() {
		items = []
		page = 0
	}
	
	func handleError(_ error: Error) {
		// show error
	}

}
