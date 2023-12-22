//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 13.12.2023.
//

import Foundation


public protocol PaginatorVMProtocol<Item, Filter>: ObservableObject {
	
	associatedtype Item: Identifiable
	associatedtype Filter
	
	/// A filter applicable to the fetch service used.
	var filter: Filter? { get set }
	
	var paginator: Paginator<Item, Filter> { get }
	
	/// Determines which cell's `didAppear` event (from the end) triggers "fetch next page" request.
	var prefetchDistance: Int { get set }
	
	// MARK: - UI Events Handling
	
	@Sendable func onAppear()
	
	/// Call to trigger next page fetch when the list is scrolled far enough.
	@Sendable func onItemShown(_ item: Item)
	
	/// Explicit refresh request (e.g. from a refresh control)
	@Sendable func onRefresh()
	
	// MARK: - Internal
	
	/**
	 Perform a fetch operation - either `refresh` or `nextPage` (see `FetchType`).
	 
	 - Note: `Open` access only to allow overrides in subclasses (i.e. it should not be called from the view layer directly).
	 */
	func fetch(_ type: FetchType, force: Bool)
}

public extension PaginatorVMProtocol {
	
	// MARK: - Public Variables
	/**
	 A filter applicable to the fetch service used.
	 */
	var filter: Filter? {
		set { paginator.filter = newValue }
		get { paginator.filter }
	}
	
	@Sendable func onAppear() {
		if paginator.state == .initial { fetch(.nextPage) }
	}
	
	@Sendable func onItemShown(_ item: Item) {
		if !paginator.state.fetchInProgress,
		   !paginator.lastPageIsIncomplete,
		   let idx = paginator.items.firstIndex(where: { $0.id == item.id }) {
			let startFetchFrom = paginator.items.count - prefetchDistance
			if idx > startFetchFrom {
				fetch(.nextPage)
			}
		}
	}
	
	@Sendable func onRefresh() {
		fetch(.refresh, force: true)
	}
	
	// MARK: - Internal
	
	/**
	 Perform a fetch operation - either `refresh` or `nextPage` (see `FetchType`).
	 
	 - Note: `Open` access only to allow overrides in subclasses (i.e. it should not be called from the view layer directly).
	 */
	func fetch(_ type: FetchType, force: Bool = false) {
		paginator.fetchInBackground(type, force: force)
	}
}
