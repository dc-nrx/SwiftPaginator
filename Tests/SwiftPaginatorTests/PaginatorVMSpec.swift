//
//  PaginatorVM.swift
//
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import XCTest
import Combine
import ReplaceableLogger
@testable import SwiftPaginator

final class PaginatorVMSpec: XCTestCase {

	let logger: Logger = DefaultLogger(commonPrefix: "[TEST]")
	
	var fetchService: DummyFetchService!
	var sut: PaginatorVM<DummyItem, DummyFilter>!
	var cancellables = Set<AnyCancellable>()

	let totalItems = 99
	let itemsPerPage = 30

	@MainActor
	override func setUpWithError() throws {
		fetchService = DummyFetchService(totalItems: totalItems)
		sut = PaginatorVM(fetchClosure: fetchService.fetch, itemsPerPage: itemsPerPage)
	}

	@MainActor
	override func tearDownWithError() throws {
		fetchService = nil
		sut = nil
	}

	@MainActor
	func testInit_itemsIsEmpty() {
		XCTAssertEqual(sut.items.count, 0)
		XCTAssertEqual(sut.loadingState, .initial)
	}

	func testFetch_onViewDidAppear() async {
		await performInitialFetch()
		let items = await sut.items
		XCTAssertEqual(items.count, itemsPerPage)
	}
	
	func testFetchNextPage_triggersOnBotElementShown() async {
		await performInitialFetch()
		let itemShowIdx = itemsPerPage - 3
		logger.log(.debug, "triggering item show \(itemShowIdx)")
		await sut.onItemShown(sut.items[itemShowIdx])
		logger.log(.debug, "waiting for page 1...")
		await waitFor(page: 1)
		let itemsCount = await sut.items.count
		XCTAssertEqual(itemsCount, 2 * self.itemsPerPage)
	}

//	func testFetchNextPage_subsequentOnItemShown_triggersOnceForParticularPage() async {
//		await performInitialFetch()
//		let shownIndicies = ((itemsPerPage - 5)..<itemsPerPage).map { $0 }
//	}
	
}

// MARK: - Private
private extension PaginatorVMSpec {

	func performInitialFetch() async {
		logger.log(.debug, "initial fetch start...")
		await sut.onViewDidAppear()
		await waitFor(page: 0)
	}
	
	func waitFor(
		page: Int,
		caller: String = #function
	) async {
		await withCheckedContinuation { cont in
			let waitId = UUID().uuidString.prefix(5)
			let (l, r) = (page * itemsPerPage + 1, (page + 1) * itemsPerPage)
			logger.log(.debug, "wait l = \(l) r = \(r) | \(waitId)")
			Task {
				sut.$items
					.drop { $0.count < l }
					.prefix { $0.count <= r }
					.receive(on: RunLoop.main)
					.sink { items in
						self.logger.log(.debug, "exp fulfill, wait done for \(items.count) | \(waitId)")
						cont.resume()
					}
					.store(in: &cancellables)
			}
		}
	}
}
