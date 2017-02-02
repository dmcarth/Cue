//
//  SearchResult.swift
//  Cue
//
//  Created by Dylan McArthur on 10/21/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public struct SearchResult {
	
	public typealias Index = Int
	
	public var range: Range<Index>
	
	public var keywordType: HeaderBlock.HeaderType?
	
	public init(range: Range<Index>, keywordType: HeaderBlock.HeaderType?=nil) {
		self.range = range
		self.keywordType = keywordType
	}
	
}

extension SearchResult: Equatable {
	
	public static func ==(lhs: SearchResult, rhs: SearchResult) -> Bool {
		return lhs.range == rhs.range && lhs.keywordType == rhs.keywordType
	}
	
}
