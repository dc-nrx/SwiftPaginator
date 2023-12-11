//
//  PaginatorVM.swift
//
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation
import Combine
import OSLog

/**
 Stores sorted collection of `Item`s and provides relevant fetch operations. Can be used as a view model in either list or grid view.
 */
open class PaginatorVM<Item: Identifiable, Filter>: ObservableObject {
	
	// MARK: - Public Variables
	/**
	 A filter applicable to the fetch service used.
	 */
	open var filter: Filter? {
		set { paginator.filter = newValue }
		get { paginator.filter }
	}
	
	/**
	 Determines which cell's `didAppear` event (from the end) triggers "fetch next page" request.
	 */
	open var prefetchDistance: Int
	
	// MARK: - Public Read-only Variables

	open var pageSize: Int { paginator.configuration.pageSize }

	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public private(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress.
	 */
	@Published public private(set) var state: State = .initial
	
	/**
	 The total count of elements on the remote source (if applicable).
	 */
	@Published public private(set) var total: Int?
	
	// MARK: - Private Variables
	
	private let paginator: Paginator<Item, Filter>
	private let logger = Logger(subsystem: "Paginator", category: "PaginatorVM<\(Item.self)>")

	// MARK: - Init

	public init(
		paginator: Paginator<Item, Filter>,
		prefetchDistance: Int = 20
	) {
		self.paginator = paginator
		self.prefetchDistance = prefetchDistance
		Task {
			await subscribeToPaginatorUpdates()
		}
	}
	
	public convenience init(
		fetchClosure: @escaping FetchPageClosure<Item, Filter>,
		itemsPerPage: Int = 50,
		firstPageIndex: Int = 0,
		prefetchDistance: Int = 20
	) {
		let paginator = Paginator(.init(pageSize: itemsPerPage, firstPageIndex: firstPageIndex), fetch: fetchClosure)
		self.init(paginator: paginator, prefetchDistance: prefetchDistance)
	}
	
	// MARK: - Public
	// MARK: - UI Events Handling
	
	@Sendable
	open func onViewDidAppear() {
		if state == .initial { fetch(.nextPage) }
	}
	
	/**
	 Call to trigger next page fetch when the list is scrolled far enough.
	 */
	@Sendable
	open func onItemShown(_ item: Item) {
		if !state.fetchInProgress,
		   !paginator.lastPageIsIncomplete,
		   let idx = items.firstIndex(where: { $0.id == item.id }) {
			let startFetchFrom = items.count - prefetchDistance
			if idx > startFetchFrom {
				fetch(.nextPage)
			}
		}
	}
	
	@Sendable
	open func onRefresh() async {
		fetch(.refresh, force: true)
	}
	
	// MARK: - Internal
	/**
	 Perform a fetch operation - either `refresh` or `nextPage` (see `FetchType`).
	 
	 - Note: `Open` access only to allow overrides in subclasses (i.e. it should not be called from the view layer directly).
	 */
	open func fetch(
		_ type: FetchType,
		force: Bool = false
	) {
		paginator.fetchInBackground(type, force: force)
	}

}

// MARK: - Private
private extension PaginatorVM {

	/**
	 Bind to all relevant `paginator` state changes.
	 */
	func subscribeToPaginatorUpdates() async {
		paginator.$items
			.receive(on: DispatchQueue.main)
			.assign(to: &$items)
		
		paginator.$state
			.receive(on: DispatchQueue.main)
			.assign(to: &$state)

		paginator.$total
			.receive(on: DispatchQueue.main)
			.assign(to: &$total)
	}
}
