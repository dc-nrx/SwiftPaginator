//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation

public enum PostFetchProcessor<T>: Comparable {

	/// Process newly fetched page before merge with existed list
	case newPage(ListProcessor<T>)
	/// Customize merge process
	case merge(MergeProcessor<T>)
	/// Process resulting list after merge
	case resultList(ListProcessor<T>)

	public typealias MergeProcessor<Item> = (_ current: inout [Item], _ new: inout [Item]) -> ()
	public typealias ListProcessor<Item> = (_ items: inout [Item]) -> ()
	
	func dropSameIDs<Item: Identifiable>(prioritizeNewlyFetched: Bool) -> PostFetchProcessor<Item> {
		//TODO: add IDs cache
		let result: MergeProcessor<Item> = { current, new in
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
		
		return .merge(result)
	}
	
	// Comparable conformance
	public static func < (lhs: PostFetchProcessor<T>, rhs: PostFetchProcessor<T>) -> Bool {
		switch (lhs, rhs) {
		case (.newPage, .merge), (.newPage, .resultList), (.merge, .resultList):
			return true
		default:
			return false
		}
	}
	
	// Equatable conformance
	public static func == (lhs: PostFetchProcessor<T>, rhs: PostFetchProcessor<T>) -> Bool {
		switch (lhs, rhs) {
		case (.newPage(let lhsProcessor), .newPage(let rhsProcessor)),
			 (.resultList(let lhsProcessor), .resultList(let rhsProcessor)):
			return unsafeBitCast(lhsProcessor, to: Int.self) == unsafeBitCast(rhsProcessor, to: Int.self)
		case (.merge(let lhsProcessor), .merge(let rhsProcessor)):
			return unsafeBitCast(lhsProcessor, to: Int.self) == unsafeBitCast(rhsProcessor, to: Int.self)
		default:
			return false
		}
	}
}
