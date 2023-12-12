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
		XCTAssertTrue(PaginatorState.fetching(.refresh).fetchInProgress)
		XCTAssertTrue(PaginatorState.discardingOldData.fetchInProgress)
		XCTAssertTrue(PaginatorState.processingReceivedData.fetchInProgress)

		XCTAssertFalse(PaginatorState.initial.fetchInProgress)
		XCTAssertFalse(PaginatorState.finished.fetchInProgress)
		XCTAssertFalse(PaginatorState.cancelled.fetchInProgress)
		XCTAssertFalse(PaginatorState.error(NSError()).fetchInProgress)
	}

	func testTransitionValid() {
		XCTAssertTrue(PaginatorState.transitionValid(from: .fetching(.nextPage), to: .processingReceivedData))
		XCTAssertTrue(PaginatorState.transitionValid(from: .fetching(.nextPage), to: .cancelled))

		XCTAssertTrue(PaginatorState.transitionValid(from: .processingReceivedData, to: .finished))

		XCTAssertTrue(PaginatorState.transitionValid(from: .initial, to: .fetching(.nextPage)))
		XCTAssertTrue(PaginatorState.transitionValid(from: .initial, to: .fetching(.refresh)))
		XCTAssertTrue(PaginatorState.transitionValid(from: .finished, to: .fetching(.nextPage)))
		XCTAssertTrue(PaginatorState.transitionValid(from: .finished, to: .fetching(.refresh)))
		XCTAssertTrue(PaginatorState.transitionValid(from: .cancelled, to: .fetching(.nextPage)))
		XCTAssertTrue(PaginatorState.transitionValid(from: .cancelled, to: .fetching(.refresh)))
		XCTAssertTrue(PaginatorState.transitionValid(from: .error(PaginatorError.wrongStateTransition(from: .cancelled, to: .initial)), to: .fetching(.refresh)))

		XCTAssertTrue(PaginatorState.transitionValid(from: .processingReceivedData, to: .error(NSError())))
	}

}
