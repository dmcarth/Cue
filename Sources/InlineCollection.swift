//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/21/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

struct InlineCollection: Collection {
	private var array = [AbstractNode]()
	
	var startIndex: Int {
		return 0
	}
	
	var endIndex: Int {
		return array.endIndex
	}
	
	subscript(_ pos: Int) -> AbstractNode {
		return array[pos]
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
	// Ensure all inlines are of equal depth, the purpose of this structure is to represent a tree-like structure more like a 2D array.
	mutating func push(_ inline: AbstractNode) {
		guard !array.isEmpty else {
			array.append(inline)
			return
		}
		
		var queue = [inline]
		
		var idx = 0
		while idx < array.endIndex {
			let currInline = array[idx]
			guard let newInline = queue.first else { return }
			
			if !currInline.range.overlaps(newInline.range) {
				if newInline.range.upperBound < currInline.range.lowerBound {
					array.insert(newInline, at: idx)
					queue.removeFirst()
				}
			} else {
				if newInline.range.lowerBound > currInline.range.lowerBound {
					fatalError("\(self) found invalid overlap when comparing \(newInline) and \(currInline). Unprepared to push inlines the do not extend beyond both sides of the current inline.")
				} else {
					// Clip newInline by the beginning of the current inline
					let oldEndIndexForNewInline = newInline.range.upperBound
					newInline.range = newInline.range.lowerBound..<currInline.range.lowerBound
					
					// Create remainder and add to queue
					var remainder: AbstractNode
					let remainderRange: Range = currInline.range.upperBound..<oldEndIndexForNewInline
					if let _ = newInline as? Literal {
						remainder = Literal(range: currInline.range.upperBound..<oldEndIndexForNewInline)
					} else if let newEm = newInline as? Emphasis {
						// adjust delimiters
						remainder = Emphasis(start: remainderRange.lowerBound..<remainderRange.lowerBound, stop: newEm.delimiters.1.range)
						newEm.delimiters.0.range = currInline.range.lowerBound..<currInline.range.lowerBound
					} else if let newRef = newInline as? Reference {
						// adjust delimiters
						remainder = Reference(start: remainderRange.lowerBound..<remainderRange.lowerBound, stop: newRef.delimiters.1.range)
						newRef.delimiters.0.range = currInline.range.lowerBound..<currInline.range.lowerBound
					} else {
						fatalError("\(self) found an impossible \(newInline) during self sorting")
					}
					
					queue.append(remainder)
					
					if newInline.range.isEmpty {
						array.insert(newInline, at: idx)
					}
					
					queue.removeFirst()
				}
			}
			
			idx += 1
		}
		
		array.append(contentsOf: queue)
	}
}

