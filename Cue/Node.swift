//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public enum CueNodeType {
	// Block
	case document
	case scene
	case comment
	case cue(String)
	case description
	// Inline
	case italic
}

public class CueNode: CustomStringConvertible {
	
	public var type: CueNodeType
	public var location: Int
	public var length: Int
	public var children = [CueNode]()
	public var markingRanges = [(Int, Int)]()
	
	public init(type: CueNodeType, location: Int, length: Int) {
		self.type = type
		self.location = location
		self.length = length
	}
	
	func addChild(node: CueNode) {
		children.append(node)
	}
	
	func addChildren(nodes: [CueNode]) {
		children.append(contentsOf: nodes)
	}
	
	func addMarkingRange(range: (Int, Int)) {
		markingRanges.append(range)
	}
	
	// MARK: Iterative Functions (FOR EXISTING TREES ONLY)
	
	// Binary search on first level of children
	public func search(index: Int) -> Int? {
		var lower = 0
		var upper = children.count
		
		while lower < upper {
			let midIndex = lower + (upper - lower) / 2
			let midChild = children[midIndex]
			
			if index >= midChild.location && index <= midChild.location+midChild.length {
				return midIndex
			} else if index > midChild.location+midChild.length {
				lower = midIndex + 1
			} else {
				upper = midIndex
			}
		}
		
		return nil
	}
	
	public var description: String {
		var desc = "\(type)(\(location),\(length))"
		if !children.isEmpty {
			desc += "{ " + children.map { $0.description }.joined(separator: ", ") + " } "
		}
		return desc
	}
	
}
