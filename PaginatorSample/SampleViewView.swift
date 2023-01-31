//
//  SampleViewView.swift
//  PaginatorSample
//
//  Created by Dmytro Chapovskyi on 30.01.2023.
//

import SwiftUI
import SwiftPaginator

public struct SampleView: View {
	
	
	let vm = PaginatorVM(
		fetchService: DummyFetchService(totalItems: 400, fetchDelay: 1),
		itemsPerPage: 50
	)
	
	public var body: some View {
		PaginatorView(vm: vm)
	}
}

//struct SampleView_Previews: PreviewProvider {
//	static var previews: some View {
//		SampleView()
//	}
//}
