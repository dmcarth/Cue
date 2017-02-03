//
//  Searchable.swift
//  Cue
//
//  Created by Dylan McArthur on 1/31/17.
//
//

enum SearchComparison {
	case lessThan
	case contains
	case greaterThan
}

public struct SearchOptions<Index: Comparable> {
	
	/// Enables search to traverse nodes deeper than level-1
	public var deepSearchEnabled: Bool
	
	/// Causes search to return on the first node matching this predicate. If no match is found, search will return nil.
	public var predicate: ((Node<Index>)->Bool)?
	
	public init(deepSearch: Bool = true, predicate: ((Node<Index>)->Bool)?=nil) {
		self.deepSearchEnabled = deepSearch
		self.predicate = predicate
	}
	
}

extension Node {
	
	public func childNodes(from lowerBound: Index, to upperBound: Index) -> [Node<Index>] {
		var nodes = [Node<Index>]()
		
		let opts = SearchOptions<Index>(deepSearch: false)
		
		if var node = search(for: lowerBound, options: opts) {
			nodes.append(node)
			
			var searchIndex = node.range.upperBound
			var safeUpperBound = min(range.upperBound, upperBound)
			
			while let next = node.next, searchIndex < safeUpperBound {
				nodes.append(next)
				searchIndex = node.range.upperBound
				node = next
			}
		}
		
		return nodes
	}
	
	public func search(for index: Index, options: SearchOptions<Index>) -> Node<Index>? {
		guard compare(to: index) == .contains else { return nil }
		
		return _search(for: index, options: options)
	}
	
	private func _search(for index: Index, options: SearchOptions<Index>) -> Node<Index>? {
		var lower = 0
		var upper = children.count
		
		while lower < upper {
			let midIndex = lower + (upper - lower) / 2
			let child = children[midIndex]
			let comparison = child.compare(to: index)
			
			switch comparison {
			case .greaterThan:
				lower = midIndex
			case .lessThan:
				upper = midIndex + 1
			case .contains:
				// We found a match!
				
				// If a custom search predicate has been provided, that takes precedence over everything else
				if let predicate = options.predicate {
					if predicate(child) { return child }
				}
				
				if options.deepSearchEnabled {
					if let deepMatch = child._search(for: index, options: options) {
						return deepMatch
					}
				}
				
				// Checking for nil ensures that a search with a predicate will only return if the matching node passes the given predicate. A search without a predicate will prioritize depth first.
				if options.predicate == nil {
					return child
				}
				
				// Search matched the index but none of the options, break the loop
				break
			}
		}
		
		return nil
	}
	
	private func compare(to index: Index) -> SearchComparison {
		if index < range.lowerBound {
			return .greaterThan
		} else if index >= range.upperBound {
			return .lessThan
		} else {
			return .contains
		}
	}
	
}
