//
//  PaginatorVM.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import XCTest
import Combine
@testable import SwiftPaginator

final class PaginatorVMSpec: XCTestCase {
	
	var fetchService: DummyFetchService!
	var sut: PaginatorVM<DummyItem, DummyFilter>!
	var cancellables = Set<AnyCancellable>()
		 	
	let totalItems = 99
	let itemsPerPage = 30
	
	@MainActor
	override func setUpWithError() throws {
		fetchService = DummyFetchService(totalItems: 99)
		sut = PaginatorVM(injectedFetch: fetchService.fetch, itemsPerPage: 30)
	}

	@MainActor
	override func tearDownWithError() throws {
		fetchService = nil
		sut = nil
	}

	@MainActor
	func testInit_itemsIsEmpty() {
		XCTAssertEqual(sut.items.count, 0)
		XCTAssertEqual(sut.loadingState, .notLoading)
	}

	func testFetchNextPage_triggersOnBotElementShown() async {
		await MainActor.run { sut.onViewDidAppear() }
		let initialExp = expectation(description: "initial fetch finished")
		await sut.$items
			.drop { $0.isEmpty }
			.prefix { $0.count <= self.itemsPerPage}
			.sink { _ in initialExp.fulfill() }
			.store(in: &cancellables)
		await waitForExpectations(timeout: 2)
		XCTAssertEqual(fetchService.fetchCountPageCallsCount, 1)
		
		let nextPageExp = expectation(description: "next page loaded")
		await sut.onItemShown(sut.items[itemsPerPage - 3])
		await sut.$items
			.drop { $0.count <= self.itemsPerPage }
			.prefix { $0.count <= 2 * self.itemsPerPage }
			.sink { _ in nextPageExp.fulfill() }
			.store(in: &cancellables)
		
		await waitForExpectations(timeout: 2)
		let itemsCount = await sut.items.count
		XCTAssertEqual(itemsCount, 2 * self.itemsPerPage)
	}

//	func testFilter() async {
//		let filter = DummyFilter(mandatoryFlag: true)
//		sut.filter = filter
//		await MainActor.run { sut.onViewDidAppear() }
//		let initialExp = expectation(description: "initial fetch finished")
//		sut.$items
//			.drop { $0.isEmpty }
//			.prefix { $0.count <= self.itemsPerPage}
//			.sink { _ in initialExp.fulfill() }
//			.store(in: &cancellables)
//		await waitForExpectations(timeout: 2)
//		XCTAssertEqual(sut.items.first?.filterUsed?.id, filter.id)
//	}
}

