//
//  PaginatorVM.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import XCTest
import Combine
@testable import Paginator

final class PaginatorVMSpec: XCTestCase {
	
	var fetchService: DummyFetchService!
	var sut: PaginatorVM<ComparableDummy, DummyFilter>!
	var cancellables = Set<AnyCancellable>()
	
	override func setUpWithError() throws {
		fetchService = DummyFetchService(totalItems: 99)
		sut = PaginatorVM<ComparableDummy, DummyFilter>(fetchService: fetchService)
	}

	override func tearDownWithError() throws {
		fetchService = nil
		sut = nil
	}

	func testInit_itemsIsEmpty() {
		XCTAssertEqual(sut.items.count, 0)
		XCTAssertEqual(sut.loadingState, .notLoading)
	}

	func testFetchNextPage_triggersOnBotElementShown() async {
		sut.onViewDidAppear()
		let initialExp = expectation(description: "initial fetch finished")
		sut.$items
			.drop { $0.isEmpty }
			.prefix { $0.count <= 30}
			.sink { _ in initialExp.fulfill() }
			.store(in: &cancellables)
		await waitForExpectations(timeout: 2)
		XCTAssertEqual(fetchService.fetchCountPageCallsCount, 1)
		
		let nextPageExp = expectation(description: "next page loaded")
		sut.onItemShown(sut.items[27])
		sut.$items
			.drop { $0.count <= 30 }
			.prefix { $0.count <= 60 }
			.sink { _ in nextPageExp.fulfill() }
			.store(in: &cancellables)
		
		await waitForExpectations(timeout: 2)
		XCTAssertEqual(sut.items.count, 60)
	}

//	func testFilter() async {
//		let filter = DummyFilter(mandatoryFlag: true)
//		sut.filter = filter
//		sut.onViewDidAppear()
//		let initialExp = expectation(description: "initial fetch finished")
//		sut.$items
//			.drop { $0.isEmpty }
//			.prefix { $0.count <= 30}
//			.sink { _ in initialExp.fulfill() }
//			.store(in: &cancellables)
//		await waitForExpectations(timeout: 2)
//		XCTAssertEqual(sut.items.first?.filterUsed?.id, filter.id)
//	}
}

