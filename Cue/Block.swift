//
//  Block.swift
//  Cue
//
//  Created by Dylan McArthur on 11/17/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

extension Block {
	func addDefaultChildren(offset: Int) {
		if offset > startIndex {
			let del = Delimiter(startIndex: startIndex, endIndex: offset)
			del.type = .whitespace
			addChild(del)
		}
	}
}

extension Heading {
	func addDefaultChildren(for results: [SearchResult]) {
		addDefaultChildren(offset: results[0].startIndex)
		
		let key = Keyword(results[0])
		key.type = results[0].keywordType!
		addChild(key)
		
		let del = Delimiter(results[1])
		del.type = .whitespace
		addChild(del)
		
		let id = Identifier(results[2])
		addChild(id)
		
		if results.count >= 5 {
			let del1 = Delimiter(results[3])
			addChild(del1)
			let te = RawText(results[4])
			addChild(te)
		}
	}
}

extension Lyric {
	func addDefaultChildren(for result: SearchResult) {
		addDefaultChildren(offset: result.startIndex)
		
		let delim = Delimiter(result)
		delim.type = .lyric
		addChild(delim)
		
		let te = RawText(startIndex: delim.endIndex, endIndex: endIndex)
		addChild(te)
	}
}

extension CommentBlock {
	func addDefaultChildren(for results: [SearchResult]) {
		addDefaultChildren(offset: results[0].startIndex)
		
		let cont1 = CommentText(results[0])
		addChild(cont1)
		
		let delim = Delimiter(results[1])
		delim.type = .whitespace
		addChild(delim)
		
		let cont2 = CommentText(results[1])
		addChild(cont2)
	}
}
