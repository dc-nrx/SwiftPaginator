//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

public enum State: Equatable {
	
	case initial
	/// There is no loading at the moment.
	case finished
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Re-fetching last page in progress.
	case refetchingLast
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
	/// Fetch has thrown an error
	case interrupted
	
	public var inProgress: Bool {
		switch self {
		case .fetchingNextPage, .refreshing, .refetchingLast:
			return true
		case .initial, .finished, .interrupted:
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
		case .interrupted:
			return "Fetch Interrupted"
		}
	}
}
