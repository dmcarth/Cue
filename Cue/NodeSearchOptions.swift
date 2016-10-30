//
//  NodeSearchOptions.swift
//  Cue
//
//  Created by Dylan McArthur on 10/29/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

@objc public class NodeSearchOptions: NSObject {
	
	/// Enables search to traverse nodes deeper than level-1
	public var deepSearchEnabled: Bool
	
	/// Causes search to return early when it finds a node matching this predicate. Search may not return a nodes matching this predicate if the given search index has no matching parent nodes.
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
