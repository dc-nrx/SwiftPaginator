//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 04.10.2023.
//

import Foundation

public struct Configuration<Item> {
	
	/// Page size to request.
	public var pageSize: Int
	
	/// The first page index (
	public var firstPageIndex: Int

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

	init(
		pageSize: Int = 30,
		firstPageIndex: Int = 0,
		pageTransform: ListProcessor<Item>? = nil,
		merge: MergeProcessor<Item> = .dropSameIDs(prioritizeNewlyFetched: true),
		resultTransform: ListProcessor<Item>? = nil
	) where Item: Identifiable {
		self.pageTransform = pageTransform
		self.merge = merge
		self.resultTransform = resultTransform
		self.pageSize = pageSize
		self.firstPageIndex = firstPageIndex
	}
	
	public init(
		pageSize: Int = 30,
		firstPageIndex: Int = 0,
		pageTransform: ListProcessor<Item>? = nil,
		merge: MergeProcessor<Item>,
		resultTransform: ListProcessor<Item>? = nil
	) {
		self.pageTransform = pageTransform
		self.merge = merge
		self.resultTransform = resultTransform
		self.pageSize = pageSize
		self.firstPageIndex = firstPageIndex
	}
}
