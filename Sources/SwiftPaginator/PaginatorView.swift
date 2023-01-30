//
//  Paginator 2View.swift
//  
//
//  Created by Dmytro Chapovskyi on 30.01.2023.
//

import SwiftUI

public struct PaginatorView: View {
	
	@ObservedObject private var vm: PaginatorVM<DummyFetchService>

	public init(vm: PaginatorVM<DummyFetchService>) {
		self.vm = vm
	}
	
	public var body: some View {
		ScrollView {
			LazyVStack {
				ForEach(vm.items) { item in
					Text(item.name)
						.onAppear {
							vm.onItemShown(item)
						}
				}
				ProgressView()
					.opacity(vm.loadingState == .fetchingNextPage ? 0 : 1)
			}
		}
		.onAppear {
			vm.onViewDidAppear()
		}
		.background(Color.gray)
	}
}

struct Paginator_2View_Previews: PreviewProvider {
	static var vm = PaginatorVM(fetchService: DummyFetchService(totalItems: 3000), itemsPerPage: 50)
	
	static var previews: some View {
		PaginatorView(vm: vm)
	}
}
