//
//  EditablePaginatorSpec.swift
//  
//
//  Created by Dmytro Chapovskyi on 09.07.2023.
//

import XCTest
@testable import SwiftPaginator

final class EditablePaginatorSpec: XCTestCase {

	var fetchServiceMock: DummyFetchService!
	var sut: EditablePaginator<DummyItem, DummyFilter>!

	let kItemsPerPage = 30

	override func setUpWithError() throws {
		fetchServiceMock = DummyFetchService()
		sut = EditablePaginator(.init(pageSize: kItemsPerPage), fetch: fetchServiceMock.fetch)
	}
	
	override func tearDownWithError() throws {
		sut = nil
		fetchServiceMock = nil
	}
	
	func testFetch_2sameIDsInSubsequentPages_itemUpdatedWithNewestOne_noDuplicates_resultSortedByUpdatedAt() async throws {
		var page0 = (0...29).map { DummyItem(id: UUID().uuidString, name: "d0-\($0)", updatedAt: .now) }
		var page1 = (0...29).map { DummyItem(id: UUID().uuidString, name: "d1-\($0)", updatedAt: .now) }
		
		let duplicateId = UUID().uuidString
		let updatedName = "UPDATED"
		page0[4] = DummyItem(id: duplicateId, name: "Original", updatedAt: .now)
		page1[8] = DummyItem(id: duplicateId, name: updatedName, updatedAt: .now + 1)
		
		sut.configuration = Configuration(
			nextPageMerge: .dropSameIDs(prioritizeNewlyFetched: true),
			resultTransform: .sort(keyPath: \.updatedAt, by: >)
		)
		
		fetchServiceMock.fetchCountPageReturnValue = page0
		try await sut.fetchNextPage()
		var items = sut.items
		XCTAssertEqual(items.count, 30)

		fetchServiceMock.fetchCountPageReturnValue = page1
		try await sut.fetchNextPage()
		
		items = sut.items
		let itemsWithSameId = items.filter { $0.id == duplicateId }
		XCTAssertEqual(itemsWithSameId.count, 1)
		XCTAssertEqual(items.count, 59)
		XCTAssertEqual(itemsWithSameId.first?.name, updatedName)
		XCTAssertEqual(items.firstIndex { $0.id == duplicateId }, 0)
	}
	
}
