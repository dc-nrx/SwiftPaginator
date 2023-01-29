//
//  FetchService.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public protocol FS {
	associatedtype Element
	
	func fetch(
		count: Int,
		page: Int
	) async throws -> [Element]
}

public class FetchService<Element>: FS {
	
	public func fetch(
		count: Int,
		page: Int
	) async throws -> [Element] {
		fatalError("abstract class")
	}
}

final class DummyFetchService: FetchService<ComparableDummy> {
	
	// MARK: - fetch
	override init() { }
	
	init(
		totalItems: Int,
		fetchDelay: TimeInterval? = nil
	) {
		self.fetchDelay = fetchDelay
		super.init()
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
				return Array(items[l ..< min(r, totalItems)])
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
	var fetchCountPageReturnValue = [ComparableDummy]()
	var fetchCountPageClosure: ((Int, Int) async throws -> [ComparableDummy])?
	
	override func fetch(count: Int, page: Int) async throws -> [ComparableDummy] {
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
