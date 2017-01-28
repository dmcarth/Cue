//
//  NamedEntities.swift
//  Cue
//
//  Created by Dylan McArthur on 1/27/17.
//
//

struct NamedEntities {
	
	var names = [String: Array<String.UTF16Index>]()
	
	init() {}
	
	mutating func addReference(to name: String, at location:  String.UTF16Index) {
		var referencesForName = names[name] ?? []
		
		referencesForName.append(location)
		
		names[name] = referencesForName
	}
	
}
