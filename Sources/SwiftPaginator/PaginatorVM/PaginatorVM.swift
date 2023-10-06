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
	public var filter: Filter? {
		didSet {
			paginator.filter = filter
		}
	}
	
	/**
	 Determines which cell's `didAppear` event (from the end) triggers "fetch next page" request.
	 */
	@MainActor
	public var distanceBeforeLoadNextPage: Int
	
	// MARK: - Public Read-only Variables

	public var itemsPerPage: Int {
		paginator.configuration.pageSize
	}

	/**
	 The items fetched from `itemFetchService`.
	 */
	@MainActor
	@Published public private(set) var items = [Item]()
	
	/**
	 Indicated that loading is currently in progress.
	 */
	@MainActor
	@Published public private(set) var loadingState = State.initial
	
	/**
	 The total count of elements on the remote source (if applicable).
	 */
	@MainActor
	@Published public private(set) var total: Int?
	
	// MARK: - Private Variables
	
	@MainActor
	public let paginator: Paginator<Item, Filter>
	
	@MainActor
	private var cancellables = Set<AnyCancellable>()
	
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
	@MainActor
	open func fetchNextPage(
		cleanBeforeUpdate: Bool = false
	) async {
		do {
			try await paginator.fetchNextPage(cleanBeforeUpdate: cleanBeforeUpdate)
		} catch {
			handleError(error)
		}
	}
	
	// MARK: - Protected
	@MainActor
	open func handleError(_ error: Error) {
		logger.error("Unhandeled Error: \(error)")
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
		if !loadingState.isOperation,
		   let idx = items.firstIndex(where: { $0.id == item.id }) {
			let startFetchFrom = items.count - distanceBeforeLoadNextPage
			if idx > startFetchFrom {
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
	@MainActor
	func subscribeToPaginatorUpdates() async {
		paginator.$items
			.sink { paginatorItems in
				Task {
					await MainActor.run { [weak self] in
						self?.logger.debug("items recieved on main \(paginatorItems.count)")
						self?.items = paginatorItems
					}
				}
			}
			.store(in: &cancellables)
		
		paginator.$loadingState
			.sink { paginatorLoadingState in
				_ = Task {
					await MainActor.run { [weak self] in
						self?.logger.debug("loading state recieved on main")
						self?.loadingState = paginatorLoadingState
					}
				}
			}
			.store(in: &cancellables)
	}
}
