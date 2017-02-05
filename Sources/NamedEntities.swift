//
//  NamedEntities.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

struct NamedEntities<S: BidirectionalCollection, C: Codec> where
	S.Iterator.Element == C.CodeUnit,
	S.SubSequence: BidirectionalCollection,
	S.SubSequence.Iterator.Element == S.Iterator.Element
{
	
	typealias Index = S.Index
	
	var map: [String: Array<Index>]
	
	init(_ parser: Cue<S, C>) {
		var map = [String: Array<Index>]()
		
		parser.root.enumerate { (node) in
			if case .name = node.type {
				let scalars = C.scalars(from: parser.data[node.range])
				let view = String.UnicodeScalarView(scalars)
				let name = String(view)
				
				var referencesForName = map[name] ?? []
				
				referencesForName.append(node.range.lowerBound)
				
				map[name] = referencesForName
			}
		}
		
		self.map = map
	}
	
}
