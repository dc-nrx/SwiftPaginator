//
//  SomeFetchService.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public typealias PaginatorItem = Comparable & Identifiable

public protocol FetchService {
	
	associatedtype Element: PaginatorItem
	associatedtype Filter
	
	var filter: Filter? { get set }
	
	func fetch(
		count: Int,
		page: Int
	) async throws -> [Element]
}
