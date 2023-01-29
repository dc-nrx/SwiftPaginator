//
//  PaginatorVM.swift
//
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation
import Combine

/**
 Stores sorted collection of `Item`s and provides relevant fetch operations. Can be used as a view model in either list or grid view.
 */
public class PaginatorVM<Item: PaginatorItem>: ObservableObject {
		
	/**
	 The items fetched from `itemFetchService`.
	 */
	public private(set) var items = CurrentValueSubject<[Item], Never>([])
	
	/**
	 Indicated that loading is currently in progress
	 */
	public private(set) var loadingState = CurrentValueSubject<PaginatorLoadingState, Never>(.notLoading)
	
	public let distanceBeforeLoadNextPage = 10
	
	private let paginator: Paginator<Item>
	private var cancellables = Set<AnyCancellable>()
	
	init(paginator: Paginator<Item>) {
		self.paginator = paginator
	}

	/**
	 Fetch the next items page.
	 
	 - Parameter cleanBeforeUpdate: If `true`, makes a "fresh fetch" of the 0 page
	 and replaces the current `items` value with the fetched result on success. The `items` value
	 does not get cleared in case of fetch error.
	 */
	public func fetchNextPage(
		cleanBeforeUpdate: Bool = false
	) async {
		do {
			try await paginator.fetchNextPage(cleanBeforeUpdate: cleanBeforeUpdate)
		} catch {
			handleError(error)
		}
	}
	
	func handleError(_ error: Error) {
		// show error
	}
}

// MARK: - Event handling
public extension PaginatorVM {
	
	func onViewDidAppear() async {
		await fetchNextPage(cleanBeforeUpdate: true)
	}
	
	/**
	 Call to trigger next page fetch when the list is scrolled far enough.
	 */
	func onItemShown(_ item: Item) async {
		if let idx = items.value.firstIndex(of: item),
		   idx > items.value.count - distanceBeforeLoadNextPage {
			await fetchNextPage()
		}
	}
	
	func onRefresh() async {
		await fetchNextPage(cleanBeforeUpdate: true)
	}
}


// MARK: - Private
private extension PaginatorVM {

	func subscribeToPaginatorUpdates() {
		paginator.$items
			.receive(on: RunLoop.main)
			.subscribe(items)
			.store(in: &cancellables)
		
		paginator.$loadingState
			.receive(on: RunLoop.main)
			.subscribe(loadingState)
			.store(in: &cancellables)
	}
}
