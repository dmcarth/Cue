//
//  SearchResult.swift
//  Cue
//
//  Created by Dylan McArthur on 10/21/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public struct SearchResult: Equatable {
	public var startIndex: String.UTF16Index
	public var endIndex: String.UTF16Index
	public var keywordType: Keyword.KeywordType?
	
	public init(startIndex: String.UTF16Index, endIndex: String.UTF16Index, keywordType: Keyword.KeywordType? = nil) {
		self.startIndex = startIndex
		self.endIndex = endIndex
		self.keywordType = keywordType
	}
	
	public static func ==(lhs: SearchResult, rhs: SearchResult) -> Bool {
		return lhs.startIndex == rhs.startIndex && lhs.endIndex == rhs.endIndex && lhs.keywordType == rhs.keywordType
	}
}
