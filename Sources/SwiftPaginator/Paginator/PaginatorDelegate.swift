//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 13.12.2023.
//

import Foundation

public protocol PaginatorDelegate<Item, Filter> {
	associatedtype Item: Identifiable
	associatedtype Filter
	
	func paginator(_ paginator: Paginator<Item, Filter>, willUpdateItemsTo updatedItems: [Item])
	func paginator(_ paginator: Paginator<Item, Filter>, willUpdateStateTo newState: PaginatorState)
}

extension PaginatorDelegate {
	func paginator(_ paginator: Paginator<Item, Filter>, willUpdateItemsTo updatedItems: [Item]) { }
	func paginator(_ paginator: Paginator<Item, Filter>, willUpdateStateTo newState: PaginatorState) { }
}
