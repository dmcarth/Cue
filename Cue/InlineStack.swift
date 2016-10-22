//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/21/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

class InlineStack {
	private(set) var array = [Inline]()
	
	var lastBracket: Delimiter?
	var lastBracketIndex: Int?
	
	var lastEmphasis: Delimiter?
	var lastEmphasisIndex: Int?
	
	var count: Int {
		return array.count
	}
	
	func push(_ inline: Inline) {
		array.append(inline)
		
		if let delim = inline as? Delimiter {
			if delim.type == .openBracket {
				lastBracket = delim
				lastBracketIndex = array.count-1
			} else if delim.type == .emph {
				lastEmphasis = delim
				lastEmphasisIndex = array.count-1
			}
		}
	}
	
	func pop() -> Inline? {
		return array.popLast()
	}
	
	func peek() -> Inline? {
		return array.last
	}
}
