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
	/// Fetch the next page (or fetch once again the last one, if it had fewer items then `pageCount`)
	case fetchNext
}

public enum State {
	/// The initial state, before any fetching has started.
	case initial

	/// The state during an active fetch operation, with the type of fetch.
	case fetching(FetchType)

	/// The state indicating the old data is being discarded.
	case discardingOldData

	/// The state when newly received data is being processed.
	case processingReceivedData

	/// The state indicating that loading has finished.
	case finished

	/// The state when a fetch operation has been cancelled.
	case cancelled

	/// The state indicating an error occurred during the fetch operation.
	case error(Error)
}

public extension State {

	var fetchInProgress: Bool {
		switch self {
		case .fetching, .discardingOldData, .processingReceivedData:
			return true
		case .initial, .finished, .error, .cancelled:
			return false
		}
	}
	
	static func transitionValid(
		from: State,
		to: State
	) -> Bool {
		switch (from, to) {
		case (.fetching, .processingReceivedData),
			(.fetching, .cancelled): true

		case (.processingReceivedData, .finished): true
			
		case (.initial, .fetching),
			(.finished, .fetching),
			(.cancelled, .fetching),
			(.error, .fetching): true
			
		case (_, .error): true
			
		default: false
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
		case let (.fetching(type1), .fetching(type2)):
			return type1 == type2
		case (.cancelled, .cancelled):
			return true
		case let (.error(error1), .error(error2)):
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
		case .fetching(let type):
			return "Fetching (\(type))"
		case .discardingOldData:
			return "Discarding Old Data"
		case .processingReceivedData:
			return "Processing Received Data"
		case .finished:
			return "Finished Loading"
		case .cancelled:
			return "Fetch Cancelled"
		case .error(let error):
			return "Fetch Error: \(error)"
		}
	}
}
