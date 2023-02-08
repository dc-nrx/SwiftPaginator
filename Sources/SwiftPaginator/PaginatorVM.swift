//
//  PaginatorVM.swift
//
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation
import Combine

/**
 Stores sorted collection of `Item`s and provides relevant fetch operations. Can be used as a view model in either list or grid view.
 */
public actor PaginatorVM<Item: PaginatorItem, Filter>: ObservableObject {
	
	/**
	 A filter applicable to the fetch service used.
	 */
	var filter: Filter?
	
	var itemsPerPage: Int {
		paginator.itemsPerPage
	}
	
	/**
	 The items fetched from `itemFetchService`.
	 */
	@MainActor
	@Published public private(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress
	 */
	@MainActor
	@Published public private(set) var loadingState = PaginatorLoadingState.notLoading

	/**
	 Determines which cell's `didAppear` event (from the end) triggers "fetch next page" request.
	 */
	public let distanceBeforeLoadNextPage: Int
	
	private let paginator: Paginator<Item, Filter>
	
	@MainActor
	private var cancellables = Set<AnyCancellable>()
	private var fetchTask: Task<(), Error>?
	
	public init(
		fetchClosure: @escaping FetchClosure<Item, Filter>,
		itemsPerPage: Int = 100,
		distanceBeforeLoadNextPage: Int = 200
	) {
		self.paginator = Paginator(fetchClosure: fetchClosure, itemsPerPage: itemsPerPage)
		self.distanceBeforeLoadNextPage = distanceBeforeLoadNextPage
		Task {
			await subscribeToPaginatorUpdates()
		}
	}
	
	/**
	 Fetch the next items page.
	 
	 - Parameter cleanBeforeUpdate: If `true`, makes a "fresh fetch" of the 0 page
	 and replaces the current `items` value with the fetched result on success. The `items` value
	 does not get cleared in case of fetch error.
	 */
	public func fetchNextPage(
		cleanBeforeUpdate: Bool = false
	) async {
		do {
			try await paginator.fetchNextPage(cleanBeforeUpdate: cleanBeforeUpdate)
		} catch {
			handleError(error)
		}
	}
}

// MARK: - UI Events Handling
public extension PaginatorVM {
	
	@MainActor @Sendable
	func onViewDidAppear() async {
		await fetchNextPage(cleanBeforeUpdate: true)
	}
	
	/**
	 Call to trigger next page fetch when the list is scrolled far enough.
	 */
	@Sendable
	func onItemShown(_ item: Item) async {
		let itemsSnapshot = await items
		if await loadingState == .notLoading,
		   let idx = itemsSnapshot.firstIndex(of: item) {
			let startFetchFrom = itemsSnapshot.count - distanceBeforeLoadNextPage
			if idx > startFetchFrom {
				await fetchNextPage()
			}
		}
	}
	
	@Sendable
	func onRefresh() async {
		await fetchNextPage(cleanBeforeUpdate: true)
	}
}


// MARK: - Private
private extension PaginatorVM {

	/**
	 Bind to all relevant `paginator` state changes.
	 */
	@MainActor
	func subscribeToPaginatorUpdates() async {
		await paginator.$items
			.sink { paginatorItems in
				Task {
					await MainActor.run {
						pp("** items recieved on main \(paginatorItems.count)")
						self.items = paginatorItems
					}
				}
			}
			.store(in: &cancellables)
		
		await paginator.$loadingState
			.sink { paginatorLoadingState in
				_ = Task {
					await MainActor.run {
						pp("** loading state recieved on main")
						self.loadingState = paginatorLoadingState
					}
				}
			}
			.store(in: &cancellables)
	}
	
	func handleError(_ error: Error) {
		pp("ERROR \(error)")
	}
}
