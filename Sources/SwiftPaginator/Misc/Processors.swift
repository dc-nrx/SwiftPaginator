//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation

public protocol LocalEditsTracker: AnyObject {

	/**
	 This property is added to `items.count` during `page` calculation. (see `page`)
	 
	 If there is a need to make edits that are not reflected on the remote source (e.g., filter something out locally),
	 register it by incrementing / decrementing this property accordingly.
	 
	 This way, `page` calculation would remain correct, and `fetch` would continue work as expected.
	 
	 - NOTE: In-place edits (that is, `add`, `delete` and `update` methods)
	 usually *should* be reflected on the remote source, and in such cases `localEditsDelta` should not be changed.
	 (as the items count changes both locally and on the remote source).
	 */

	var localEditsDelta: Int { get set }
}

public struct ListProcessor<Item> {
	
	public typealias Operation = (LocalEditsTracker, inout [Item]) -> ()
	
	public var execute: Operation

	public init(execute: @escaping Operation) {
		self.execute = execute
	}
	
	public static func filter(
		_ isIncluded: @escaping (Item) -> Bool
	) -> ListProcessor<Item> {
		.init { editsTracker, items in
			let initialCount = items.count
			items = items.filter(isIncluded)
			editsTracker.localEditsDelta += (items.count - initialCount)
		}
	}
	
	public static func sort(
		by comparator: @escaping (Item, Item) -> Bool
	) -> ListProcessor<Item> {
		.init { _, items in items.sort(by: comparator) }
	}

	public static func sort<T>(
		keyPath: KeyPath<Item, T>,
		by comparator: @escaping (T, T) -> Bool
	) -> ListProcessor<Item> {
		.init { _, items in
			items.sort { comparator($0[keyPath: keyPath], $1[keyPath: keyPath]) }
		}
	}
}

public struct MergeProcessor<Item> {
	
	public typealias Operation = (LocalEditsTracker, _ current: inout [Item], _ new: [Item]) -> ()
	
	public var execute: Operation
	
	public init(execute: @escaping Operation) {
		self.execute = execute
	}

	public static var append: MergeProcessor {
		.init { _, current, new in current.append(contentsOf: new) }
	}
	
	public static func dropSameIDs(
		prioritizeNewlyFetched: Bool = true
	) -> MergeProcessor where Item: Identifiable {
		//TODO: add IDs cache?
		.init { _, current, new in
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
