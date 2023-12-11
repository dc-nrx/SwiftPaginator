//
//  Types.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.02.2023.
//

import Foundation

public struct Page<Item> {
	
	public var items: [Item]
	
	public var totalItems: Int?
	public var totalPages: Int?
	public var currentPage: Int?
	
	public init(
		_ items: [Item],
		totalItems: Int? = nil,
		totalPages: Int? = nil,
		currentPage: Int? = nil
	) {
		self.items = items
		self.totalItems = totalItems
		self.totalPages = totalPages
		self.currentPage = currentPage
	}
}

/// Use when there is some valuable metadata
public typealias FetchPageClosure<Item, Filter> = (_ page: Int, _ count: Int, Filter?) async throws -> Page<Item>

/// Use when there is some valuable metadata
public protocol PaginationRequestProvider<Item, Filter> where Item: Identifiable {

	associatedtype Filter
	associatedtype Item

	func fetch(
		page: Int,
		count: Int,
		filter: Filter?
	) async throws -> Page<Item>
}

public extension PaginationRequestProvider {
	
	func fetch(
		page: Int,
		count: Int
	) async throws -> Page<Item> {
		try await fetch(page: page, count: count, filter: nil)
	}
}

public extension Paginator {
	
	convenience init<T: PaginationRequestProvider>(
		_ configuration: Configuration<Item>,
		requestProvider: T
	) where T.Item == Item, T.Filter == Filter {
		self.init(configuration, fetch: requestProvider.fetch)
	}
}

public extension PaginatorVM {
	
	convenience init<T: PaginationRequestProvider>(
		requestProvider: T,
		itemsPerPage: Int = PaginatorDefaults.itemsPerPage,
		firstPageIndex: Int = PaginatorDefaults.firstPageIndex,
		distanceBeforeLoadNextPage: Int = PaginatorDefaults.distanceBeforeLoadNextPage
	) where T.Item == Item, T.Filter == Filter {
		self.init(fetchClosure: requestProvider.fetch, itemsPerPage: itemsPerPage, firstPageIndex: firstPageIndex, distanceBeforeLoadNextPage: distanceBeforeLoadNextPage)
	}
}
