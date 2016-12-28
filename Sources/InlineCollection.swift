//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/21/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

struct InlineCollection: Collection {
	private var array = [Inline]()
	
	var startIndex: Int {
		return 0
	}
	
	var endIndex: Int {
		return array.endIndex
	}
	
	subscript(_ pos: Int) -> Inline {
		return array[pos]
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
	// Ensure all inlines are of equal depth, the purpose of this structure is to represent a tree-like structure as a 2D array.
	mutating func push(_ inline: Inline) {
		guard !array.isEmpty else {
			array.append(inline)
			return
		}
		
		var queue = [inline]
		
		var idx = 0
		while idx < array.endIndex {
			let currInline = array[idx]
			guard let newInline = queue.first else { return }
			
			if exclusion(currInline, newInline) {
				if newInline.endIndex < currInline.startIndex {
					array.insert(newInline, at: idx)
					queue.removeFirst()
				}
			} else {
				if newInline.startIndex > currInline.startIndex {
					fatalError("\(self) found invalid overlap when comparing \(newInline) and \(currInline)")
				} else {
					let oldEndIndex = newInline.endIndex
					newInline.endIndex = currInline.startIndex
					
					// Create remainder and add to queue
					var remainder: Inline
					if let _ = newInline as? RawText {
						remainder = RawText()
					} else if let _ = newInline as? Emphasis {
						remainder = Emphasis()
					} else if let _ = newInline as? Reference {
						remainder = Reference()
					} else {
						fatalError("\(self) found an impossible \(newInline) during self sorting")
					}
					remainder.startIndex = currInline.endIndex
					remainder.endIndex = oldEndIndex
					queue.append(remainder)
					
					if newInline.endIndex-newInline.startIndex > 0 {
						array.insert(newInline, at: idx)
					}
					
					queue.removeFirst()
				}
			}
			
			idx += 1
		}
		
		array.append(contentsOf: queue)
	}
	
	private func exclusion(_ lhs: Node, _ rhs: Node) -> Bool {
		return lhs.endIndex <= rhs.startIndex ||
				lhs.startIndex >= rhs.endIndex
	}
}

