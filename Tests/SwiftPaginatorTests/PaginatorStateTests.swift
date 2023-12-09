//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 05.10.2023.
//

import Foundation
import XCTest
import Combine

@testable import SwiftPaginator

final class PaginatorStateTests: XCTestCase, CancellablesOwner {
	
	var fetchServiceMock: DummyFetchService!
	var sut: Paginator<DummyItem, DummyFilter>!
	var cancellables = Set<AnyCancellable>()
	
	override func setUpWithError() throws {
		fetchServiceMock = DummyFetchService()
		fetchServiceMock.fetchDelay = 0.1
		sut = Paginator(fetch: fetchServiceMock.fetch)
		cancellables = Set<AnyCancellable>()
	}
	
	override func tearDownWithError() throws {
		sut = nil
		fetchServiceMock = nil
		cancellables = Set<AnyCancellable>()
	}

	func testNextPage_immidiatelyAfterNextPage_throws() async throws {
		let exp = expectState(sut, .active(.fetchNext))
		try await sut.fetch()
		await fulfillment(of: [exp])
	}
}
