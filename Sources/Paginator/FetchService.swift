//
//  FetchService.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public class FetchService<Element> {
	
	func fetch(
		count: Int,
		page: Int
	) async throws -> [Element] {
		fatalError("abstract class")
	}
}

