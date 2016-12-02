//
//  Block.swift
//  Cue
//
//  Created by Dylan McArthur on 11/17/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

extension Block {
	func addDefaultChildren(offset: Int) {
		let del = Delimiter(startIndex: startIndex, endIndex: offset)
		del.type = .whitespace
		addChild(del)
	}
}

extension Heading {
	override func addDefaultChildren(offset: Int) {
		super.addDefaultChildren(offset: offset)
		let te = RawText(startIndex: offset, endIndex: endIndex)
		addChild(te)
	}
}

extension Lyric {
	func addDefaultChildren(for result: SearchResult) {
		addDefaultChildren(offset: result.startIndex)
		
		let delim = Delimiter(startIndex: result.startIndex, endIndex: result.endIndex)
		delim.type = .lyric
		addChild(delim)
		
		let te = RawText(startIndex: delim.endIndex, endIndex: endIndex)
		addChild(te)
	}
}

extension CommentBlock {
	func addDefaultChildren(for results: [SearchResult]) {
		addDefaultChildren(offset: results[0].startIndex)
		
		let cont1 = CommentText(startIndex: results[0].startIndex, endIndex: results[0].endIndex)
		addChild(cont1)
		
		let delim = Delimiter(startIndex: results[1].startIndex, endIndex: results[1].endIndex)
		delim.type = .whitespace
		addChild(delim)
		
		let cont2 = CommentText(startIndex: results[1].endIndex, endIndex: endIndex)
		addChild(cont2)
	}
}
