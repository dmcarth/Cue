//
//  Enumerable.swift
//  Cue
//
//  Created by Dylan McArthur on 1/31/17.
//
//

public protocol Enumerable {
	
	var children: [AbstractNode] { get }
	
}

extension Enumerable {
	
	public func enumerate(_ handler: (Enumerable)->Void) {
		let isLeaf = children.isEmpty
		
		handler(self)
		
		guard !isLeaf else { return }
		
		for child in children {
			child.enumerate(handler)
		}
	}
	
}
