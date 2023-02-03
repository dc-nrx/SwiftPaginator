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
		fetchService = DummyFetchService(totalItems: totalItems)
		sut = PaginatorVM(injectedFetch: fetchService.fetch, itemsPerPage: itemsPerPage)
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

	func testFetch_onViewDidAppear() async {
		await performInitialFetch()
		let items = await sut.items
		XCTAssertEqual(items.count, itemsPerPage)
	}
	
	func testFetchNextPage_triggersOnBotElementShown() async {
		pp("initial fetch start...")
		await performInitialFetch()
		let itemShowIdx = itemsPerPage - 3
		pp("triggering item show \(itemShowIdx)")
		await sut.onItemShown(sut.items[itemShowIdx])
		pp("waiting for page 1...")
		await waitFor(page: 1)
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

// MARK: - Private
private extension PaginatorVMSpec {

	func performInitialFetch() async {
		await sut.onViewDidAppear()
		await waitFor(page: 0)
	}
	
	@MainActor
	func waitFor(
		page: Int,
		caller: String = #function
	) async {
		let nextPageExp = XCTestExpectation(description: "page \(page) loaded - \(caller)")
		let (l, r) = (page * itemsPerPage + 1, (page + 1) * itemsPerPage)
		pp("wait l = \(l) r = \(r)")
		await sut.$items
			.drop { $0.count < l }
			.prefix { $0.count <= r }
			.sink { items in
				pp("wait done for \(items.count)")
				nextPageExp.fulfill()
			}
			.store(in: &cancellables)
		wait(for: [nextPageExp], timeout: 0.05)
	}
}
