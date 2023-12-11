//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 10.12.2023.
//

import Foundation


public enum Mocks {

	public static let fetchService = DummyFetchService(totalItems: 250)
	
	public static func paginator(
	) -> Paginator<DummyItem, DummyFilter> {		
		return Paginator<DummyItem, DummyFilter>(.init(), requestProvider: fetchService)
	}


	public static func vm(
		prefetchDistance: Int = 50
	) -> PaginatorVM<DummyItem, DummyFilter> {
		PaginatorVM<DummyItem, DummyFilter>(paginator: paginator(), prefetchDistance: prefetchDistance)
	}
	
}

public extension PaginatorVM {
}

public extension Paginator {
	static func mock() -> Paginator<DummyItem, DummyFilter> {
		let fetchService = DummyFetchService(totalItems: 44)
		return Paginator<DummyItem, DummyFilter>(.init(), requestProvider: fetchService)
	}
}
