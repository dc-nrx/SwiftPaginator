//
//  PaginationSimpleRequestProvider.swift
//  
//
//  Created by Dmytro Chapovskyi on 31.07.2023.
//

import Foundation

public typealias FetchItemsClosure<Item, Filter> = (_ page: Int, _ count: Int, Filter?) async throws -> [Item]

public protocol PaginationSimpleRequestProvider {

	associatedtype Filter
	associatedtype Item

	func fetchItems(
		page: Int,
		count: Int,
		filter: Filter?
	) async throws -> [Item]
}

public extension PaginationSimpleRequestProvider {
	
	func fetchItems(
		page: Int,
		count: Int
	) async throws -> [Item] {
		try await fetchItems(page: page, count: count, filter: nil)
	}
}

public extension PaginationRequestProvider where Self: PaginationSimpleRequestProvider {
	
	func fetch(
		page: Int,
		count: Int,
		filter: Filter?
	) async throws -> Page<Item> {
		Page(try await fetchItems(page: page, count: count, filter: filter))
	}

}

public extension Paginator {
	
}
