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
	
	public var children = [Node]()
	
	public let sourcePosition: Int
	
	public internal(set) var sourceEnd: Int
	
	public init(range: Range<Int>) {
		self.sourcePosition = range.lowerBound
		self.sourceEnd = range.upperBound
	}
	
	func addChild(_ child: Node) {
		child.parent = self
		children.append(child)
	}
	
	func removeLastChild() {
		guard !children.isEmpty else { return }
		
		_ = children.removeLast()
	}
	
}

// MARK: - Range
extension Node {
	
	public var isEmpty: Bool {
		return range.isEmpty
	}
	
	public var range: Range<Int> {
		return sourcePosition..<sourceEnd
	}
	
	public var rangeIncludingMarkers: Range<Int> {
		var lowerBound = sourcePosition
		if let left = (self as? LeftDelimited)?.leftDelimiter {
			lowerBound = left.sourcePosition
		}
		
		var upperBound = sourceEnd
		if let right = (self as? RightDelimited)?.rightDelimiter {
			upperBound = right.sourceEnd
		}
		
		return lowerBound..<upperBound
	}
	
	func extendLengthToInclude(node: Node) {
		sourceEnd = node.range.upperBound
	}
	
	public var nsRange: NSRange {
		return NSMakeRange(sourcePosition, sourceEnd - sourcePosition)
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
