//
//  ChangeNotificationTests.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import XCTest
import SwiftPaginator

final class ChangeNotificationTests: XCTestCase {

	var sut: Paginator<DummyItem, Void>!
	
    override func setUpWithError() throws {
		let mockBE = MockFetchProvider(totalCount: 75)
		
		sut = Paginator(.init(pageSize: 30), requestProvider: mockBE)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAdd_onInitialState() async throws {
		NotificationCenter.default.post(name: .paginatorItemAdded, object: DummyItem())
    }

}
