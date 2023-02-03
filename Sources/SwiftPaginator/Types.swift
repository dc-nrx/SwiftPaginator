//
//  Types.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.02.2023.
//

import Foundation

public typealias PaginatorItem = Comparable & Identifiable

public typealias FetchFunction<Item: PaginatorItem, Filter> = (_ count: Int, _ page: Int, Filter?) async throws -> [Item]

public enum PaginatorLoadingState {
	/// There is no loading at the moment.
	case notLoading
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
}
