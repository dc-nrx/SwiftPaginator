import XCTest
@testable import SwiftPaginator

final class PaginatorTests: XCTestCase {
	
	let kOptionalResponseDelay = 0.5
	let kItemsPerPage = 30
	
	var fetchServiceMock: DummyFetchService!
	var sut: Paginator<DummyItem, DummyFilter>!
	
	override func setUpWithError() throws {
		fetchServiceMock = DummyFetchService()
		sut = Paginator(.init(pageSize: kItemsPerPage), fetch: fetchServiceMock.fetch)
	}
	
	override func tearDownWithError() throws {
		sut = nil
		fetchServiceMock = nil
	}
	
	// MARK: - Initial State
	
	func testInit_vmIsEmpty() async {
		XCTAssertTrue(sut.items.isEmpty)
		XCTAssertEqual(sut.page, 0)
		XCTAssertEqual(sut.state, .initial)
	}
	
	// MARK: - Page
	
	func testFetch_receive0Items_pageNotIncreased() async throws {
		fetchServiceMock.fetchCountPageReturnValue = []
		try await sut.fetch()
		let page = sut.page
		XCTAssertEqual(page, 0)
	}
	
	func testFetch_receivedNotFullPage_pageNotIncreased() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 29)
		try await sut.fetch()
		let page = sut.page
		XCTAssertEqual(page, 0)
	}
	
	func testFetch_receivedFullPage_pageIncreased() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 30)
		try await sut.fetch()
		let page = sut.page
		XCTAssertEqual(page, 1)
	}
	
	func testFetch_receivedLongerPageThanExpexted_pageIncreasedBy1() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 38)
		try await sut.fetch()
		let page = sut.page
		XCTAssertEqual(page, 1)
	}
	
	// MARK: - Items
	
	func testFetch_receivedNotFullPage_itemsCountCorrect() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: kItemsPerPage - 1)
		try await sut.fetch()
		XCTAssertEqual(sut.items.count, kItemsPerPage - 1)
		XCTAssertEqual(sut.total, kItemsPerPage - 1)
	}
	
	func testFetchViaMockClosure_receiveNormalPage_itemsCountCorrect() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: kItemsPerPage)
		try await sut.fetch()
		let items = sut.items
		XCTAssertEqual(items.count, kItemsPerPage)
		XCTAssertEqual(sut.total, kItemsPerPage)
	}
	
	func testFetch_withNoParams_notResetsExistedData() async throws {
		let total = 5 * kItemsPerPage
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: total)
		try await sut.fetch()
		XCTAssertEqual(sut.total, total)
		try await sut.fetch()
		XCTAssertEqual(sut.total, total)

		XCTAssertEqual(sut.items.count, 60)
		XCTAssertEqual(sut.page, 2)
	}
	
	func testFetch_repeatedCalls_noRepeatedRequest() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.fetchNext)
			async let b: () = sut.fetch(.fetchNext)
			async let c: () = sut.fetch(.fetchNext)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testRefresh_repeatedCalls_noRepeatedRequest() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.refresh)
			async let b: () = sut.fetch(.refresh)
			async let c: () = sut.fetch(.refresh)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testRefreshAndFetch_repeatedMixedCalls_noRepeatedRequests() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.refresh)
			async let b: () = sut.fetch(.fetchNext)
			async let c: () = sut.fetch(.refresh)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testFetchAndRefresh_repeatedMixedCalls_noRepeatedRequests() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.fetchNext)
			async let b: () = sut.fetch(.refresh)
			async let c: () = sut.fetch(.fetchNext)
			let _ = try await [a, b, c]
		}
		try await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testSameIds_inLastPage_areNotDuplicated() async throws {
		let testResponse = [DummyItem(),DummyItem(),DummyItem(),DummyItem()]
		fetchServiceMock.fetchCountPageReturnValue = testResponse
		sut.configuration = .init(merge: .dropSameIDs(prioritizeNewlyFetched: true))
		try await sut.fetch()
		XCTAssertEqual(sut.page, 0)
		XCTAssertEqual(sut.items.count, 4)
		try await sut.fetch()
		XCTAssertEqual(sut.page, 0)
		XCTAssertEqual(sut.items.count, 4)
	}
		
//	func testFilter_appliedToGeneratedObjects() async throws {
//		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 29)
//		let filter = DummyFilter(optionalFlag: true)
//		sut.filter = filter
//		try await sut.fetch()
//		XCTAssertEqual(sut.items.first?.filterUsed, filter)
//	}
	
	// MARK: - Item Change Events Responder
	
//	func testOnItemDeleted_sameItemDeletedFromFromSut() async throws {
//		var page = (0...29).map(MockFactrory.item)
//		let itemIdToDelete = UUID().uuidString
//		page[10] = MockFactrory.customItem(id: itemIdToDelete, name: "zzz")
//		fetchServiceMock.fetchCountPageReturnValue = page
//
//		try await sut.fetch()
//		XCTAssertNotNil(sut.items.first { $0.id == itemIdToDelete} )
//
//		let itemToDelete = MockFactrory.customItem(id: itemIdToDelete, name: "abc")
//		sut.itemDeleted(itemToDelete)
//		XCTAssertNil(sut.items.first { $0.id == itemIdToDelete} )
//	}
}
