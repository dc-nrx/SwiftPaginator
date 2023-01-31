//
//  FS.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public typealias PaginatorItem = Comparable & Identifiable

/**
 `Comparable` and `Identifiable` conformances are needed for `Paginator` to sort the items list after merge and resolve collisions.
 
 Comparable is to support sorting (by `>`). E.g., by date added / date updated / alphabetically by name etc.
 Both Comparable and Identifiable are needed to resolve duplicates of the same element.
 The element with the higher order is kept, and the one with the lower is discarded.
 
 `Filter` - An optional filter containing any conditions whatsoever - provided and handled by the `FetchService` implementation.

 */
open class FetchService<Item: PaginatorItem, Filter> {

	/**
	 The fetch request, pretty much self explanatory.
	 */
	func fetch(
		count: Int,
		page: Int,
		filter: Filter?
	) async throws -> [Item] {
		fatalError("abstract class")
	}
}
