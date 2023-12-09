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

public protocol CancellablesOwner: AnyObject {
	var cancellables: Set<AnyCancellable>! { get set }
}

public extension CancellablesOwner {

	func waitUntil<T: StatePublisher>(
		_ statePublisher: T,
		in state: T.State
	) async {
		await withCheckedContinuation { continuation in
			statePublisher.state
				.filter { $0 == state }
				.first()
				.sink { _ in continuation.resume() }
				.store(in: &cancellables)
		}
	}
	
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

public protocol StatePublisher {
	associatedtype State: Equatable

	var state: AnyPublisher<State, Never> { get }
}

extension Paginator: StatePublisher {
	
	public var state: AnyPublisher<State, Never> {
		$loadingState.eraseToAnyPublisher()
	}

}
