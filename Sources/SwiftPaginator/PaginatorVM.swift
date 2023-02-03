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
public class PaginatorVM<Item: PaginatorItem, Filter>: ObservableObject {
	
	/**
	 A filter applicable to the fetch service used.
	 */
	var filter: Filter? {
		set { paginator.filter = newValue }
		get { paginator.filter }
	}
	
	var itemsPerPage: Int {
		paginator.itemsPerPage
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
	 Determines which cell's `didAppear` event (from the end) triggers "fetch next page" request.
	 */
	public var distanceBeforeLoadNextPage = 25
	
	private let paginator: Paginator<Item, Filter>
	private var cancellables = Set<AnyCancellable>()
	private var fetchTask: Task<(), Error>?
	
	public init(
		injectedFetch: @escaping FetchFunction<Item, Filter>,
		itemsPerPage: Int = 30
	) {
		self.paginator = Paginator(injectedFetch: injectedFetch, itemsPerPage: itemsPerPage)
		subscribeToPaginatorUpdates()
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
			print("##### \(#function):\(#line) paginator pre-start")
			try await paginator.fetchNextPage(cleanBeforeUpdate: cleanBeforeUpdate)
			print("##### \(#function):\(#line) paginator post-start")
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
	@MainActor @Sendable
	func onItemShown(_ item: Item) async {
		if loadingState == .notLoading,
		   let idx = items.firstIndex(of: item) {
			let startFetchFrom = items.count - distanceBeforeLoadNextPage
			if idx > startFetchFrom {
				print("##### \(#function):\(#line) start fetch")
				await fetchNextPage()
			}
		}
	}
	
	@MainActor @Sendable
	func onRefresh() async {
		await fetchNextPage(cleanBeforeUpdate: true)
	}
}


// MARK: - Private
private extension PaginatorVM {

	/**
	 Bind to all relevant `paginator` state changes.
	 */
	func subscribeToPaginatorUpdates() {
		paginator.$items
			.receive(on: RunLoop.main)
			.sink { [self] in
				self.items = $0
			}
			.store(in: &cancellables)
		
		paginator.$loadingState
			.receive(on: RunLoop.main)
			.sink {
				self.loadingState = $0
			}
			.store(in: &cancellables)
	}
	
	func handleError(_ error: Error) {
		print("##### \(#file) - \(#function):\(#line) ERROR \(error)")
	}
}
