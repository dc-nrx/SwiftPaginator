import XCTest
@testable import Paginator

final class PaginatorTests: XCTestCase {
	
	let kOptionalResponseDelay = 0.5
	
	var fetchServiceMock: DummyFetchService!
	var sut: Paginator<DummyFetchService>!
	
	override func setUpWithError() throws {
		fetchServiceMock = DummyFetchService()
		sut = Paginator(fetchService: fetchServiceMock)
	}
	
	override func tearDownWithError() throws {
		sut = nil
		fetchServiceMock = nil
	}
	
	// MARK: - Initial State
	
	func testInit_vmIsEmpty() {
		XCTAssertTrue(sut.items.isEmpty)
		XCTAssertEqual(sut.page, 0)
		XCTAssertEqual(sut.loadingState, .notLoading)
	}
	
	// MARK: - Page
	
	func testFetch_receive0Items_pageNotIncreased() async throws {
		fetchServiceMock.fetchCountPageReturnValue = []
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 0)
	}
	
	func testFetch_receivedNotFullPage_pageNotIncreased() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 29)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 0)
	}
	
	func testFetch_receivedFullPage_pageIncreased() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 30)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 1)
	}
	
	func testFetch_receivedLongerPageThanExpexted_pageIncreasedBy1() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 38)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 1)
	}
	
	// MARK: - Items
	
	func testFetch_receivedNotFullPage_itemsCountCorrect() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: sut.itemsPerPage - 1)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, sut.itemsPerPage - 1)
	}
	
	func testFetchViaMockClosure_receiveNormalPage_itemsCountCorrect() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: sut.itemsPerPage)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, sut.itemsPerPage)
	}
	
	func testFetch_withNoParams_notResetsExistedData() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 5 * sut.itemsPerPage)
		try await sut.fetchNextPage()
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, 60)
		XCTAssertEqual(sut.page, 2)
	}
	
	func testFetch_repeatedCalls_noRepeatedRequest() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetchNextPage(cleanBeforeUpdate: false)
			async let b: () = sut.fetchNextPage(cleanBeforeUpdate: false)
			async let c: () = sut.fetchNextPage(cleanBeforeUpdate: false)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testRefresh_repeatedCalls_noRepeatedRequest() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetchNextPage(cleanBeforeUpdate: true)
			async let b: () = sut.fetchNextPage(cleanBeforeUpdate: true)
			async let c: () = sut.fetchNextPage(cleanBeforeUpdate: true)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testRefreshAndFetch_repeatedMixedCalls_noRepeatedRequests() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetchNextPage(cleanBeforeUpdate: true)
			async let b: () = sut.fetchNextPage(cleanBeforeUpdate: false)
			async let c: () = sut.fetchNextPage(cleanBeforeUpdate: true)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testFetchAndRefresh_repeatedMixedCalls_noRepeatedRequests() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetchNextPage(cleanBeforeUpdate: false)
			async let b: () = sut.fetchNextPage(cleanBeforeUpdate: true)
			async let c: () = sut.fetchNextPage(cleanBeforeUpdate: false)
			let _ = try await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testFetch_2sameIDsInSubsequentPages_itemUpdatedWithNewestOne_noDuplicates_resultSortedByUpdatedAt() async throws {
		var page0 = (0...29).map { ComparableDummy(id: UUID().uuidString, name: "d0-\($0)", updatedAt: .now) }
		var page1 = (0...29).map { ComparableDummy(id: UUID().uuidString, name: "d1-\($0)", updatedAt: .now) }
		
		let duplicateId = UUID().uuidString
		let updatedName = "UPDATED"
		page0[4] = ComparableDummy(id: duplicateId, name: "Original", updatedAt: .now)
		page1[8] = ComparableDummy(id: duplicateId, name: updatedName, updatedAt: .now + 1)
		
		fetchServiceMock.fetchCountPageReturnValue = page0
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, 30)

		fetchServiceMock.fetchCountPageReturnValue = page1
		try await sut.fetchNextPage()
		
		let itemsWithSameId = sut.items.filter { $0.id == duplicateId }
		XCTAssertEqual(itemsWithSameId.count, 1)
		XCTAssertEqual(sut.items.count, 59)
		XCTAssertEqual(itemsWithSameId.first?.name, updatedName)
		XCTAssertEqual(sut.items.firstIndex { $0.id == duplicateId }, 0)
	}
	
	func testFilter_appliedToGeneratedObjects() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 29)
		let filter = DummyFilter(optionalFlag: true)
		sut.filter = filter
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.first?.filterUsed, filter)
	}
	
	// MARK: - Item Change Events Responder
	
//	func testOnItemDeleted_sameItemDeletedFromFromSut() async throws {
//		var page = (0...29).map(MockFactrory.item)
//		let itemIdToDelete = UUID().uuidString
//		page[10] = MockFactrory.customItem(id: itemIdToDelete, name: "zzz")
//		fetchServiceMock.fetchCountPageReturnValue = page
//
//		try await sut.fetchNextPage()
//		XCTAssertNotNil(sut.items.first { $0.id == itemIdToDelete} )
//
//		let itemToDelete = MockFactrory.customItem(id: itemIdToDelete, name: "abc")
//		sut.itemDeleted(itemToDelete)
//		XCTAssertNil(sut.items.first { $0.id == itemIdToDelete} )
//	}
}
