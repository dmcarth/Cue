//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/26/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

class InlineMarker {
	
	var previous: InlineMarker?
	
	enum MarkerType {
		case asterisk
		case openBracket
		case closeBracket
		case comment
	}
	
	var type: MarkerType
	
	var range: Range<Int>

	init(type: MarkerType, range: Range<Int>) {
		self.type = type
		self.range = range
	}
	
}
