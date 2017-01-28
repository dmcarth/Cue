//
//  NamedEntities.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

struct NamedEntities {
	
	var map: [String: Array<String.UTF16Index>]
	
	init(_ ast: Node) {
		var map = [String: Array<String.UTF16Index>]()
		
		ast.enumerate { (node) in
			if node is Name {
				let name = String(data[node.startIndex..<node.endIndex])!
				
				var referencesForName = map[name] ?? []
				
				referencesForName.append(node.startIndex)
				
				map[name] = referencesForName
			}
		}
		
		self.map = map
	}
	
}
