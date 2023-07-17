//
//  PaginatorVM.swift
//
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation
import Combine
import ReplaceableLogger

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
		paginator.itemsPerPage
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
	@Published public private(set) var loadingState = PaginatorLoadingState.initial
	
	// MARK: - Private Variables
	
	@MainActor
	public let paginator: Paginator<Item, Filter>
	
	@MainActor
	private var cancellables = Set<AnyCancellable>()
	
	private var logger: Logger
	// MARK: - Init

	public init(
		paginator: Paginator<Item, Filter>,
		distanceBeforeLoadNextPage: Int = 20,
		logger: Logger = DefaultLogger(commonPrefix:"📒")
	) {
		self.logger = logger
		self.paginator = paginator
		self.distanceBeforeLoadNextPage = distanceBeforeLoadNextPage
		Task {
			await subscribeToPaginatorUpdates()
		}
	}

	
	public convenience init(
		fetchClosure: @escaping FetchClosure<Item, Filter>,
		itemsPerPage: Int = 50,
		firstPageIndex: Int = 0,
		distanceBeforeLoadNextPage: Int = 20,
		logger: Logger = DefaultLogger(commonPrefix:"📒")
	) {
		let paginator = Paginator(itemsPerPage: itemsPerPage, firstPageIndex: firstPageIndex, fetch: fetchClosure)
		self.init(paginator: paginator, distanceBeforeLoadNextPage: distanceBeforeLoadNextPage, logger: logger)
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
		logger.log(.error, "Unhandeled Error: \(error)")
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
						self?.logger.log(.debug, "items recieved on main \(paginatorItems.count)")
						self?.items = paginatorItems
					}
				}
			}
			.store(in: &cancellables)
		
		paginator.$loadingState
			.sink { paginatorLoadingState in
				_ = Task {
					await MainActor.run { [weak self] in
						self?.logger.log(.debug, "loading state recieved on main")
						self?.loadingState = paginatorLoadingState
					}
				}
			}
			.store(in: &cancellables)
	}
}
