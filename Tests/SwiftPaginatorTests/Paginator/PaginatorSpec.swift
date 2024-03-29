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
		XCTAssertEqual(sut.nextPage, 0)
		XCTAssertEqual(sut.state, .initial)
	}
	
	// MARK: - Page
	
	func testFetch_receive0Items_pageNotIncreased() async throws {
		fetchServiceMock.fetchCountPageReturnValue = []
		await sut.fetch()
		let page = sut.nextPage
		XCTAssertEqual(page, 0)
	}
	
	func testFetch_receivedNotFullPage_pageNotIncreased() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 29)
		await sut.fetch()
		let page = sut.nextPage
		XCTAssertEqual(page, 0)
	}
	
	func testFetch_receivedFullPage_pageIncreased() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 30)
		await sut.fetch()
		let page = sut.nextPage
		XCTAssertEqual(page, 1)
	}
	
	func testFetch_receivedLongerPageThanExpexted_pageIncreasedBy1() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 38)
		await sut.fetch()
		let page = sut.nextPage
		XCTAssertEqual(page, 1)
	}
	
	func testFetch_firstIndexNonZero_canLoadFirst2Pages() {
		
	}
	
	// MARK: - Items
	
	func testFetch_receivedNotFullPage_itemsCountCorrect() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: kItemsPerPage - 1)
		await sut.fetch()
		XCTAssertEqual(sut.items.count, kItemsPerPage - 1)
		XCTAssertEqual(sut.total, kItemsPerPage - 1)
	}
	
	func testFetchViaMockClosure_receiveNormalPage_itemsCountCorrect() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: kItemsPerPage)
		await sut.fetch()
		let items = sut.items
		XCTAssertEqual(items.count, kItemsPerPage)
		XCTAssertEqual(sut.total, kItemsPerPage)
	}
	
	func testFetch_withNoParams_notResetsExistedData() async throws {
		let total = 5 * kItemsPerPage
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: total)
		await sut.fetch()
		XCTAssertEqual(sut.total, total)
		await sut.fetch()
		XCTAssertEqual(sut.total, total)

		XCTAssertEqual(sut.items.count, 60)
		XCTAssertEqual(sut.nextPage, 2)
	}
	
	func testFetch_repeatedCalls_noRepeatedRequest() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.nextPage)
			async let b: () = sut.fetch(.nextPage)
			async let c: () = sut.fetch(.nextPage)
			let _ = await [a, b, c]
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
			let _ = await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testRefreshAndFetch_repeatedMixedCalls_noRepeatedRequests() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.refresh)
			async let b: () = sut.fetch(.nextPage)
			async let c: () = sut.fetch(.refresh)
			let _ = await [a, b, c]
		}
		try! await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testFetchAndRefresh_repeatedMixedCalls_noRepeatedRequests() async throws {
		fetchServiceMock.setupFetchClosureWithTotalItems(totalItems: 0)
		fetchServiceMock.fetchDelay = kOptionalResponseDelay
		Task {
			async let a: () = sut.fetch(.nextPage)
			async let b: () = sut.fetch(.refresh)
			async let c: () = sut.fetch(.nextPage)
			let _ = await [a, b, c]
		}
		try await Task.sleep(nanoseconds: UInt64(kOptionalResponseDelay / 2 * Double(NSEC_PER_SEC)))
		XCTAssertEqual(fetchServiceMock.fetchCountPageCallsCount, 1)
	}
	
	func testSameIds_inLastPage_areNotDuplicated() async throws {
		let testResponse = [DummyItem(),DummyItem(),DummyItem(),DummyItem()]
		fetchServiceMock.fetchCountPageReturnValue = testResponse
		sut.configuration = .init(merge: .dropSameIDs(prioritizeNewlyFetched: true))
		await sut.fetch()
		XCTAssertEqual(sut.nextPage, 0)
		XCTAssertEqual(sut.items.count, 4)
		await sut.fetch()
		XCTAssertEqual(sut.nextPage, 0)
		XCTAssertEqual(sut.items.count, 4)
	}
	
	// MARK: - In-place edits
	
	func testOnItemDeleted_2fullPages() async throws {
		let pages = [
			(0...29).map { _ in DummyItem() },
			(0...29).map { _ in DummyItem() }
		]
		let itemIdToDelete = pages[0][0].id
		fetchServiceMock.fetchCountPageClosure = { page, count in
			Page(pages[page])
		}
		
		sut.configuration = .init(merge: .dropSameIDs(prioritizeNewlyFetched: true))
		await sut.fetch()
		XCTAssertFalse(sut.reachedEnd)
		sut.delete(itemWithID: itemIdToDelete)
		
		XCTAssertFalse(sut.reachedEnd)
		XCTAssertNil(sut.items.first { $0.id == itemIdToDelete} )
		XCTAssertEqual(29, sut.items.count)

		await sut.fetch()
		XCTAssertEqual(0, sut.items.firstIndex { $0.id == itemIdToDelete} )
		XCTAssertEqual(30, sut.items.count)
		
		await sut.fetch()
		XCTAssertEqual(60, sut.items.count)
	}
    
    func testRangeDelete_affecting2Pages() async {
        let mockBE = MockFetchProvider(totalCount: 75)
        let sut = Paginator(.init(pageSize: 30), requestProvider: mockBE)
        
        await sut.fetch()
        await sut.fetch()
        XCTAssertEqual(60, sut.items.count)
        
        sut.delete(itemsByID: (25..<35).map { "\($0)" } )
        XCTAssertEqual(50, sut.items.count)
    }
	
	func testOnItemAdd_2fullPages() async throws {
		let itemToAdd = DummyItem(name: "-1")
		
		var items = (0...59).map { DummyItem(name: "\($0)") }
		fetchServiceMock.fetchCountPageClosure = { page, count in
			let subrange = page * count..<min((page + 1) * count, items.count)
			return Page(Array(items[subrange]))
		}
		
		sut.configuration = .init(merge: .dropSameIDs(prioritizeNewlyFetched: true))
		await sut.fetch()
		
		XCTAssertEqual(30, sut.items.count)
		
		sut.insert(itemToAdd)
		items.insert(itemToAdd, at: 0)
		fetchServiceMock.fetchCountPageClosure = { page, count in
			let subrange = page * count..<min((page + 1) * count, items.count)
			return Page(Array(items[subrange]))
		}
		
		XCTAssertEqual(31, sut.items.count)
		
		await sut.fetch()
		XCTAssertEqual(60, sut.items.count)

		await sut.fetch()
		XCTAssertEqual(61, sut.items.count)
	}
	
	// MARK: - Fetch cancellation
	
	func testForceFetch_cancelsOngoingFetch() {
		
	}
}
