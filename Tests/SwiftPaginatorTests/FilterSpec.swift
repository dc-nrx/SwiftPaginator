//
//  FilterSpec.swift
//  
//
//  Created by Dmytro Chapovskyi on 30.01.2023.
//

import XCTest
import Combine
@testable import SwiftPaginator

final class FilterSpec: XCTestCase {

	var fetchService: DummyFetchService!
	var sut: PaginatorVM<DummyItem, DummyFilter>!
	var cancellables = Set<AnyCancellable>()
	
	@MainActor
	override func setUpWithError() throws {
		fetchService = DummyFetchService(totalItems: 99)
		sut = PaginatorVM(injectedFetch: fetchService.fetch)
	}

	@MainActor
	override func tearDownWithError() throws {
		fetchService = nil
		sut = nil
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
//		waitForExpectations(timeout: 2)
//		XCTAssertEqual(sut.items.first?.filterUsed?.id, filter.id)
//	}
	
}
