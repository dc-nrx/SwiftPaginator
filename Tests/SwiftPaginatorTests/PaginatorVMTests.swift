//
//  PaginatorVM.swift
//
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import XCTest
import Combine
import OSLog
@testable import SwiftPaginator

final class PaginatorVMTests: XCTestCase {

	let logger = Logger(subsystem: "Paginator [TEST]", category: "***")
	
	var fetchService: DummyFetchService!
	var sut: PaginatorVM<DummyItem, DummyFilter>!
	var cancellables = Set<AnyCancellable>()

	let totalItems = 99
	let itemsPerPage = 30

	override func setUpWithError() throws {
		fetchService = DummyFetchService(totalItems: totalItems)
		sut = PaginatorVM(fetchClosure: fetchService.fetch, itemsPerPage: itemsPerPage)
	}

	override func tearDownWithError() throws {
		fetchService = nil
		sut = nil
	}

	func testInit_itemsIsEmpty() {
		XCTAssertEqual(sut.items.count, 0)
		XCTAssertEqual(sut.paginator.state, .initial)
	}

	func testFetch_onViewDidAppear() async {
		await performInitialFetch()
		XCTAssertEqual(sut.items.count, itemsPerPage)
	}
	
	func testFetchNextPage_triggersOnBotElementShown() async {
		await performInitialFetch()
		let itemShowIdx = itemsPerPage - 3
		logger.info("triggering item show \(itemShowIdx)")
		sut.onItemShown(sut.items[itemShowIdx])
		logger.info("waiting for page 1...")
		await waitFor(page: 1)
		let itemsCount = sut.items.count
		XCTAssertEqual(itemsCount, 2 * self.itemsPerPage)
	}

//	func testFetchNextPage_subsequentOnItemShown_triggersOnceForParticularPage() async {
//		await performInitialFetch()
//		let shownIndicies = ((itemsPerPage - 5)..<itemsPerPage).map { $0 }
//	}
	
}

// MARK: - Private
private extension PaginatorVMTests {

	func performInitialFetch() async {
		logger.info("initial fetch start...")
		sut.onAppear()
		await waitFor(page: 0)
	}
	
	func waitFor(
		page: Int,
		caller: String = #function
	) async {
		await withCheckedContinuation { cont in
			let waitId = UUID().uuidString.prefix(5)
			let (l, r) = (page * itemsPerPage + 1, (page + 1) * itemsPerPage)
			logger.debug("wait l = \(l) r = \(r) | \(waitId)")
			Task {
				sut.$items
					.drop { $0.count < l }
					.prefix { $0.count <= r }
					.receive(on: RunLoop.main)
					.sink { items in
						self.logger.debug("exp fulfill, wait done for \(items.count) | \(waitId)")
						cont.resume()
					}
					.store(in: &cancellables)
			}
		}
	}
}
