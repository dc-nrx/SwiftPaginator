//
//  Types.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.02.2023.
//

import Foundation

public typealias FetchPageClosure<Item, Filter> = (_ page: Int, _ count: Int, Filter?) async throws -> Page<Item>

public struct Page<Item> {
	
	public var items: [Item]
	
	public var totalItems: Int?
	public var totalPages: Int?
	public var currentPage: Int?
	
	init(_ items: [Item], totalItems: Int? = nil, totalPages: Int? = nil, currentPage: Int? = nil) {
		self.items = items
		self.totalItems = totalItems
		self.totalPages = totalPages
		self.currentPage = currentPage
	}
}

// MARK: - Pagination Request Provider

public protocol PaginationRequestProvider {

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
		requestProvider: T,
		itemsPerPage: Int = PaginatorDefaults.itemsPerPage,
		firstPageIndex: Int = PaginatorDefaults.firstPageIndex
	) where T.Item == Item, T.Filter == Filter {
		self.init(itemsPerPage: itemsPerPage, firstPageIndex: firstPageIndex, fetch: requestProvider.fetch)
	}
}
