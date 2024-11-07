//
//  ChangeNotificationTests.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import XCTest
@testable import SwiftPaginator

final class ChangeNotificationTests: XCTestCase {

	let defaultItems = (0..<75).map(DummyItem.init)
	
	var be: MockFetchProvider<DummyItem, Void>!
	var sut: Paginator<DummyItem, Void>!
	var notifier: PaginatorNotifier!
	
    override func setUpWithError() throws {
		be = MockFetchProvider(defaultItems)
		notifier = .init(.init())
		sut = Paginator(.init(pageSize: 30, notifier: notifier), requestProvider: be)
    }

    override func tearDownWithError() throws {
		be = nil
		notifier = nil
		sut = nil
    }
	
	// MARK: - Add

    func testAdd_onInitialState() async throws {
		XCTAssertEqual(sut.items.count, 0)
		notifier.post(.add(DummyItem(-1), nil))
		XCTAssertEqual(sut.items.count, 1)
    }

	func testAdd_withFullPage() async throws {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		let newItem = DummyItem(-1)
		be.source = .fakeBE([newItem] + defaultItems)
		notifier.post(.add(newItem, nil))
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
		notifier.post(.add(newItem, nil))
		XCTAssertEqual(sut.items.count, 31)

		notifier.post(.add(newItem, nil))
		XCTAssertEqual(sut.items.count, 31)
	}

    func testAdd_sameParentID_itemAdded() async throws {
        XCTAssertEqual(sut.items.count, 0)
        let id = "1"
        sut.configuration.parentId = id
        notifier.post(.add(DummyItem(-1), id))
        XCTAssertEqual(sut.items.count, 1)
    }

    func testAdd_differentParentIDs_itemNotAdded() async throws {
        XCTAssertEqual(sut.items.count, 0)
        sut.configuration.parentId = "1"
        notifier.post(.add(DummyItem(-1), "2"))
        XCTAssertEqual(sut.items.count, 0)
    }

    func testAdd_confNoParent_itemHasParent_itemAdded() async throws {
        XCTAssertEqual(sut.items.count, 0)
        notifier.post(.add(DummyItem(-1), "1"))
        XCTAssertEqual(sut.items.count, 1)
    }

    func testAdd_confHasParent_itemNoParent_itemNotAdded() async throws {
        XCTAssertEqual(sut.items.count, 0)
        sut.configuration.parentId = "1"
        notifier.post(.add(DummyItem(-1), nil))
        XCTAssertEqual(sut.items.count, 0)
    }
    // TODO: add same for deletes

	// MARK: - Delete

	func testDelete_middle() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
        XCTAssertEqual(sut.total, defaultItems.count)
		
		notifier.post(.delete(defaultItems[10], nil))
		XCTAssertEqual(sut.items.count, 29)
		XCTAssertEqual(sut.items[0].id, "0")
		XCTAssertEqual(sut.items.last!.id, "29")
        XCTAssertEqual(sut.total, defaultItems.count - 1)
	}

	func testDelete_first() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
        XCTAssertEqual(sut.total, defaultItems.count)

		notifier.post(.delete(defaultItems[0], nil))
		XCTAssertEqual(sut.items.count, 29)
		XCTAssertEqual(sut.items[0].id, "1")
		XCTAssertEqual(sut.items.last!.id, "29")
        XCTAssertEqual(sut.total, defaultItems.count - 1)
	}

	func testDelete_last() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
        XCTAssertEqual(sut.total, defaultItems.count)
        
		notifier.post<DummyItem>(.delete(defaultItems[29], nil))
		XCTAssertEqual(sut.items.count, 29)
		XCTAssertEqual(sut.items[0].id, "0")
		XCTAssertEqual(sut.items.last!.id, "28")
        XCTAssertEqual(sut.total, defaultItems.count - 1)
	}

	func testDelete_notFound() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
        XCTAssertEqual(sut.total, defaultItems.count)

		notifier.post(.delete(defaultItems[33], nil))
		XCTAssertEqual(sut.items.count, 30)
        XCTAssertEqual(sut.total, defaultItems.count)
	}
	
	// MARK: - Edits
	
	func testEdit_existed_notMoveToTop() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		var changedItem = sut.items[1]
		changedItem.name = "updated"
		notifier.post(.edit(changedItem, moveToTop: false))

		XCTAssertEqual(sut.items.count, 30)
		XCTAssertEqual(sut.items[1].name, "updated")
		for i in 0..<29 {
			if i == 1 { continue }
			XCTAssertEqual(sut.items[i].name, "name_\(i)")
		}
        XCTAssertEqual(sut.total, defaultItems.count)
	}

	func testEdit_existed_moveToTop() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		var changedItem = sut.items[1]
		changedItem.name = "updated"
		notifier.post(.edit(changedItem, moveToTop: true))

		XCTAssertEqual(sut.items.count, 30)
		XCTAssertEqual(sut.items[0].name, "updated")
		XCTAssertEqual(sut.items[1].name, "name_0")
		for i in 2..<29 {
			XCTAssertEqual(sut.items[i].name, "name_\(i)")
		}
        XCTAssertEqual(sut.total, defaultItems.count)
	}

	func testEdit_notFound() async {
		await sut.fetch(.nextPage)
		XCTAssertEqual(sut.items.count, 30)
		
		var changedItem = DummyItem(35)
		changedItem.name = "updated"
		notifier.post(.edit(changedItem, moveToTop: false))

		XCTAssertEqual(sut.items.count, 30)
		for i in 0..<29 {
			XCTAssertEqual(sut.items[i].name, "name_\(i)")
		}
        XCTAssertEqual(sut.total, defaultItems.count)
	}

}
