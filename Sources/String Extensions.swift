//
//  String Extensions.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

extension String.UTF16Index {
	mutating func advance(in source: String.UTF16View) {
		self = source.index(after: self)
	}
	
	mutating func advance(in source: String.UTF16View, by distance: Int) {
		return self = source.index(self, offsetBy: distance)
	}
	
	func advanced(in source: String.UTF16View) -> String.UTF16Index {
		return source.index(after: self)
	}
	
	func advanced(in source: String.UTF16View, by distance: Int) -> String.UTF16Index {
		return source.index(self, offsetBy: distance)
	}
}
