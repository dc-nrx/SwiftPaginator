//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation

public enum State {

	case initial
	/// There is no loading at the moment.
	case finished
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Re-fetching last page in progress.
	case refetchingLast
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
	/// Fetch has been cancelled
	case cancelled
	/// An error occured during execution of the underlying fetch reuqest
	case fetchError(Error)
}

public extension State {

	var isOperation: Bool {
		switch self {
		case .fetchingNextPage, .refreshing, .refetchingLast:
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
		case (.fetchingNextPage, .fetchingNextPage):
			return true
		case (.refetchingLast, .refetchingLast):
			return true
		case (.refreshing, .refreshing):
			return true
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
		case .fetchingNextPage:
			return "Fetching Next Page"
		case .refetchingLast:
			return "Refetching Last Page"
		case .refreshing:
			return "Refreshing"
		case .cancelled:
			return "Fetch Interrupted"
		case .fetchError(let error):
			return "Network error \(error)"
		}
	}
}
