//
//  NodeSearchOptions.swift
//  Cue
//
//  Created by Dylan McArthur on 10/29/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public struct NodeSearchOptions {
	// Enables search to traverse nodes deeper than level-1
	public var deepSearchEnabled: Bool
	// Search continues until the predicate returns true
	public var predicate: (Node)->Bool
	
	public init(deepSearch: Bool = true, searchPredicate: ((Node)->Bool)?) {
		self.deepSearchEnabled = deepSearch
		if let p = searchPredicate {
			self.predicate = p
		} else {
			self.predicate = { n in return false }
		}
	}
}
