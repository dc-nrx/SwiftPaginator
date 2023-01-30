//
//  FS.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public typealias PaginatorItem = Comparable & Identifiable

public protocol FetchService {
	
	associatedtype Item: PaginatorItem
	associatedtype Filter
	
	func fetch(
		count: Int,
		page: Int,
		filter: Filter?
	) async throws -> [Item]
}
