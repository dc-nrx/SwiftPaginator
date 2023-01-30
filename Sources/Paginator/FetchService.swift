//
//  FetchService.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation


public protocol Filter { }

// custom implementation for filtered requests
//struct FetchRequest {
//	var count: Int
//	var page: Int
//	var filter: Filter?
//}

public class FetchService<Element> {
	
//	public func makeRequest() -> FetchRequest
//	public func fetch(_ request: FetchRequest) async throws -> [Element] {
//		fatalError("abstract class")
//	}
	
	public var filter: Filter? = nil
	
	public func fetch(
		count: Int,
		page: Int
	) async throws -> [Element] {
		fatalError("abstract class")
		//fetch(FetchRequest(count: count, page: page, filter: nil)
	}
}
