//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Node {
	
	public var text = [UInt8]()
	public var location = 0
	public var length = 0
	public var markingRanges = [(Int,Int)]()
	
	public var parent: Node?
	public var children = [Node]()
	
	func addChild(_ child: Node) {
		//	TODO: if parent can't accept this child, back up until we find a parent that can
		var par = self
		
		child.parent = par
		par.children.append(child)
	}
	
	// Binary search on first level of children
	public func search(index: Int) -> Node? {
		var lower = 0
		var upper = children.count
		
		while lower < upper {
			let midIndex = lower + (upper - lower) / 2
			let midChild = children[midIndex]
			
			if index >= midChild.location && index <= midChild.location+midChild.length {
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
}

public class Block: Node { }
public class Inline: Node { }

protocol Nameable {
	var name: [UInt8] { get set }
}

public class Document: Block {}

public class Heading: Block, Nameable {
	public var name: [UInt8] = []
}
public class ActHeading: Heading {}
public class ChapterHeading: Heading {}
public class SceneHeading: Heading {}

public class Description: Block {}
public class CueBlock: Block {}
public class Lyric: Block {}	// Even though lyrics are parsed as inlines, we consider lyrics a block element
public class Comment: Block {}

public class Cue: Block, Nameable {
	public var name: [UInt8] = []
}
public class RegularCue: Cue {}
public class DualCue: Cue {}

public class Text: Inline {}
public class Emphasis: Inline {}
public class Reference: Inline {}
