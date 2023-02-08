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

	func testFetchNextPage_subsequentOnItemShown_triggersOnceForParticularPage() async {
		pp("initial fetch start...")
		await performInitialFetch()
		let shownIndicies = ((itemsPerPage - 5)..<itemsPerPage).map { $0 }
		
	}
	
}

// MARK: - Private
private extension PaginatorVMSpec {

	func performInitialFetch() async {
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
			pp("wait l = \(l) r = \(r) | \(waitId)")
			Task {
				await sut.$items
					.drop { $0.count < l }
					.prefix { $0.count <= r }
					.receive(on: RunLoop.main)
					.sink { items in
						pp("exp fulfill, wait done for \(items.count) | \(waitId)")
						cont.resume()
					}
					.store(in: &cancellables)
			}
		}
	}
}
