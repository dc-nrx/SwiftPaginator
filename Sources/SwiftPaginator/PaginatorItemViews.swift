//
//  PaginatorView.swift
//  
//
//  Created by Dmytro Chapovskyi on 10.07.2023.
//

import Foundation
import SwiftUI

/**
 A 
 */
public struct PaginatorForEach<Item: Identifiable, Filter, Content: View>: View {
	
	@ObservedObject private var vm: PaginatorVM<Item, Filter>
	
	let content: (Item) -> Content

	public init(
		_ vm: PaginatorVM<Item, Filter>,
		@ViewBuilder content: @escaping (Item) -> Content
	) {
		self.vm = vm
		self.content = content
	}
	
	public var body: some View {
		ForEach(vm.items) { item in
			content(item)
				.task {
					await vm.onItemShown(item)
				}
		}
	}
}

#Preview {
	let vm = Mocks.vm(prefetchDistance: 80)
	
	return List {
		PaginatorForEach(vm) { item in
			Text(item.name)
		}
	}
	.task {
		await vm.onViewDidAppear()
	}
}
