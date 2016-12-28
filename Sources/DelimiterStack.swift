//
//  DelimiterStack.swift
//  Cue
//
//  Created by Dylan McArthur on 10/26/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

struct DelimiterStack {
	private var array = [Delimiter]()
	
	var isEmpty: Bool {
		return array.isEmpty
	}
	
	var count: Int {
		return array.count
	}
	
	mutating func push(_ del: Delimiter) {
		array.append(del)
	}
	
	func peek() -> Delimiter? {
		return array.last
	}
	
	mutating func pop() -> Delimiter? {
		return array.popLast()
	}
}
