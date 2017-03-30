//
//  NamedEntities.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

struct NamedEntities {
	
	var map: [String: Array<Int>]
	
	init(_ parser: Cue) {
		var map = [String: Array<Int>]()
		
		parser.root.enumerate { (node) in
			if node is Name {
				let scalars = Cue.C.scalars(from: parser.data[node.range])
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
