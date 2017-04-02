//
//  Scanner.swift
//  Cue
//
//  Created by Dylan McArthur on 4/1/17.
//
//

extension UnsafeBufferPointer where Element == UInt16 {
	
	func scanForLineEnding(at index: Int) -> Bool {
		let c = self[index]
		
		return c == UTF16.linefeed || c == UTF16.carriage
	}
	
	func scanForWhitespace(at index: Int) -> Bool {
		let c = self[index]
		
		return c == UTF16.space || c == UTF16.tab || scanForLineEnding(at: index)
	}
	
	func scanForFirstNonspace(at index: Int, limit: Int) -> Int {
		var j = index
		
		while j < limit {
			if scanForWhitespace(at: j) {
				j += 1
			} else {
				break
			}
		}
		
		return j
	}
	
	func scanForHyphen(at index: Int, limit: Int) -> Int {
		var j = index
		
		while j < limit {
			if self[j] == UTF16.hyphen {
				break
			} else {
				j += 1
			}
		}
		
		return j
	}
	
	func scanBackwardForFirstNonspace(at index: Int, limit: Int) -> Int {
		var j = index
		
		while j > limit {
			let backtrack = j - 1
			
			if scanForWhitespace(at: backtrack) {
				j = backtrack
			} else {
				break
			}
		}
		
		return j
	}
	
}
