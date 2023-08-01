//
//  PaginationSimpleRequestProvider.swift
//  
//
//  Created by Dmytro Chapovskyi on 31.07.2023.
//

import Foundation

/// Use when only items are valueable from response
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
