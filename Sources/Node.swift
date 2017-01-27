//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Node {
	
	public weak var parent: Node?
	public weak var next: Node?
	public weak var previous: Node?
	public var children = [Node]()
	
	public var startIndex = 0
	public var endIndex = 0
	
	public var isLeaf: Bool {
		return children.isEmpty
	}
	
	public init() {}
	
	public init(startIndex: Int, endIndex: Int) {
		self.startIndex = startIndex
		self.endIndex = endIndex
	}
	
	public convenience init(_ result: SearchResult) {
		self.init(startIndex: result.startIndex, endIndex: result.endIndex)
	}
	
	internal func addChild(_ child: Node) {
		child.parent = self
		if let last = children.last {
			child.previous = last
			last.next = child
		}
		self.children.append(child)
	}
	
	internal func removeLastChild() {
		guard !children.isEmpty else { return }
		
		children.removeLast()
		if let last = children.last {
			last.next = nil
		}
	}
	
}

// MARK: - Search and Query
extension Node {
	
	/// Binary search for the node containing a given index.
	///
	/// - Parameters:
	///   - index: A utf16 byte index.
	///   - options: A NodeSearchOptions object allowing fine grain control of search.
	///      - deepSearch: A Bool causing search to recursively find the most specific match. Default value is true.
	///      - predicate: A closure causing search to return early if a matching node is found.
	/// - Returns: Node containing a given index, nil if out of bounds
	public func search(index: Int, options: NodeSearchOptions) -> Node? {
		guard index >= self.startIndex && index < endIndex else {
			return nil
		}
		
		var lowerBound = 0
		var upperBound = children.count
		
		while lowerBound < upperBound {
			let midIndex = lowerBound + (upperBound - lowerBound) / 2
			let midChild = children[midIndex]
			
			if index < midChild.startIndex {
				upperBound = midIndex
			} else if index >= midChild.endIndex {
				lowerBound = midIndex + 1
			} else {
				// We've found a match!
				
				// If a custom search predicate has been provided, that takes precedence over everything else
				if let predicate = options.predicate{
					if predicate(midChild) {
						return midChild
					}
				}
				
				if options.deepSearchEnabled {
					if let deepMatch = midChild.search(index: index, options: options) {
						return deepMatch
					}
				}
				
				// Checking for nil ensures that a search with a predicate will only return if the matching node passes the given predicate
				if options.predicate == nil {
					return midChild
				}
				
				// Search matched the index but not the options, break the loop
				break
			}
		}
		
		return nil
	}
	
	public func enumerate(_ handler: (_ node: Node)->Void) {
		let isLeaf = children.isEmpty
		handler(self)
		
		// This enables us to manipulate the node within the handler without creating an infinite loop
		guard !isLeaf else {
			return
		}
		
		for c in children {
			c.enumerate(handler)
		}
	}
	
	public func childNodes(from startingIndex: Int, to endingIndex: Int) -> [Node] {
		var nodes = [Node]()
		
		let opts = NodeSearchOptions(deepSearch: false, searchPredicate: nil)
		var searchIndex = startingIndex
		let safeEndIndex = min(endingIndex, endIndex)
		
		if var node = search(index: searchIndex, options: opts) {
			nodes.append(node)
			searchIndex = node.endIndex
			
			while let next = node.next, searchIndex < safeEndIndex {
				nodes.append(next)
				searchIndex = next.endIndex
				node = next
			}
		}
		
		return nodes
	}
	
}

// MARK: - Debug Functions
extension Node: Equatable {
	
	func debugString() -> String {
		var s = "(\(type(of: self))) \(startIndex) \(endIndex))"
		if !isLeaf {
			s += "{" + children.map { $0.debugString() }.joined(separator: ",") + "}"
		}
		return s
	}
	
	public static func ==(lhs: Node, rhs: Node) -> Bool {
		return lhs.debugString() == rhs.debugString()
	}
	
}
