//
//  SearchResult.swift
//  Cue
//
//  Created by Dylan McArthur on 10/21/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public struct SearchResult<Index: Comparable> {
	
	public var range: Range<Index>
	
	public var keywordType: HeaderType?
	
	public init(range: Range<Index>, keywordType: HeaderType?=nil) {
		self.range = range
		self.keywordType = keywordType
	}
	
}

extension SearchResult: Equatable {
	
	public static func ==(lhs: SearchResult, rhs: SearchResult) -> Bool {
		return lhs.range == rhs.range && lhs.keywordType == rhs.keywordType
	}
	
}
