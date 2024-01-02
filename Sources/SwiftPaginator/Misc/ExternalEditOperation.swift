//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import Foundation

/// Send it whenever there's a changing operation elsewhere to avoid redundant refreshes.
public extension Notification.Name {
	/// Contains the added object
	static let paginatorEditOperation = Notification.Name("paginatorEditOperation")
}

public enum ExternalEditOperation<Item: Identifiable> {
	case delete(id: Item.ID)
	case add(Item)
	case edit(Item, moveToTop: Bool)
	
	public var itemId: Item.ID {
		switch self {
		case .delete(let id): id
		case .add(let item), .edit(let item, _): item.id
		}
	}
}
