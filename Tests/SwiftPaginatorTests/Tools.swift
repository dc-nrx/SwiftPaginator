//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 05.10.2023.
//

import Foundation
import Combine
import XCTest

import SwiftPaginator

public extension CancellablesOwner {
	
	func expectState<T: StatePublisher>(
		_ statePublisher: T,
		_ expectedState: T.State,
		timeout: TimeInterval = 0.2
	) -> XCTestExpectation {
		let expectation = XCTestExpectation(description: "Expecting state to be \(expectedState)")
		
		statePublisher.state
			.first(where: { $0 == expectedState })
			.sink(receiveValue: { _ in
				expectation.fulfill()
			})
			.store(in: &cancellables)
		
		return expectation
	}
}
