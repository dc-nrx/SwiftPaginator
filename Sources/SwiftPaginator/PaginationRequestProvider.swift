//
//  Types.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.02.2023.
//

import Foundation

public typealias FetchClosure<Item, Filter> = (_ page: Int, _ count: Int, Filter?) async throws -> PaginationResponse<Item>

public typealias PaginationResponse<Item> = (items: [Item], total: Int?)

public protocol PaginationRequestProvider {

	associatedtype Filter
	associatedtype Item

	func fetch(
		page: Int,
		count: Int,
		filter: Filter?
	) async throws -> PaginationResponse<Item>

}

public extension PaginationRequestProvider {
	
	func fetch(
		page: Int,
		count: Int
	) async throws -> PaginationResponse<Item> {
		try await fetch(page: page, count: count, filter: nil)
	}
}
