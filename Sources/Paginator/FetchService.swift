//
//  FetchService.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation


public class FetchService<Element, Filter> {
	
	typealias Filter = [String: String]
	
	public var filter: Filter? = nil
	
	public func fetch(
		count: Int,
		page: Int
	) async throws -> [Element] {
		fatalError("abstract class")
		//fetch(FetchRequest(count: count, page: page, filter: nil)
	}
}
