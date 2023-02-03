//
//  Tools.swift
//  
//
//  Created by Dmytro Chapovskyi on 03.02.2023.
//

import Foundation

public func pp(
	_ str: String,
	file: String = #file,
	function: String = #function,
	line: Int = #line,
	funNameMaxLen: Int = 30
) {
	let funAdjusted: String
	if function.count > funNameMaxLen {
		funAdjusted = function.prefix(27) + "..."
	} else {
		funAdjusted = function
	}
	let lastPathComponentHighlighted = "[" + URL(string: file)!.lastPathComponent.prefix { $0 != "." } + "]"
	let fileUtf8 = (lastPathComponentHighlighted as NSString).utf8String!
	let funUtf8 = (funAdjusted as NSString).utf8String!
	let strUtf8 = (str as NSString).utf8String!
	let str = String(format: "##  %-20s:%-3d %-\(funNameMaxLen)s  --> %s", fileUtf8, line, funUtf8, strUtf8)
	print(str)

}
