//
//  Enumerable.swift
//  Cue
//
//  Created by Dylan McArthur on 1/31/17.
//
//

extension Node {
	
	public func enumerate(_ handler: (Node)->Void) {
		let isLeaf = children.isEmpty
		
		handler(self)
		
		guard !isLeaf else { return }
		
		for child in children {
			child.enumerate(handler)
		}
	}
	
}
