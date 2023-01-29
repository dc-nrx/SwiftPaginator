import XCTest
@testable import Paginator

final class PaginatorTests: XCTestCase {
	
	let kOptionalResponseDelay = 0.5
	
	var fetchServiceMock: DummyFetchService!
	var sut: Paginator<ComparableDummy>!
	
	override func setUpWithError() throws {
		fetchServiceMock = DummyFetchService() //FoldersRepositoryMock()
		sut = Paginator(fetchService: fetchServiceMock) //FoldersListVM(itemFetchService: fetchServiceMock)
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
	
	func testFetch_receive0Folders_pageNotIncreased() async throws {
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
	
}
