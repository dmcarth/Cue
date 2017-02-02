//
//  NamedEntities.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

//struct NamedEntities {
//	
//	var map: [String: Array<Int>]
//	
//	init(_ parser: Cue) {
//		var map = [String: Array<Int>]()
//		
//		parser.root.enumerate { (node) in
//			if let cue = node as? CueBlock {
//				let bytes = Array(parser.data[cue.name.range])
//				let name = String(bytes)
//				
//				var referencesForName = map[name] ?? []
//				
//				referencesForName.append(cue.name.range.lowerBound)
//				
//				map[name] = referencesForName
//			}
//		}
//		
//		self.map = map
//	}
//	
//}
