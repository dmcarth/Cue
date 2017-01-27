//
//  HybridUTF16Index.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

public struct HybridUTF16Index {
	
	fileprivate let source: String.UTF16View
	
	public var index: String.UTF16Index
	
	public var offset: Int
	
	public init(source: String.UTF16View, index: String.UTF16Index, offset: Int) {
		self.source = source
		self.index = index
		self.offset = offset
	}
	
}

extension HybridUTF16Index {
	
	public func backtracked() -> HybridUTF16Index {
		let newIndex = source.index(before: index)
		let newOffset = offset - 1
		
		return HybridUTF16Index(source: source, index: newIndex, offset: newOffset)
	}
	
	public mutating func advance() {
		index = source.index(after: index)
		offset += 1
	}
	
	public func advanced() -> HybridUTF16Index {
		let newIndex = source.index(after: index)
		let newOffset = offset + 1
		
		return HybridUTF16Index(source: source, index: newIndex, offset: newOffset)
	}
	
	public func advanced(by distance: Int) -> HybridUTF16Index {
		let newIndex = source.index(index, offsetBy: distance)
		let newOffset = offset + distance
		
		return HybridUTF16Index(source: source, index: newIndex, offset: newOffset)
	}
	
}

extension HybridUTF16Index: Comparable {
	
	public static func < (lhs: HybridUTF16Index, rhs: HybridUTF16Index) -> Bool {
		return lhs.index < rhs.index
	}
	
	public static func == (lhs: HybridUTF16Index, rhs: HybridUTF16Index) -> Bool {
		return lhs.index == rhs.index
	}
	
}
