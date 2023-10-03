//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation


public struct PostFetchProcessor<Item> {

	public typealias MergeProcessor = (_ current: inout [Item], _ new: inout [Item]) -> ()
	public typealias ListProcessor = (_ items: inout [Item]) -> ()

	/// Process newly fetched page before merge with existed list
	var pre: ListProcessor?
	/// Customize merge process
	var merge: MergeProcessor
	/// Process resulting list after merge
	var post: ListProcessor?
	
	public init(
		pre: ListProcessor? = nil,
		merge: @escaping MergeProcessor = { $0 += $1 },
		post: ListProcessor? = nil
	) {
		self.pre = pre
		self.merge = merge
		self.post = post
	}
	
	func dropSameIDs(prioritizeNewlyFetched: Bool) -> MergeProcessor where Item: Identifiable {
		//TODO: add IDs cache
		let result: MergeProcessor = { current, new in
			if prioritizeNewlyFetched {
				let IDs = Set(current.map { $0.id} )
				var itemsToAppend = new
				itemsToAppend.removeAll { IDs.contains($0.id) }
				current.append(contentsOf: itemsToAppend)
			} else {
				let IDs = Set(new.map { $0.id} )
				current.removeAll { IDs.contains($0.id) }
				current.append(contentsOf: new)
			}
		}
		
		return result
	}
}

//public extension PostFetchProcessor where
