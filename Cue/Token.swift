//
//  Tokens.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public struct CueLexerToken: CustomStringConvertible {
	
	public var type: CueNodeType
	public var text: [UInt16]
	public var location: Int
	public var length: Int
	public var offset: Int
	
	public var description: String {
		let str = String(utf16CodeUnits: text, count: text.count)
		return "\(type)(\(location),\(length)):  \"\(str)\""
	}
	
}
