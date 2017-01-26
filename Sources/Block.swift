//
//  Block.swift
//  Cue
//
//  Created by Dylan McArthur on 11/17/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Block: Node {
	public var lineNumber = 0
	
	public init(startIndex: Int, endIndex: Int, offset: Int) {
		super.init(startIndex: startIndex, endIndex: endIndex)
		
		if offset > startIndex {
			let del = Delimiter(startIndex: startIndex, endIndex: offset)
			del.type = .whitespace
			addChild(del)
		}
	}
}

public class Document: Block {
	public convenience init() {
		self.init(startIndex: 0, endIndex: 0, offset: 0)
	}
}

public class Heading: Block {
	public init(startIndex: Int, endIndex: Int, results: [SearchResult]) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: results[0].startIndex)
		
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

public class CommentBlock: Block {
	public init(startIndex: Int, endIndex: Int, results: [SearchResult]) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: results[0].startIndex)
		
		let cont1 = CommentText(results[0])
		addChild(cont1)
		
		let delim = Delimiter(results[1])
		delim.type = .whitespace
		addChild(delim)
		
		let cont2 = CommentText(results[1])
		addChild(cont2)
	}
}

public class FacsimileBlock: Block {
	public init(startIndex: Int, endIndex: Int) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: startIndex)
	}
}

public class Facsimile: Block {
	public init(startIndex: Int, endIndex: Int, result: SearchResult) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: result.startIndex)
		
		let de = Delimiter(result)
		addChild(de)
		
		let te = RawText(startIndex: result.endIndex, endIndex: endIndex)
		addChild(te)
	}
}

public class CueBlock: Block {
	public init(startIndex: Int, endIndex: Int) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: startIndex)
	}
}

public class AbstractCue: Block {
	internal func addDefaultChildren(for results: [SearchResult]) {
		let name = Name(startIndex: results[0].startIndex, endIndex: results[0].endIndex)
		addChild(name)
		
		let del2 = Delimiter(results[1])
		del2.type = .colon
		addChild(del2)
		
		let te = RawText(startIndex: del2.endIndex, endIndex: endIndex)
		addChild(te)
	}
}

public class RegularCue: AbstractCue {
	public init(startIndex: Int, endIndex: Int, results: [SearchResult]) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: results[0].startIndex)
		
		addDefaultChildren(for: results)
	}
}
public class DualCue: AbstractCue {
	public init(startIndex: Int, endIndex: Int, results: [SearchResult]) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: results[0].startIndex)
		
		let del = Delimiter(results[0])
		del.type = .dual
		addChild(del)
		
		addDefaultChildren(for: Array(results.dropFirst()))
	}
}

public class LyricBlock: Block {
	public init(startIndex: Int, endIndex: Int) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: startIndex)
	}
}

public class Lyric: Block {
	public init(startIndex: Int, endIndex: Int, result: SearchResult) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: result.startIndex)
		
		let delim = Delimiter(result)
		delim.type = .lyric
		addChild(delim)
		
		let te = RawText(startIndex: delim.endIndex, endIndex: endIndex)
		addChild(te)
	}
}

public class Description: Block {
	public init(startIndex: Int, endIndex: Int) {
		super.init(startIndex: startIndex, endIndex: endIndex, offset: startIndex)
		
		let te = RawText(startIndex: startIndex, endIndex: endIndex)
		addChild(te)
	}
}

public class EndBlock: Block {
	
}
