//
//  ProcessorsTests.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.12.2023.
//

import XCTest
import SwiftPaginator

final class ProcessorsTests: XCTestCase {

	let mockBE = MockFetchProvider(totalCount: 70)
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPageTransform_filtering2ItemsFromFirstPageOut_loadsAllSubsequent() async throws {
		let config = PaginatorConfiguration<DummyItem>(pageTransform: .filter { !$0.id.hasPrefix("1") })
		let paginator = Paginator(config, requestProvider: mockBE)
		
		await paginator.fetch()
		XCTAssertEqual(19, paginator.items.count)

		await paginator.fetch()
		XCTAssertEqual(49, paginator.items.count)

		await paginator.fetch()
		XCTAssertEqual(59, paginator.items.count)
		
		await paginator.fetch(.refresh)
		XCTAssertEqual(19, paginator.items.count)
		
		await paginator.fetch()
		XCTAssertEqual(49, paginator.items.count)
	}

}
