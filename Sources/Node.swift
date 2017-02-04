//
//  Node.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public final class Node<Index: Comparable> {
	
	public weak var next: Node<Index>?
	
	public var children: ContiguousArray<Node<Index>> = []
	
	public var range: Range<Index>
	
	public var type: NodeType
	
	public init(type: NodeType, range: Range<Index>) {
		self.type = type
		self.range = range
	}
	
	func addChild(_ child: Node<Index>) {
		if let last = children.last {
			last.next = child
		}
		
		children.append(child)
	}
	
	func replaceLastChild(with newChild: Node<Index>) {
		if !children.isEmpty {
			children.removeLast()
		}
		
		addChild(newChild)
	}
	
}

public enum NodeType {
	case document
	case headerBlock(HeaderType)
	case descriptionBlock
	case cueContainer
	case cueBlock(Bool) //isDual
	case name
	case lyricContainer
	case lyricBlock
	case facsimileContainer
	case facsimileBlock
	case endBlock
	case textStream
	case literal
	case comment
	case emphasis
	case reference
	case delimiter
}

public enum HeaderType {
	case act
	case chapter
	case scene
	case page
}

// MARK: - Debug Functions
extension Node: Equatable {
	
	public var debugString: String {
		var s = "(Node<\(type)>) \(range))"
		if !children.isEmpty {
			s += "{ " + children.map { $0.debugString }.joined(separator: ", ") + "}"
		}
		return s
	}
	
	public static func ==(lhs: Node, rhs: Node) -> Bool {
		return lhs.debugString == rhs.debugString
	}
	
}
