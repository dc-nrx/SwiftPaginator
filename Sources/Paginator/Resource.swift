//
//  Resourse.swift
//  
//
//  Created by Dmytro Chapovskyi on 29.01.2023.
//

import Foundation

public protocol ResourceProtocol: Identifiable {

	var createdAt: Date { get }
	var updatedAt: Date { get }
//	var mainThumb: RemoteMedia? { get } // Folder: (coverURL) ?? (build from coverMediaID) || Holding: build from ID and type
//	var alternativeThumbs: [RemoteMedia] { get }
	var name: String { get }
}
