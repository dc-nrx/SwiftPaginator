//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation

public struct ListProcessor<Item> {
	var execute: (_ items: inout [Item]) -> ()

	public static func sort(
		by comparator: @escaping (Item, Item) -> Bool
	) -> ListProcessor<Item> {
		.init { $0.sort(by: comparator) }
	}

	public static func sort<T>(
		keyPath: KeyPath<Item, T>,
		by comparator: @escaping (T, T) -> Bool
	) -> ListProcessor<Item> {
		.init { items in
			items.sort { comparator($0[keyPath: keyPath], $1[keyPath: keyPath]) }
		}
	}
}

public struct MergeProcessor<Item> {
	
	var execute: (_ current: inout [Item], _ new: [Item]) -> ()
	
	public static var append: MergeProcessor {
		.init { $0.append(contentsOf: $1) }
	}
	
	public static func dropSameIDs(
		prioritizeNewlyFetched: Bool = true
	) -> MergeProcessor where Item: Identifiable {
		//TODO: add IDs cache?
		.init { current, new in
			if prioritizeNewlyFetched {
				let IDs = Set(new.map { $0.id} )
				current.removeAll { IDs.contains($0.id) }
				current.append(contentsOf: new)
			} else {
				let IDs = Set(current.map { $0.id} )
				var itemsToAppend = new
				itemsToAppend.removeAll { IDs.contains($0.id) }
				current.append(contentsOf: itemsToAppend)
			}
		}
	}

}
