//
//  MutablePaginator.swift
//  
//
//  Created by Dmytro Chapovskyi on 09.07.2023.
//

import Foundation

/**
 Supports local edits - that is, insertions, deletions, and in-place updates of already fetched items.
 
 Can come handy to keep the content in sync with the remote source,
 without having to re-fetch the whole thing after each locally initiated atomic change.
 
 The most appropriate moment to enforce a local edit would be upon recieving `success`
 in response to corresponding remote operation.
 */
public class EditablePaginator<Item, Filter>: Paginator<Item, Filter> where Item: Comparable & Identifiable {

	/**
	 Merge with previously fetched `items` (to take care of items with same IDs), sort the resulting array and update `items` value accordingly.
	 
	 If duplicated items are found, the value with the latest `updatedAt` is used, and others are discarded.
	 
	 The sort order is  descending.
	 
	 - Note: The method can be used for any update
	 */
	override func receive(_ newItems: [Item]) {
		//// Use map to handle collisions of items with the same ID
		items = (items + newItems)
			.reduce(into: [Item.ID: Item]()) { partialResult, item in
				if let existeditem = partialResult[item.id] {
					partialResult[item.id] = [existeditem, item].max()
				} else {
					partialResult[item.id] = item
				}
			}
			.values
			.sorted(by: >)
	}
}

public extension EditablePaginator {
	
	/**
	 Will have effect **only** if `item.updatedAt` is more recent than `updatedAt` of the one with the same `id` from `items`.
	 If an outdated version of`item` is not present in `items`, the result of the behaviour will be the same as for `itemAdded()`.
	 */
	func itemUpdatedLocally(_ item: Item) {
		receive([item])
	}
	
	/**
	 Inserts the `item` into `items`, respecting sort order.
	 */
	func itemAddedLocally(_ item: Item) {
		receive([item])
	}
	
	/**
	 Removes `item` from `items` (if it was there).
	 */
	func itemDeletedLocally(_ item: Item) {
		if let indexToDelete = items.firstIndex(where: { $0.id == item.id } ) {
			items.remove(at: indexToDelete)
		}
	}
}
