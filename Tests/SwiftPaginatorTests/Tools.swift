//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 05.10.2023.
//

import Foundation
import Combine

import SwiftPaginator

public protocol CancellablesOwner: AnyObject {
	var cancellables: Set<AnyCancellable>! { get set }
}

public protocol StatePublisher {
	associatedtype State: Equatable
	
	var state: AnyPublisher<State, Never> { get }
}

public extension CancellablesOwner {

	func waitUntil<T: StatePublisher>(_ stateProvider: T, in state: T.State) async {
		await withCheckedContinuation { continuation in
			stateProvider.state
				.filter { $0 == state }
				.first()
				.sink { _ in continuation.resume() }
				.store(in: &cancellables)
		}
	}
}

extension Paginator: StatePublisher {
	
	public var state: AnyPublisher<State, Never> {
		$loadingState.eraseToAnyPublisher()
	}
}
