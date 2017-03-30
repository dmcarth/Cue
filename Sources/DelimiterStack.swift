//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/26/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

struct InlineMarker{
	
	var type: MarkerType
	
	var range: Range<Int>
	
}

enum MarkerType {
	case asterisk
	case openBracket
	case closeBracket
	case comment
}

struct DelimiterStack {
	
	fileprivate var buffer = [InlineMarker]()
	
	fileprivate var lastOpeningBracketIndex: Int? = nil
	
	mutating func popToOpeningBracket() -> InlineMarker? {
		guard let index = lastOpeningBracketIndex else {
			return nil
		}
		
		let marker = buffer[index]
		
		buffer.removeLast(buffer.endIndex - 1 - index)
		
		return marker
	}
	
	mutating func popToOpeningAsterisk() -> InlineMarker? {
		guard let last = buffer.last else { return nil }
		
		guard last.type == .asterisk else { return nil }
		
		lastOpeningBracketIndex = nil
		
		return buffer.removeLast()
	}
	
	mutating func push(_ marker: InlineMarker) {
		if marker.type == .openBracket {
			lastOpeningBracketIndex = buffer.endIndex
		}
		
		buffer.append(marker)
	}
	
}

extension DelimiterStack: Collection {
	
	var startIndex: Int {
		return 0
	}
	
	var endIndex: Int {
		return buffer.endIndex
	}
	
	subscript(index: Int) -> InlineMarker {
		return buffer[index]
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
}
