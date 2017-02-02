//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class AbstractNode: Enumerable, Searchable {
	
	public weak var parent: AbstractNode?
	
	public weak var next: AbstractNode?
	
	public var children: [AbstractNode] {
		return []
	}
	
	public var range: Range<Int>
	
	public var lineNumber = 0
	
	public init(range: Range<Int>) {
		self.range = range
	}
	
	public func compare(to index: Int) -> SearchComparison {
		if index < range.lowerBound {
			return .greaterThan
		} else if index >= range.upperBound {
			return .lessThan
		} else {
			return .contains
		}
	}
	
}

extension AbstractNode {
	
	func childNodes(from startIndex: Int, to endIndex: Int) -> [AbstractNode] {
		var nodes = [AbstractNode]()
		
		let opts = SearchOptions(deepSearch: false)
		
		if var node = searchChildren(for: startIndex, options: opts) {
			nodes.append(node)
			
			var searchIndex = node.range.upperBound
			let safeEndIndex = min(range.upperBound, endIndex)
			
			while let next = node.next, searchIndex < safeEndIndex {
				nodes.append(next)
				searchIndex = node.range.upperBound
				node = next
			}
		}
		
		return nodes
	}
	
}

// MARK: - Debug Functions
extension AbstractNode: Equatable {
	
	var debugString: String {
		var s = "(\(type(of: self))) \(range))"
		if !children.isEmpty {
			s += "{" + children.map { $0.debugString }.joined(separator: ",") + "}"
		}
		return s
	}
	
	public static func ==(lhs: AbstractNode, rhs: AbstractNode) -> Bool {
		return lhs.debugString == rhs.debugString
	}
	
}
