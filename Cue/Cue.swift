//
//  Cue.swift
//  Cue
//
//  Created by Dylan McArthur on 10/14/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public class Cue {
	
	var text: [UInt16]
	
	init(withString string: String) {
		//	here would be a good time to do any preprocessing
		self.text = [UInt16](string.utf16)
	}
	
	public func parsedDocument() -> CueNode {
		let tokens = CueLexer.lex(bytes: text)
		let tree = CueParser.ast(fromTokens: tokens)
		return tree
	}
	
}
