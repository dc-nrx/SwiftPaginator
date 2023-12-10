//
//  StateTests.swift
//  
//
//  Created by Dmytro Chapovskyi on 10.12.2023.
//

import XCTest
import SwiftPaginator

final class StateTests: XCTestCase {

	func testFetchInProgress() {
		XCTAssertTrue(State.fetching(.refresh).fetchInProgress)
		XCTAssertTrue(State.discardingOldData.fetchInProgress)
		XCTAssertTrue(State.processingReceivedData.fetchInProgress)

		XCTAssertFalse(State.initial.fetchInProgress)
		XCTAssertFalse(State.finished.fetchInProgress)
		XCTAssertFalse(State.cancelled.fetchInProgress)
		XCTAssertFalse(State.error(NSError()).fetchInProgress)
	}

	func testTransitionValid() {
		XCTAssertTrue(State.transitionValid(from: .fetching(.fetchNext), to: .processingReceivedData))
		XCTAssertTrue(State.transitionValid(from: .fetching(.fetchNext), to: .cancelled))

		XCTAssertTrue(State.transitionValid(from: .processingReceivedData, to: .finished))

		XCTAssertTrue(State.transitionValid(from: .initial, to: .fetching(.fetchNext)))
		XCTAssertTrue(State.transitionValid(from: .initial, to: .fetching(.refresh)))
		XCTAssertTrue(State.transitionValid(from: .finished, to: .fetching(.fetchNext)))
		XCTAssertTrue(State.transitionValid(from: .finished, to: .fetching(.refresh)))
		XCTAssertTrue(State.transitionValid(from: .cancelled, to: .fetching(.fetchNext)))
		XCTAssertTrue(State.transitionValid(from: .cancelled, to: .fetching(.refresh)))
		XCTAssertTrue(State.transitionValid(from: .error(PaginatorError.wrongStateTransition(from: .cancelled, to: .initial)), to: .fetching(.refresh)))

		XCTAssertTrue(State.transitionValid(from: .processingReceivedData, to: .error(NSError())))
	}

}
