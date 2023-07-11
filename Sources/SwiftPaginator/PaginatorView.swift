//
//  PaginatorView.swift
//  
//
//  Created by Dmytro Chapovskyi on 10.07.2023.
//

import Foundation
import SwiftUI

public struct PaginatorView<Item: Identifiable, Filter, Content: View>: View {
	
	@ObservedObject private var vm: PaginatorVM<Item, Filter>
	
	let content: (Item) -> Content

	public init(
		_ paginator: Paginator<Item, Filter>,
		distanceBeforeLoadNextPage: Int = 5,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self.vm = PaginatorVM(paginator: paginator, distanceBeforeLoadNextPage: distanceBeforeLoadNextPage)
		self.content = content
	}

	public var body: some View {
		ScrollView {
			LazyVStack {
				ForEach(vm.items) { item in
					content(item)
						.task {
							await vm.onItemShown(item)
						}
				}
			}
		}
		.task {
			await vm.fetchNextPage()
		}
	}
}
