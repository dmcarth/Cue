//
//  TableOfContents.swift
//  Cue
//
//  Created by Dylan McArthur on 2/3/17.
//
//

struct TableOfContents {
	
	var contents: [TableOfContentsItem]
	
	init(_ parser: Cue) {
		var contents = [TableOfContentsItem]()
		
		parser.root.enumerate { (node) in
			if let header = node as? Header {
				let itemType = TableOfContentsType.init(keyword: header.type)
				let item = TableOfContentsItem(type: itemType, location: node.range.lowerBound)
				contents.append(item)
			} else if node is Reference {
				let item = TableOfContentsItem(type: .reference, location: node.range.lowerBound)
				contents.append(item)
			}
		}
		
		self.contents = contents
	}
	
}
