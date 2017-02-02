//
//  TableOfContents.swift
//  Cue
//
//  Created by Dylan McArthur on 1/28/17.
//
//

struct TableOfContents {
	
	var contents: [TableOfContentsItem]
	
	init(_ parser: Cue) {
		var contents = [TableOfContentsItem]()
		
		parser.root.enumerate { (node) in
			if let header = node as? HeaderBlock {
				let type = TableOfContentsType.init(keyword: header.type)
				let item = TableOfContentsItem(type: type, location: header.range.lowerBound)
				
				contents.append(item)
			} else if let reference = node as? Reference {
				let item = TableOfContentsItem(type: .reference, location: reference.range.lowerBound)
				
				contents.append(item)
			}
		}
		
		self.contents = contents
	}
	
}
