//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.10.2023.
//

public enum PaginatorState: Equatable {
	case initial
	/// There is no loading at the moment.
	case notLoading
	/// Fetch next page in progress.
	case fetchingNextPage
	/// Refresh in progress (i.e. `fetchNextPage(cleanBeforeUpdate: true)`)
	case refreshing
}
