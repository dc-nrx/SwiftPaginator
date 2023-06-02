//
//  Types.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.02.2023.
//

import Foundation

public typealias PaginatorItem = Comparable & Identifiable

public typealias FetchClosure<Item: PaginatorItem, Filter> = (_ page: Int, _ count: Int, Filter?) async throws -> [Item]

public enum PaginatorLoadingState: Equatable {
	case initial
	/// There is no loading at the moment.
	case notLoading
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
}
