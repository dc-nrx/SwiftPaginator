//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 26.12.2023.
//

import Foundation

public class MockFetchProvider<Item: Identifiable, Filter>: PaginationRequestProvider {
	
	/// Define the way of response generation
	public var source: Source
	
	/// Records the last `fetch` call input & the total number of calls.
	public private(set) var info = Info()
	
	public init(_ source: Source) { self.source = source }
	
	public convenience init(_ totalCount: UInt = 100) where Item == DummyItem {
		let items = (0..<totalCount)
			.map { DummyItem(id: "id-\($0)", name: "name-\($0)", updatedAt: .now - TimeInterval($0)) }
		self.init(.fakeBE(items))
	}

	public func fetch(page: Int, count: Int, filter: Filter?) async throws -> Page<Item> {
		info.recordCall(page: page, count: count, filter: filter)

		switch source {
		case .page(let page):
			return page

		case .fakeBE(let config):
			let startIndex = max((page - config.firstPageIndex) * count, 0)
			let endIndex = min(startIndex + count, config.allItems.count)
			let pageItems = Array(config.allItems[startIndex..<endIndex])
			
			if let delay = config.responseDelay {
				let nanoseconds = UInt64(delay * 1_000_000_000)
				try await Task.sleep(nanoseconds: nanoseconds)
			}
			
			return Page(pageItems,
						totalItems: config.totalItems,
						totalPages: config.totalPages,
						currentPage: config.showCurrentPage ? page : nil)

		case .dynamic(let closure):
			return try await closure(page, count, filter)
		}
	}
	
	// MARK: - Sub-types
	
	public struct Info {
		public var fetchCallCount = 0
		public var lastFetchedPage: Int?
		public var lastFetchedCount: Int?
		public var lastFetchedFilter: Filter?
		
		mutating func recordCall(page: Int, count: Int, filter: Filter?) {
			fetchCallCount += 1
			lastFetchedPage = page
			lastFetchedCount = count
			lastFetchedFilter = filter
		}
	}

	public enum Source {
		/// A predefined page that will be returned on each `fetch` call (method input is ignored)
		case page(Page<Item>)
		/// A backend simulation
		case fakeBE(FakeBEConfiguration)
		case dynamic(FetchPageClosure<Item, Filter>)
		
		public struct FakeBEConfiguration {
			public var allItems: [Item]
			public var firstPageIndex: Int
			public var totalItems: Int?
			public var totalPages: Int?
			public var showCurrentPage: Bool
			public var responseDelay: TimeInterval?

			// Public initializer
			public init(_ allItems: [Item],
						firstPageIndex: Int = 0,
						totalItems: Int? = nil,
						totalPages: Int? = nil,
						showCurrentPage: Bool = false,
						responseDelay: TimeInterval? = 0) {
				self.allItems = allItems
				self.firstPageIndex = firstPageIndex
				self.totalItems = totalItems
				self.totalPages = totalPages
				self.showCurrentPage = showCurrentPage
				self.responseDelay = responseDelay
			}
		}
		
		static func fakeBE(_ items: [Item],
						   firstPageIndex: Int = 0,
						   totalItems: Int? = nil,
						   totalPages: Int? = nil,
						   showCurrentPage: Bool = false,
						   responseDelay: TimeInterval? = 0) -> Self {
			let config = FakeBEConfiguration(items,
											 firstPageIndex: firstPageIndex,
											 totalItems: totalItems,
											 totalPages: totalPages,
											 showCurrentPage: showCurrentPage,
											 responseDelay: responseDelay)
			return .fakeBE(config)
		}
	}
}
