import XCTest
@testable import Paginator

final class PaginatorTests: XCTestCase {
	
	let kOptionalResponseDelay = 0.5
	
	var fetchServiceMock: DummyFetchService!
	var sut: Paginator<ComparableDummy>!
	
	override func setUpWithError() throws {
		fetchServiceMock = DummyFetchService() //ItemsRepositoryMock()
		sut = Paginator(fetchService: fetchServiceMock) //ItemsListVM(itemFetchService: fetchServiceMock)
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
		fetchServiceMock.fetchCountPageReturnValue = (1..<sut.itemsPerPage).map(MockFactrory.item)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 0)
	}
	
	func testFetch_receivedFullPage_pageIncreased() async throws {
		fetchServiceMock.fetchCountPageReturnValue = (1...sut.itemsPerPage).map(MockFactrory.item)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 1)
	}
	
	func testFetch_receivedLongerPageThanExpexted_pageNotIncreased() async throws {
		fetchServiceMock.fetchCountPageReturnValue = (0...sut.itemsPerPage).map(MockFactrory.item)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.page, 1)
	}
	
	// MARK: - Items
	
	func testFetch_receivedNotFullPage_itemsCountCorrect() async throws {
		fetchServiceMock.fetchCountPageReturnValue = (1..<sut.itemsPerPage).map(MockFactrory.item)
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, sut.itemsPerPage - 1)
	}
	
	func testFetchViaMockClosure_receiveNormalPage_itemsCountCorrect() async throws {
		fetchServiceMock.fetchCountPageClosure = { count, page in
			return (0..<count).map { MockFactrory.item(num: $0, page: page) }
		}
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, 30)
	}
	
	func testFetch_withNoParams_notResetsExistedData() async throws {
		fetchServiceMock.fetchCountPageClosure = { [sut] count, page in
			(1...sut!.itemsPerPage).map(MockFactrory.item)
		}
		try await sut.fetchNextPage()
		try await sut.fetchNextPage()
		XCTAssertEqual(sut.items.count, 60)
		XCTAssertEqual(sut.page, 2)
	}
	
	func testFetch_repeatedCalls_noRepeatedRequest() async throws {
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
		var page0 = (0...29).map { MockFactrory.item(num: $0, page: 0) }
		var page1 = (0...29).map { MockFactrory.item(num: $0, page: 1) }
		
		let duplicateId = UUID().uuidString
		let updatedName = "UPDATED"
		page0[4] = MockFactrory.customItem(id: duplicateId, name: "Original", updatedAt: .now)
		page1[8] = MockFactrory.customItem(id: duplicateId, name: updatedName, updatedAt: .now + 1)
		
		fetchServiceMock.fetchCountPageReturnValue = page0
		try await sut.fetchNextPage()
		fetchServiceMock.fetchCountPageReturnValue = page1
		try await sut.fetchNextPage()
		
		let itemsWithSameId = sut.items.filter { $0.id == duplicateId }
		XCTAssertEqual(itemsWithSameId.count, 1)
		XCTAssertEqual(sut.items.count, 59)
		XCTAssertEqual(itemsWithSameId.first?.name, updatedName)
		XCTAssertEqual(sut.items.firstIndex { $0.id == duplicateId }, 0)
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
