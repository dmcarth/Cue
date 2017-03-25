//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import Foundation

public class Node {
	
	public weak var parent: Node?
	
	public weak var next: Node?
	
	public var children = [Node]()
	
	public let offset: Int
	
	public internal(set) var length: Int
	
	public init(range: Range<Int>) {
		self.offset = range.lowerBound
		self.length = range.upperBound - range.lowerBound
	}
	
	func addChild(_ child: Node) {
		if let last = children.last {
			last.next = child
		}
		
		child.parent = self
		children.append(child)
	}
	
}

// MARK: - Range
extension Node {
	
	public var isEmpty: Bool {
		return range.isEmpty
	}
	
	public var range: Range<Int> {
		return offset..<offset+length
	}
	
	public var rangeIncludingMarkers: Range<Int> {
		var lowerBound = offset
		if let left = (self as? LeftDelimited)?.leftDelimiter {
			lowerBound = left.offset
		}
		
		var upperBound = offset + length
		if let right = (self as? RightDelimited)?.rightDelimiter {
			upperBound = right.offset + right.length
		}
		
		return lowerBound..<upperBound
	}
	
	func extendLengthToInclude(node: Node) {
		length = node.range.upperBound - offset
	}
	
	public var nsRange: NSRange {
		return NSMakeRange(offset, length)
	}
	
	public var nsRangeIncludingMarkers: NSRange {
		let expandedRange = rangeIncludingMarkers
		
		return NSMakeRange(expandedRange.lowerBound, expandedRange.upperBound - expandedRange.lowerBound)
	}
	
}

// MARK: - Debug Functions
extension Node: Equatable {
	
	public var debugString: String {
		var s = "(\(type(of: self)) \(range))"
		if !children.isEmpty {
			s += "{ " + children.map { $0.debugString }.joined(separator: ", ") + "}"
		}
		return s
	}
	
	public static func ==(lhs: Node, rhs: Node) -> Bool {
		return lhs.debugString == rhs.debugString
	}
	
}
