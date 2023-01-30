//
//  FS.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public protocol FetchService {
	
	associatedtype Item: Comparable & Identifiable
	associatedtype Filter
	
	func fetch(
		count: Int,
		page: Int,
		filter: Filter?
	) async throws -> [Item]
}
