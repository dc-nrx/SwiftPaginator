//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation

public enum FetchType: Equatable {
	case refresh, refetchLast, fetchNext
}

public enum State {

	case initial
	case active(FetchType)
	/// There is no loading at the moment.
	case finished
	/// Fetch has been cancelled
	case cancelled
	/// An error occured during execution of the underlying fetch reuqest
	case fetchError(Error)
}

public extension State {

	var isOperation: Bool {
		switch self {
		case .active:
			return true
		case .initial, .finished, .fetchError, .cancelled:
			return false
		}
	}
}

extension State: Equatable {
	public static func == (lhs: State, rhs: State) -> Bool {
		switch (lhs, rhs) {
		case (.initial, .initial):
			return true
		case (.finished, .finished):
			return true
		case let (.active(type1), .active(type2)):
			return type1 == type2
		case (.cancelled, .cancelled):
			return true
		case let (.fetchError(error1), .fetchError(error2)):
			return (error1 as NSError).isEqual(error2 as NSError)
		default:
			return false
		}
	}
}

extension State: CustomStringConvertible {
	public var description: String {
		switch self {
		case .initial:
			return "Initial State"
		case .finished:
			return "Finished Loading"
		case .active(let type):
			return "Active \(type)"
		case .cancelled:
			return "Fetch Interrupted"
		case .fetchError(let error):
			return "Network error \(error)"
		}
	}
}
