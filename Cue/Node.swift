//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

@objc public class Node: NSObject {
	
	public weak var parent: Node?
	public weak var next: Node?
	public weak var previous: Node?
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

public class Block: Node {
	public var lineNumber = 0
}
public class Inline: Node { }

public class Document: Block {}

public class Heading: Block {}
public class Keyword: Inline {
	public enum KeywordType {
		case act
		case chapter
		case scene
	}
	var type: KeywordType = .act
}
public class Identifier: Inline {}

public class Description: Block {}
public class CueBlock: Block {}
public class LyricBlock: Block {}
public class Lyric: Block {}
public class CommentBlock: Block {}

public class Cue: Block {
	func addDefaultChildren(for results: [SearchResult]) {
		let name = Name(startIndex: results[0].startIndex, endIndex: results[0].endIndex)
		addChild(name)
		
		let del2 = Delimiter(startIndex: results[1].startIndex, endIndex: results[1].endIndex)
		del2.type = .colon
		addChild(del2)
		
		let te = RawText(startIndex: del2.endIndex, endIndex: endIndex)
		addChild(te)
	}
}
public class RegularCue: Cue {
	override func addDefaultChildren(for results: [SearchResult]) {
		addDefaultChildren(offset: results[0].startIndex)
		
		super.addDefaultChildren(for: results)
	}
}
public class DualCue: Cue {
	override func addDefaultChildren(for results: [SearchResult]) {
		addDefaultChildren(offset: results[0].startIndex)
		
		let del = Delimiter(startIndex: results[0].startIndex, endIndex: results[0].endIndex)
		del.type = .dual
		addChild(del)
		
		super.addDefaultChildren(for: Array(results.dropFirst()))
	}
}

public class RawText: Inline {}
public class CommentText: Inline {}
public class Delimiter: Inline {
	public enum DelimiterType {
		case whitespace
		case dual
		case lyric
		case emph
		case colon
		case hyphen
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
}

// Debug Functions
extension Node {
	
	func debugString() -> String {
		var s = "(\(NSStringFromClass(type(of: self))) \(startIndex) \(endIndex))"
		if !isLeaf {
			s += "{" + children.map { $0.debugString() }.joined(separator: ",") + "}"
		}
		return s
	}
	
}
