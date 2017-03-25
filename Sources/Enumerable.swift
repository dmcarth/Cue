//
//  Enumerable.swift
//  Cue
//
//  Created by Dylan McArthur on 1/31/17.
//
//

public enum WalkerEvent {
	case enter
	case exit
}

extension Node {
	
	public func enumerate(_ handler: (Node)->Void) {
		let isLeaf = children.isEmpty
		
		handler(self)
		
		guard !isLeaf else { return }
		
		for child in children {
			child.enumerate(handler)
		}
	}
	
	public func walk(_ handler: (WalkerEvent, Node, inout Bool)->Void) {
		var shouldBreak = false
		handler(.enter, self, &shouldBreak)
		
		if !shouldBreak {
			var child = children.first
			while child != nil {
				child?.walk(handler)
				
				child = child?.next
			}
		}
		
		handler(.exit, self, &shouldBreak)
	}
	
}
