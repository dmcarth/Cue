//
//  TableOfContents.swift
//  Cue
//
//  Created by Dylan McArthur on 2/3/17.
//
//

struct TableOfContents<S: BidirectionalCollection, C: Codec> where
	S.Iterator.Element == C.CodeUnit,
	S.SubSequence: BidirectionalCollection,
	S.SubSequence.Iterator.Element == S.Iterator.Element
{
	
	typealias Index = S.Index
	
	var contents: [TableOfContentsItem<Index>]
	
	init(_ parser: Cue<S, C>) {
		var contents = [TableOfContentsItem<Index>]()
		
		parser.root.enumerate { (node) in
			if case .headerBlock(let type) = node.type {
				let itemType = TableOfContentsType.init(keyword: type)
				let item = TableOfContentsItem(type: itemType, location: node.range.lowerBound)
				contents.append(item)
			} else if case .reference = node.type {
				let item = TableOfContentsItem(type: .reference, location: node.range.lowerBound)
				contents.append(item)
			}
		}
		
		self.contents = contents
	}
	
}
