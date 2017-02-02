//
//  Searchable.swift
//  Cue
//
//  Created by Dylan McArthur on 1/31/17.
//
//

public enum SearchComparison {
	case lessThan
	case contains
	case greaterThan
}

public protocol Searchable {
	
	func compare(to index: Int) -> SearchComparison
	
}

public struct SearchOptions {
	
	/// Enables search to traverse nodes deeper than level-1
	public var deepSearchEnabled: Bool
	
	/// Causes search to return on the first node matching this predicate. If no match is found, search will return nil.
	public var predicate: ((AbstractNode)->Bool)?
	
	public init(deepSearch: Bool = true, predicate: ((AbstractNode)->Bool)?=nil) {
		self.deepSearchEnabled = deepSearch
		self.predicate = predicate
	}
	
}

extension Searchable where Self: Enumerable {
	
	public func searchChildren(for index: Int, options: SearchOptions) -> AbstractNode? {
		guard compare(to: index) == .contains else { return nil }
		
		return _searchChildren(for: index, options: options)
	}
	
	private func _searchChildren(for index: Int, options: SearchOptions) -> AbstractNode? {
		var lower = 0
		var upper = children.count
		
		while lower < upper {
			let midIndex = lower + (upper - lower) / 2
			let child = children[midIndex]
			let comparison = child.compare(to: index)
			
			switch comparison {
			case .greaterThan:
				upper = midIndex
			case .lessThan:
				lower = midIndex + 1
			case .contains:
				// We found a match!
				
				// If a custom search predicate has been provided, that takes precedence over everything else
				if let predicate = options.predicate {
					if predicate(child) { return child }
				}
				
				if options.deepSearchEnabled {
					if let deepMatch = child._searchChildren(for: index, options: options) {
						return deepMatch
					}
				}
				
				// Checking for nil ensures that a search with a predicate will only return if the matching node passes the given predicate
				if options.predicate == nil {
					return child
				}
				
				// Search matched the index but none of the options, break the loop
				break
			}
		}
		
		return nil
	}
	
}
