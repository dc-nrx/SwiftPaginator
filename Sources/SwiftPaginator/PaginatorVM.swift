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
public class PaginatorVM<FS: FetchService>: ObservableObject {
	
	/**
	 A filter applicable to the fetch service used.
	 */
	var filter: FS.Filter? {
		set { paginator.filter = newValue }
		get { paginator.filter }
	}
	
	var itemsPerPage: Int {
		paginator.itemsPerPage
	}
	
	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public private(set) var items = [FS.Item]()
	
	/**
	 Indicated that loading is currently in progress
	 */
	@Published public private(set) var loadingState = PaginatorLoadingState.notLoading

	/**
	 Determines which cell's `didAppear` event (from the end) triggers "fetch next page" request.
	 */
	public var distanceBeforeLoadNextPage = 10
	
	private let paginator: Paginator<FS>
	private var cancellables = Set<AnyCancellable>()
	
	public init(
		fetchService: FS,
		itemsPerPage: Int = 30
	) {
		self.paginator = Paginator(fetchService: fetchService, itemsPerPage: itemsPerPage)
		subscribeToPaginatorUpdates()
	}
	
}

// MARK: - UI Events Handling
public extension PaginatorVM {
	
	func onViewDidAppear() {
		Task(priority: .userInitiated) {
			await fetchNextPage(cleanBeforeUpdate: true)
		}
	}
	
	/**
	 Call to trigger next page fetch when the list is scrolled far enough.
	 */
	func onItemShown(_ item: FS.Item) {
		Task(priority: .userInitiated) {
			if let idx = items.firstIndex(of: item),
			   idx > items.count - distanceBeforeLoadNextPage {
				await fetchNextPage()
			}
		}
	}
	
	func onRefresh() {
		Task(priority: .userInitiated) {
			await fetchNextPage(cleanBeforeUpdate: true)
		}
	}
}


// MARK: - Private
private extension PaginatorVM {

	/**
	 Fetch the next items page.
	 
	 - Parameter cleanBeforeUpdate: If `true`, makes a "fresh fetch" of the 0 page
	 and replaces the current `items` value with the fetched result on success. The `items` value
	 does not get cleared in case of fetch error.
	 */
	func fetchNextPage(
		cleanBeforeUpdate: Bool = false
	) async {
		do {
			try await paginator.fetchNextPage(cleanBeforeUpdate: cleanBeforeUpdate)
		} catch {
			handleError(error)
		}
	}

	/**
	 Bind to all relevant `paginator` state changes.
	 */
	func subscribeToPaginatorUpdates() {
		paginator.$items
			.receive(on: RunLoop.main)
			.sink {
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
		// show error
	}
}
