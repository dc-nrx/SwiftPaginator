//
//  Playground.swift
//  
//
//  Created by Dmytro Chapovskyi on 31.01.2023.
//

import Foundation

public protocol AbstractService {
	associatedtype Filter
	func fetch(_ filter: Filter) -> [AnyObject]
}

public protocol StringService: AbstractService where Filter == String {
		
}

public class StringViewModel<FS: AbstractService> {
	
	let service: FS
	
	init(service: FS) where FS: StringService {
		self.service = service
	}
}


