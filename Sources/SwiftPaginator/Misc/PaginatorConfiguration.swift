//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 04.10.2023.
//

import Foundation

public struct PaginatorConfiguration<Item: Identifiable> {
	
	/// Page size to request.
	public var pageSize: Int
	
	/// The first page index (
	public var firstPageIndex: Int

    /// Used to filter only relevant local `.add` operations (see `PaginatorNotifier`)
    public var parentId: PaginatorNotifier.ParentID?

	/// Applies to the newly fetched page content before merging it with already loaded items list
	public var pageTransform: ListProcessor<Item>?
	
	/// Implements the merge logic (in most cases, you would want just
	/// to append the new page content to the existed items list)
	public var merge: MergeProcessor<Item>

	/**
	 Applies to the items list after merging it with the fetched page content.
	 Can be used, for instance, to sort the resulting list or remove duplicates.
	 
	 - Note: In nearly every practical case, either `pageTransform` or `merge` would be
	 a better choice for obvious performace reasons.
	 */
	public var resultTransform: ListProcessor<Item>?
	
	public private(set) var notifier: PaginatorNotifier?
    
	public init(
		pageSize: Int = 30,
		firstPageIndex: Int = 0,
        parentId: PaginatorNotifier.ParentID? = nil,
		notifier: PaginatorNotifier? = .default,
		pageTransform: ListProcessor<Item>? = nil,
		merge: MergeProcessor<Item> = .dropSameIDs(prioritizeNewlyFetched: true),
		resultTransform: ListProcessor<Item>? = nil
	) {
		self.pageTransform = pageTransform
		self.merge = merge
        self.parentId = parentId
		self.resultTransform = resultTransform
		self.pageSize = pageSize
		self.firstPageIndex = firstPageIndex
		self.notifier = notifier
	}
}

extension PaginatorConfiguration: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		"p_s = \(pageSize); f_idx = \(firstPageIndex)"
	}
}
