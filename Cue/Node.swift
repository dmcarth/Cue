//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

@objc public class Node: NSObject {
	
	public var parent: Node?
	public var next: Node?
	public var previous: Node?
	public var children = [Node]()
	
	public var startIndex = 0
	public var endIndex = 0
	
	public var isLeaf: Bool {
		return children.isEmpty
	}
	
	public override init() {
		super.init()
	}
	
	public init(startIndex: Int, endIndex: Int) {
		self.startIndex = startIndex
		self.endIndex = endIndex
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

public class Block: Node {
	public var lineNumber = 0
}
public class Inline: Node { }

public class Document: Block {}

public class Heading: Block {}
public class ActHeading: Heading {}
public class ChapterHeading: Heading {}
public class SceneHeading: Heading {}

public class Description: Block {}
public class CueBlock: Block {}
public class Lyric: Block {}
public class CommentBlock: Block {}

public class Cue: Block {}
public class RegularCue: Cue {}
public class DualCue: Cue {}

public class RawText: Inline {}
public class CommentText: Inline {}
public class Delimiter: Inline {
	public enum DelimiterType {
		case whitespace
		case dual
		case lyric
		case emph
		case colon
		case openBracket
		case closeBracket
	}
	public var type: DelimiterType = .whitespace
}
public class Name: Inline {}
public class Emphasis: Inline {}
public class Reference: Inline {}

// Public Interface
extension Node {
	
	/// Binary search for node containing given index.
	///
	/// - Parameters:
	///   - index: A utf16 byte index.
	///   - options: A NodeSearchOptions object allowing fine grain control of search.
	///      - deepSearch: A Bool causing search to search children for the most specific match. Default value is true.
	///      - predicate: A closure causing search to return early if a matching node is found. Default expression is { _ in return false }
	/// - Returns: Node containing given index, nil if out of bounds
	public func search(index: Int, options: NodeSearchOptions) -> Node? {
		if index >= self.startIndex && index <= self.endIndex {
			if options.predicate(self) {
				return self
			}
			
			if options.deepSearchEnabled {
				if !isLeaf {
					var lowerBound = 0
					var upperBound = children.count
					
					while lowerBound < upperBound {
						let midIndex = lowerBound + (upperBound - lowerBound) / 2
						let midChild = children[midIndex]
						
						if index < midChild.startIndex {
							upperBound = midIndex
						} else if index > midChild.endIndex {
							lowerBound = midIndex + 1
						} else {
							return midChild.search(index: index, options: options)
						}
					}
				}
			}
			
			return self
		}
		
		return nil
	}
	
	// Convenience method for enumerating nodes
	public func enumerate(_ handler: (_ node: Node)->Void) {
		let isLeaf = children.isEmpty
		handler(self)
		
		// This enables us to manipulate the node within the handler without also creating an infinite loop
		guard !isLeaf else {
			return
		}
		
		for c in children {
			c.enumerate(handler)
		}
	}
}

// Debug Functions
extension Node {
	
	func debugString() -> String {
		return "\(NSStringFromClass(type(of: self))) \(startIndex) \(endIndex)"
	}
	
//	public static func ==(_ lhs: Node, _ rhs: Node) -> Bool {
//		return lhs.debugString() == rhs.debugString()
//	}
	
}
