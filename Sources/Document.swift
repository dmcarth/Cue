//
//  Document.swift
//  Cue
//
//  Created by Dylan McArthur on 2/10/17.
//
//

public protocol LeftDelimited {
	
	var leftDelimiter: Delimiter { get }
	
}

public protocol RightDelimited {
	
	var rightDelimiter: Delimiter { get }
	
}

public final class Delimiter: Node {
	
}

public final class Document: Node {
	
}

public final class EndBlock: Node {
	
}

// MARK: Headers
public final class Header: Node {
	
	public enum HeaderType: Int {
		case act, chapter, scene, page
	}
	
	public var type: HeaderType
	
	public var keyword: Keyword
	
	public var identifier: Identifier
	
	public var title: Title?
	
	init(type: HeaderType, keyword: Keyword, identifier: Identifier, title: Title?=nil) {
		self.type = type
		self.keyword = keyword
		self.identifier = identifier
		self.title = title
		
		let upperBound = (title != nil) ? title!.range.upperBound : identifier.range.upperBound
		super.init(range: keyword.range.lowerBound..<upperBound)
		
		addChild(keyword)
		addChild(identifier)
		if let title = title { addChild(title) }
	}
	
}

public final class Keyword: Node {
	
}

public final class Identifier: Node {
	
}

public final class Title: Node, LeftDelimited { // contains inlines directly
	
	public var leftDelimiter: Delimiter
	
	init(left: Range<Int>, body: Range<Int>) {
		self.leftDelimiter = Delimiter(range: left)
		super.init(range: body)
	}
	
}



// MARK: Cues
public final class CueContainer: Node {
	
}

public class CueBlock: Node {
	
	public var name: Name
	
	public var direction: Direction
	
	public var isSelfDescribing: Bool {
		return direction.isEmpty
	}
	
	init(name: Name, direction: Direction) {
		self.name = name
		self.direction = direction
		
		super.init(range: name.range.lowerBound..<direction.range.upperBound)
		
		addChild(name)
		addChild(direction)
	}
	
}

public final class DualCue: CueBlock, LeftDelimited {
	
	public var leftDelimiter: Delimiter
	
	init(left: Range<Int>, name: Name, direction: Direction) {
		self.leftDelimiter = Delimiter(range: left)
		super.init(name: name, direction: direction)
	}
	
}

public final class Name: Node, RightDelimited {
	
	public var rightDelimiter: Delimiter
	
	init(body: Range<Int>, right: Range<Int>) {
		self.rightDelimiter = Delimiter(range: right)
		super.init(range: body)
	}
	
}

public final class Direction: Node { // contains either lyricContainer or inlines
	
}



public final class LyricContainer: Node {
	
}

public final class LyricBlock: Node, LeftDelimited { // contains inlines directly
	
	public var leftDelimiter: Delimiter
	
	init(left: Range<Int>, body: Range<Int>) {
		self.leftDelimiter = Delimiter(range: left)
		super.init(range: body)
	}
	
}



// MARK: Facsimiles
public final class FacsimileContainer: Node {
	
}

public final class FacsimileBlock: Node, LeftDelimited { // contains inlines directly
	
	public var leftDelimiter: Delimiter
	
	init(left: Range<Int>, body: Range<Int>) {
		self.leftDelimiter = Delimiter(range: left)
		super.init(range: body)
	}
	
}



// MARK: Description
public final class Description: Node { // contains inlines directly
	
}

public final class Literal: Node {
	
}

public final class Emphasis: Node, LeftDelimited, RightDelimited {
	
	public var leftDelimiter: Delimiter
	
	public var rightDelimiter: Delimiter
	
	init(left: Range<Int>, body: Range<Int>, right: Range<Int>) {
		self.leftDelimiter = Delimiter(range: left)
		self.rightDelimiter = Delimiter(range: right)
		super.init(range: body)
	}
	
}

public final class Reference: Node, LeftDelimited, RightDelimited {
	
	public enum ReferenceType {
		case image
		case unknown
		
		init?(ext: String) {
			switch ext {
			case "jpg", "jpeg", "png", "gif":
				self = .image
			default:
				return nil
			}
		}
	}
	
	public var type: ReferenceType = .unknown
	
	public var leftDelimiter: Delimiter
	
	public var rightDelimiter: Delimiter
	
	init(left: Range<Int>, body: Range<Int>, right: Range<Int>) {
		self.leftDelimiter = Delimiter(range: left)
		self.rightDelimiter = Delimiter(range: right)
		super.init(range: body)
	}
	
}

public final class Comment: Node, LeftDelimited {
	
	public var leftDelimiter: Delimiter
	
	init(left: Range<Int>, body: Range<Int>) {
		self.leftDelimiter = Delimiter(range: left)
		super.init(range: body)
	}
	
}
