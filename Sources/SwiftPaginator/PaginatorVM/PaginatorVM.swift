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
	open var distanceBeforeLoadNextPage: Int
	
	// MARK: - Public Read-only Variables

	open var itemsPerPage: Int {
		paginator.configuration.pageSize
	}

	/**
	 The items fetched from `itemFetchService`.
	 */
	@Published public private(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress.
	 */
	@Published public private(set) var state = State.initial
	
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
		distanceBeforeLoadNextPage: Int = 20
	) {
		self.paginator = paginator
		self.distanceBeforeLoadNextPage = distanceBeforeLoadNextPage
		Task {
			await subscribeToPaginatorUpdates()
		}
	}
	
	public convenience init(
		fetchClosure: @escaping FetchPageClosure<Item, Filter>,
		itemsPerPage: Int = 50,
		firstPageIndex: Int = 0,
		distanceBeforeLoadNextPage: Int = 20
	) {
		let paginator = Paginator(.init(pageSize: itemsPerPage, firstPageIndex: firstPageIndex), fetch: fetchClosure)
		self.init(paginator: paginator, distanceBeforeLoadNextPage: distanceBeforeLoadNextPage)
	}
	
	// MARK: - Public
	/**
	 Fetch the next items page.
	 
	 - Parameter cleanBeforeUpdate: If `true`, makes a "fresh fetch" of the 0 page
	 and replaces the current `items` value with the fetched result on success. The `items` value
	 does not get cleared in case of fetch error.
	 */
	open func fetch(_ type: FetchType) async {
		do {
			try await paginator.fetch(type)
		} catch {
			handleError(error)
		}
	}
	
	// MARK: - Protected
	open func handleError(_ error: Error) {
		logger.error("Unhandeled Error: \(error)")
	}
}

// MARK: - UI Events Handling
public extension PaginatorVM {
	
	@Sendable
	func onViewDidAppear() async {
		if state == .initial { await fetch(.fetchNext) }
	}
	
	/**
	 Call to trigger next page fetch when the list is scrolled far enough.
	 */
	@Sendable
	func onItemShown(_ item: Item) async {
		if !state.fetchInProgress,
		   !paginator.lastPageIsIncomplete,
		   let idx = items.firstIndex(where: { $0.id == item.id }) {
			let startFetchFrom = items.count - distanceBeforeLoadNextPage
			if idx > startFetchFrom {
				await fetch(.fetchNext)
			}
		}
	}
	
	@Sendable
	func onRefresh() async {
		await fetch(.refresh)
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
