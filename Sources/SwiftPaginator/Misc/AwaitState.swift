//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 09.12.2023.
//

import Foundation
import Combine

public protocol CancellablesOwner: AnyObject {
	var cancellables: Set<AnyCancellable> { get set }
}

public extension CancellablesOwner {

	func waitUntil<T: StatePublisher>(
		_ statePublisher: T,
		in state: T.State
	) async {
		await withCheckedContinuation { continuation in
			statePublisher.statePublisher
				.filter { $0 == state }
				.first()
				.sink { _ in continuation.resume() }
				.store(in: &cancellables)
		}
	}
	
	func waitUntil<T: StatePublisher>(
		_ statePublisher: T,
		inOneOf states: [T.State]
	) async {
		await withCheckedContinuation { continuation in
			statePublisher.statePublisher
				.filter { states.contains($0) }
				.first()
				.sink { _ in continuation.resume() }
				.store(in: &cancellables)
		}
	}
}

public protocol StatePublisher {
	associatedtype State: Equatable

	var statePublisher: AnyPublisher<State, Never> { get }
}

extension Paginator: StatePublisher {
	
	public var statePublisher: AnyPublisher<PaginatorState, Never> {
		$state.eraseToAnyPublisher()
	}

}
