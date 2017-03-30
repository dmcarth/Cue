//
//  Queue.swift
//  Cue
//
//  Created by Dylan McArthur on 2/3/17.
//
//

struct Queue<T> {
	
	fileprivate var buffer = [T]()
	
	fileprivate var head = 0
	
	mutating func enqueue(_ element: T) {
		buffer.append(element)
	}
	
	@discardableResult mutating func dequeue() -> T? {
		guard !isEmpty else { return nil }
		
		let element = buffer[head]
		
		head += 1
		
		return element
	}
	
}

extension Queue: Collection {
	
	var startIndex: Int {
		return 0
	}
	
	var endIndex: Int {
		return buffer.endIndex - head
	}
	
	subscript(index: Int) -> T {
		return buffer[head + index]
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
}
