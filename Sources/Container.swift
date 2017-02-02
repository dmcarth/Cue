//
//  Container.swift
//  Cue
//
//  Created by Dylan McArthur on 1/31/17.
//
//

public class AbstractContainer: AbstractNode {
	
	fileprivate(set) var contents = [AbstractNode]()
	
	override public var children: [AbstractNode] {
		return contents
	}
	
}

extension AbstractContainer {
	
	func addChild(_ child: AbstractNode) {
		if let last = contents.last {
			last.next = child
		}
		
		contents.append(child)
		child.parent = self
	}
	
}
