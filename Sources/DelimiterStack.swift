//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/26/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

struct InlineMarker<Index: Comparable> {
	
	var type: MarkerType
	
	var range: Range<Index>
	
}

enum MarkerType {
	case asterisk
	case openBracket
	case closeBracket
	case comment
}

struct DelimiterStack<I: Comparable> {
	
	fileprivate var buffer = [InlineMarker<I>]()
	
	fileprivate var lastOpeningBracketIndex: Int? = nil
	
	mutating func popToOpeningBracket() -> InlineMarker<I>? {
		guard let index = lastOpeningBracketIndex else {
			return nil
		}
		
		let marker = buffer[index]
		
		buffer.removeLast(buffer.endIndex - 1 - index)
		
		return marker
	}
	
	mutating func popToOpeningAsterisk() -> InlineMarker<I>? {
		guard let last = buffer.last else { return nil }
		
		guard last.type == .asterisk else { return nil }
		
		lastOpeningBracketIndex = nil
		
		return buffer.removeLast()
	}
	
	mutating func push(_ marker: InlineMarker<I>) {
		if marker.type == .openBracket {
			lastOpeningBracketIndex = buffer.endIndex
		}
		
		buffer.append(marker)
	}
	
}

extension DelimiterStack: Collection {
	
	typealias Index = Int
	
	var startIndex: Int {
		return 0
	}
	
	var endIndex: Int {
		return buffer.endIndex
	}
	
	subscript(index: Int) -> InlineMarker<I> {
		return buffer[index]
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
}
