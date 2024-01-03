//
//  File.swift
//  
//
//  Created by Dmytro Chapovskyi on 02.01.2024.
//

import Foundation

/**
 Used to synchronise app-wide changes wihout a need to re-fetch data,
 or manually send notifications around.
 
 A common scenario would be sending an "item add request" somewhere, and posting a notification
 upon "success" response - so all the relevant paginators in the app would be able to update accordingly.
 
 An instance is passed to `Paginator` as a part of `PaginatorConfiguration`. 
 
 If observing is undesirable, it can be set to `nil` in the configuration.
 */
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
