//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

import Foundation

public enum FetchType: Equatable {
	/// Clear everything up and fetch the very first page from scratch.
	case refresh
	/// Fetch the next page.
	case fetchNext
	/// Refetch last - the common use case is when the last page has fewer elements than `pageSize`.
	/// And, therefore, has to be reloaded in order to see if there are any elements added to the end of the list.
	///
	/// However, the better way to check for new elements might be `refetchFirst`,
	/// as they are usually added to the head of the list.
	case refetchLast
	/// Might be useful to get the latest BE updates, including renames, updates, etc. - without losing already fetched data.
	case refetchFirst
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
