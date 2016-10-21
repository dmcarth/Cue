//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Node {
	
	public var parent: Node?
	public var children = [Node]()
	
	public var location = 0
	public var length = 0
	
	public var startIndex = 0
	public var endIndex = 0
	
	public init() {}
	
	public func addChild(_ child: Node) {
		//	TODO: if this node can't accept this child, back up until we find a parent that can
		child.parent = self
		self.children.append(child)
	}
	
}

public class Block: Node { }
public class Inline: Node { }

public class Document: Block {}

public class Heading: Block {}
public class ActHeading: Heading {}
public class ChapterHeading: Heading {}
public class SceneHeading: Heading {}

public class Description: Block {}
public class CueBlock: Block {}
public class Lyric: Block {}	// Even though lyrics are parsed as inlines, we consider lyrics a block element
public class Comment: Block {}

public class Cue: Block {}
public class RegularCue: Cue {}
public class DualCue: Cue {}

public class Text: Inline {}
public class Delimiter: Inline {}
public class Name: Inline {}
public class Emphasis: Inline {}
public class Reference: Inline {}

extension Node {
	
	// Binary search for most specific child
	public func search(index: Int) -> Node? {
		var lower = 0
		var upper = children.count
		
		while lower < upper {
			let midIndex = lower + (upper - lower) / 2
			let midChild = children[midIndex]
			
			if index >= midChild.location && index <= midChild.location+midChild.length {
				// TODO: optionally limit depth of search
				if let found = midChild.search(index: index) {
					return found
				}
				
				return midChild
			} else if index > midChild.location+midChild.length {
				lower = midIndex + 1
			} else {
				upper = midIndex
			}
		}
		
		return nil
	}
	
	// Convenience method for enumerating nodes
	public func enumerate(_ handler: (Node)->Void) {
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

extension Cue {
	
	// Convenience method for adding a name and delimiter as children
	public func addName(ofLength len: Int, atIndex: Int) {
		let name = Name()
		name.location = atIndex
		name.length = len
		self.addChild(name)
		let delim = Delimiter()
		delim.location = atIndex+len
		delim.length = 1
		self.addChild(delim)
	}
	
}
