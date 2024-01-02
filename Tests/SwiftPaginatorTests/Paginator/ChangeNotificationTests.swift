//
//  ChangeNotificationTests.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import XCTest
import SwiftPaginator

final class ChangeNotificationTests: XCTestCase {

	let defaultItems = (0..<75).map(DummyItem.init)
	
	var be: MockFetchProvider<DummyItem, Void>!
	var sut: Paginator<DummyItem, Void>!
	var nc: NotificationCenter!
	
    override func setUpWithError() throws {
		be = MockFetchProvider(defaultItems)
		nc = NotificationCenter()
		sut = Paginator(.init(pageSize: 30, notificationCenter: nc), requestProvider: be)
    }

    override func tearDownWithError() throws {
		be = nil
		nc = nil
		sut = nil
    }
	
	// MARK: - Add

    func testAdd_onInitialState() async throws {
		XCTAssertEqual(sut.items.count, 0)
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation.add(DummyItem(-1)))
		XCTAssertEqual(sut.items.count, 1)
    }

	func testAdd_withFullPage() async throws {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		let newItem = DummyItem(-1)
		be.source = .fakeBE([newItem] + defaultItems)
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation.add(newItem))
		XCTAssertEqual(sut.items.count, 31)
		
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 60)
		
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 76)
	}
	
	func testAdd_withFullPage_twice() async throws {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		let newItem = DummyItem(-1)
		be.source = .fakeBE([newItem] + defaultItems)
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation.add(newItem))
		XCTAssertEqual(sut.items.count, 31)

		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation.add(newItem))
		XCTAssertEqual(sut.items.count, 31)
	}

	
	// MARK: - Delete

	func testDelete_middle() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation<DummyItem>.delete(id: defaultItems[10].id))
		XCTAssertEqual(sut.items.count, 29)
		XCTAssertEqual(sut.items[0].id, "0")
		XCTAssertEqual(sut.items.last!.id, "29")
	}

	func testDelete_first() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation<DummyItem>.delete(id: defaultItems[0].id))
		XCTAssertEqual(sut.items.count, 29)
		XCTAssertEqual(sut.items[0].id, "1")
		XCTAssertEqual(sut.items.last!.id, "29")
	}

	func testDelete_last() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation<DummyItem>.delete(id: defaultItems[29].id))
		XCTAssertEqual(sut.items.count, 29)
		XCTAssertEqual(sut.items[0].id, "0")
		XCTAssertEqual(sut.items.last!.id, "28")
	}

	func testDelete_notFound() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation<DummyItem>.delete(id: defaultItems[33].id))
		XCTAssertEqual(sut.items.count, 30)
	}
	
	// MARK: - Edits
	
	func testEdit_existed() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		var changedItem = sut.items[1]
		changedItem.name = "updated"
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation.edit(changedItem))

		XCTAssertEqual(sut.items.count, 30)
		XCTAssertEqual(sut.items[1].name, "updated")
		for i in 0..<29 {
			if i == 1 { continue }
			XCTAssertEqual(sut.items[i].name, "name_\(i)")
		}
	}

	func testEdit_notFound() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		var changedItem = DummyItem(35)
		changedItem.name = "updated"
		nc.post(name: .paginatorEditOperation, object: ExternalEditOperation.edit(changedItem))

		XCTAssertEqual(sut.items.count, 30)
		for i in 0..<29 {
			XCTAssertEqual(sut.items[i].name, "name_\(i)")
		}

	}

}
