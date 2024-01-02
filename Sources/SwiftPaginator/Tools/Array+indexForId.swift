//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import Foundation

extension Array where Element: Identifiable {
	
	func index(for id: Element.ID) -> Index? {
		firstIndex(where: { $0.id == id} )
	}
}
