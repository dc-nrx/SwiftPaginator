//
//  MockFactory.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

struct ComparableDummy: PaginatorItem {
	
	let id: String
	let name: String
	let updatedAt: Date
	
	static func < (lhs: ComparableDummy, rhs: ComparableDummy) -> Bool {
		lhs.updatedAt < rhs.updatedAt
	}
}

/**
 A factory with convenient methods to make mock objects.
 Is included here instead of tests target to be used for SwiftUI previews.
 */
final class MockFactrory {
	
	static func item(_ num: Int) -> ComparableDummy {
		customItem(name: "Auto-Generated Folder \(num)")
	}
	
	static func item(num: Int, page: Int) -> ComparableDummy {
		customItem(name: "Auto-generated Folder p\(page).n\(num)")
	}
	
	static func customItem(
		id: String = UUID().uuidString,
		name: String,
		updatedAt: Date = .now
	) -> ComparableDummy {
		ComparableDummy(id: id, name: name, updatedAt: updatedAt)
	}
}
