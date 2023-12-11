//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 10.12.2023.
//

import Foundation

public extension Paginator {
	static func mock() -> Paginator<DummyItem, DummyFilter> {
		let fetchService = DummyFetchService(totalItems: 44)
		return Paginator<DummyItem, DummyFilter>(.init(), requestProvider: fetchService)
	}
}

public class PaginatorMock<T: PaginationRequestProvider>: Paginator<T.Item, T.Filter> {
	
	private let requestProvider: T
	
	public static func regular() -> PaginatorMock<DummyFetchService> {
		PaginatorMock<DummyFetchService>(requestProvider: DummyFetchService(totalItems: 44), configuration: .init())
	}
	
	public init(
		requestProvider: T,
		configuration: Configuration<T.Item>
	) {
		self.requestProvider = requestProvider
		super.init(configuration, fetch: requestProvider.fetch)
	}

}
