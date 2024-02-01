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

    public typealias ParentID = String

	/// Enum defining operations that can be performed on items.
	public enum Operation<Item: Identifiable> {
        
        case deleteMultipleIds(Set<Item.ID>, ParentID?)
        
        /**
		 Have exactly the same effect as `delete`, but requires full type specification on the call site.
		 On the other hand, requires nothing expept the `id` - thus has a wider range of use.
		 */
        case deleteId(Item.ID, ParentID?)
		
		/**
		 Have exactly the same effect as `deleteId`, but is better understanded
		 by the compiler. Therefore, is advised to use when available.
		 */
        case delete(Item, ParentID?)
		
        case add(Item, ParentID?)
		
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

// MARK: - Internal

/// Send it whenever there's a changing operation elsewhere to avoid redundant refreshes.
extension Notification.Name {
	/// Contains the added object
	static let paginatorEditOperation = Notification.Name("PaginatorNotifier.paginatorEditOperation")
}

extension PaginatorNotifier.Operation {
	var affectedIDs: Set<Item.ID> {
		switch self {
        case .deleteMultipleIds(let idsCollection, _): idsCollection
		case .deleteId(let id, _): [id]
        case .add(let item, _), .edit(let item, _), .delete(let item, _): [item.id]
		}
	}
}
