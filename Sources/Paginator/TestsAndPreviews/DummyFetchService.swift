//
//  MockFactory.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public struct DummyFilter: Equatable {
	public var optionalFlag: Bool?
	public var mandatoryFlag: Bool
	public var from: Date?
	public var to: Date?
	public var id: String?
	
	init(
		optionalFlag: Bool? = nil,
		mandatoryFlag: Bool = false,
		from: Date? = nil,
		to: Date? = nil,
		itemId: ComparableDummy.ID? = nil,
		id: String = UUID().uuidString
	) {
		self.optionalFlag = optionalFlag
		self.mandatoryFlag = mandatoryFlag
		self.from = from
		self.to = to
		self.id = id
	}
}

struct ComparableDummy: PaginatorItem {
	
	let id: String
	let name: String
	let updatedAt: Date
	var filterUsed: DummyFilter?
	
	init(id: String,
		 name: String,
		 updatedAt: Date,
		 filterUsed: DummyFilter? = nil
	) {
		self.id = id
		self.name = name
		self.updatedAt = updatedAt
		self.filterUsed = filterUsed
	}
	
	static func < (lhs: ComparableDummy, rhs: ComparableDummy) -> Bool {
		lhs.updatedAt < rhs.updatedAt
	}
}

final class DummyFetchService: FetchService {
	typealias Element = ComparableDummy
	typealias Filter = DummyFilter
		
	var filter: Filter?
	// MARK: - fetch
	
	init(
		totalItems: Int = 0,
		fetchDelay: TimeInterval? = nil
	) {
		self.fetchDelay = fetchDelay
		setupFetchClosureWithTotalItems(totalItems: totalItems)
	}
	
	public func setupFetchClosureWithTotalItems(totalItems: Int) {
		let items = (0...totalItems).map { i in
			ComparableDummy(id: UUID().uuidString, name: "Dummy Name \(i)", updatedAt: .now - TimeInterval(i))
		}
		fetchCountPageClosure = { count, page in
			let l = page * count
			let r = (page + 1) * count
			if l >= totalItems {
				return []
			} else {
				return Array(items[l ..< min(r, totalItems)]).map { dummy in
					var dummyCopy = dummy
					dummyCopy.filterUsed = self.filter
					return dummyCopy
				}
			}
		}
	}
	
	var fetchDelay: TimeInterval?
	
	var fetchCountPageThrowableError: Error?
	var fetchCountPageCallsCount = 0
	var fetchCountPageCalled: Bool {
		fetchCountPageCallsCount > 0
	}
	var fetchCountPageReceivedArguments: (count: Int, page: Int)?
	var fetchCountPageReceivedInvocations: [(count: Int, page: Int)] = []
	var fetchCountPageReturnValue = [ComparableDummy]() {
		didSet {
			fetchCountPageClosure = nil
		}
	}
	
	var fetchCountPageClosure: ((Int, Int) async throws -> [ComparableDummy])?
	
	func fetch(count: Int, page: Int) async throws -> [ComparableDummy] {
		if let error = fetchCountPageThrowableError {
			throw error
		}
		fetchCountPageCallsCount += 1
		fetchCountPageReceivedArguments = (count: count, page: page)
		fetchCountPageReceivedInvocations.append((count: count, page: page))
		if let delay = fetchDelay {
			try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
		}
		return try await fetchCountPageClosure?(count, page) ?? fetchCountPageReturnValue
	}
}
