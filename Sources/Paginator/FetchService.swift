//
//  FetchService.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public class FetchService<Element> {
	
	func fetch(
		count: Int,
		page: Int
	) async throws -> [Element] {
		fatalError("abstract class")
	}
}

final class DummyFetchService: FetchService<ComparableDummy> {
	
	// MARK: - fetch
	
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
		return try await fetchCountPageClosure?(count, page) ?? fetchCountPageReturnValue
	}
}
