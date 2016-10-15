//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public class CueParser {
	
	public func ast(fromTokens tokens: [CueLexerToken]) -> CueNode {
		let tree = CueNode(type: .document, location: 0, length: 0)
		
		for t in tokens {
			let node = CueNode(type: t.type, location: t.location, length: t.length)
			
			// Process text
			var i = 0
			let text = t.text
			while i < text.count {
				// run italics
				if let range = parseItalics(fromBytes: text, startingAtIndex: i) {
					let italicChild = CueNode(type: .italic, location: t.location+t.offset+range.0, length: range.1)
					let range1 = (range.0, 1)
					italicChild.addMarkingRange(range: range1)
					let range2 = (range.1-1, 1)
					italicChild.addMarkingRange(range: range2)
					
					node.addChild(node: italicChild)
					
					i += range.1
					continue
				}
				
				i += 1
			}
			
			if case let CueNodeType.cue(name) = node.type {
				let length = name.utf16.count + 1
				let range1 = (node.location, length)
				node.addMarkingRange(range: range1)
			}
			
			tree.addChild(node: node)
			tree.length = max(tree.length, node.length+node.location)
		}
		
		return tree
	}
	
	private func parseItalics(fromBytes col: Array<UInt16>, startingAtIndex i: Int) -> (Int, Int)?  {
		guard col.count > 2 && col[i] == 0x002a else {
			return nil
		}
		var ind = 1
		while i+ind < col.count {
			let c = col[i+ind]
			if c == 0x002a {
				return (i, ind+1)
			}
			ind += 1
		}
		return nil
	}
	
}
