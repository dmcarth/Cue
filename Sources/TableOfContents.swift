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
			switch node {
			case is Header:
				let type = TableOfContentsItem.ContentType.init(keyword: (node as! Header).type)
				let item = TableOfContentsItem(type: type, location: node.startIndex)
				
				contents.append(item)
			case is Reference:
				let item = TableOfContentsItem(type: .reference, location: node.startIndex)
				
				contents.append(item)
			default:
				break
			}
		}
		
		self.contents = contents
	}
	
}
