//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 04.10.2023.
//

import Foundation

public struct PaginatorConfiguration<Item> {
	public var pagePreprocessor: ListProcessor<Item>?
	public var mergeProcessor: MergeProcessor<Item> = .append
	public var resultPostprocessor: ListProcessor<Item>?
	public var perPage: Int
	public var firstPageIndex: Int
	
	public init(
		perPage: Int = 30,
		firstPageIndex: Int = 0,
		pagePreprocessor: ListProcessor<Item>? = nil,
		mergeProcessor: MergeProcessor<Item> = .append,
		resultPostprocessor: ListProcessor<Item>? = nil
	) {
		self.pagePreprocessor = pagePreprocessor
		self.mergeProcessor = mergeProcessor
		self.resultPostprocessor = resultPostprocessor
		self.perPage = perPage
		self.firstPageIndex = firstPageIndex
	}
}
