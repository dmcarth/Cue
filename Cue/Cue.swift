//
//  Cue.swift
//  Cue
//
//  Created by Dylan McArthur on 10/14/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public class Cue {
	
	var parser = CueParser()
	
	var lexer = CueLexer()
	
	public func parse(_ string: String) -> CueNode {
		// Now would be a good time to do any preprocessing
		let bytes = [UInt16](string.utf16)
		
		return parse(bytes)
	}
	
	public func parse(_ bytes: [UInt16]) -> CueNode {
		let tokens = lexer.lex(bytes: bytes)
		let tree = parser.ast(fromTokens: tokens)
		return tree
	}
	
}
