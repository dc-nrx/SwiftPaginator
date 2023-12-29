//
//  PaginatorComplexTests.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.12.2023.
//

import XCTest
import SwiftPaginator

final class PaginatorComplexTests: XCTestCase {


    func testFetch3Pages_lastIncomplete_refresh_correctItemsAndCurrentPage() async throws {
		let mockBE = MockFetchProvider(totalCount: 75)
		let sut = Paginator(.init(pageSize: 30), requestProvider: mockBE)
		
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.nextPage, 1)
		XCTAssertEqual(sut.items.count, 30)
		
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.nextPage, 2)
		XCTAssertEqual(sut.items.count, 60)

		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.nextPage, 2)
		XCTAssertEqual(sut.items.count, 75)

		await sut.fetch(.refresh)
		XCTAssertEqual(sut.nextPage, 1)
		XCTAssertEqual(sut.items.count, 30)
    }
	
}
