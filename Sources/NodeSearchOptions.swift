//
//  NodeSearchOptions.swift
//  Cue
//
//  Created by Dylan McArthur on 10/29/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class NodeSearchOptions {
	
	/// Enables search to traverse nodes deeper than level-1
	public var deepSearchEnabled: Bool
	
	/// Causes search to return on the first node matching this predicate. If no matching node is found, search will return nil.
	public var predicate: ((Node)->Bool)?
	
	public init(deepSearch: Bool = true, searchPredicate: ((Node)->Bool)?) {
		self.deepSearchEnabled = deepSearch
		self.predicate = searchPredicate
	}
}
