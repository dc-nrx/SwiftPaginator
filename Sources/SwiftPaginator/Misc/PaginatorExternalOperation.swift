//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import Foundation

public class PaginatorNotifier {

	public enum Operation<Item: Identifiable> {
		case deleteId(Item.ID)
		case delete(Item)
		case add(Item)
		case edit(Item, moveToTop: Bool)
	}

	public static let `default` = PaginatorNotifier()
	
	public let notificationCenter: NotificationCenter
	
	public init(_ notificationCenter: NotificationCenter = .init()) {
		self.notificationCenter = notificationCenter
	}
	
	public func post<Item>(_ op: Operation<Item>) {
		notificationCenter.post(name: .paginatorEditOperation, object: op)
	}
}

/// Send it whenever there's a changing operation elsewhere to avoid redundant refreshes.
extension Notification.Name {
	/// Contains the added object
	static let paginatorEditOperation = Notification.Name("PaginatorNotifier.paginatorEditOperation")
}

extension PaginatorNotifier.Operation {
	var itemId: Item.ID {
		switch self {
		case .deleteId(let id): id
		case .add(let item), .edit(let item, _), .delete(let item): item.id
		}
	}
}
