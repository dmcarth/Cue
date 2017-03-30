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

public final class EndBlock: Node, LeftDelimited, RightDelimited {
	
	public var leftDelimiter: Delimiter
	
	public var rightDelimiter: Delimiter
	
	init(start: Int, body: Range<Int>, end: Int) {
		self.leftDelimiter = Delimiter(range: start..<body.lowerBound)
		self.rightDelimiter = Delimiter(range: body.upperBound..<end)
		super.init(range: body)
	}
	
}

// MARK: Headers
public final class Header: Node, LeftDelimited, RightDelimited {
	
	public enum HeaderType {
		case act
		case chapter
		case scene
		case page
	}
	
	public var type: HeaderType
	
	public var leftDelimiter: Delimiter
	
	public var keyword: Keyword
	
	public var identifier: Identifier
	
	public var title: Title?
	
	public var rightDelimiter: Delimiter
	
	init(type: HeaderType, start: Int, keyword: Keyword, identifier: Identifier, title: Title?=nil, end: Int) {
		self.leftDelimiter = Delimiter(range: start..<keyword.offset)
		self.type = type
		self.keyword = keyword
		self.identifier = identifier
		self.title = title
		
		let titleUpper = (title != nil) ? title!.range.upperBound : identifier.range.upperBound
		self.rightDelimiter = Delimiter(range: titleUpper..<end)
		super.init(range: keyword.range.lowerBound..<end)
		
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

public class CueBlock: Node, LeftDelimited {
	
	public var leftDelimiter: Delimiter
	
	public var isDual: Bool
	
	public var name: Name
	
	public var direction: Node
	
	public var isSelfDescribing: Bool {
		return direction.isEmpty
	}
	
	init(left: Range<Int>, isDual: Bool, name: Name, direction: Node) {
		self.leftDelimiter = Delimiter(range: left)
		self.isDual = isDual
		self.name = name
		self.direction = direction
		
		super.init(range: name.range.lowerBound..<direction.rangeIncludingMarkers.upperBound)
		
		addChild(name)
		addChild(direction)
	}
	
}

public final class Name: Node, RightDelimited {
	
	public var rightDelimiter: Delimiter
	
	init(body: Range<Int>, right: Range<Int>) {
		self.rightDelimiter = Delimiter(range: right)
		super.init(range: body)
	}
	
}

public final class DirectionBlock: Node, RightDelimited {
	
	public var rightDelimiter: Delimiter
	
	init(body: Range<Int>, end: Int) {
		self.rightDelimiter = Delimiter(range: body.upperBound..<end)
		super.init(range: body)
	}
	
}

public final class LyricContainer: Node {
	
}

public final class LyricBlock: Node, LeftDelimited, RightDelimited { // contains inlines directly
	
	public var leftDelimiter: Delimiter
	
	public var rightDelimiter: Delimiter
	
	init(start: Int, body: Range<Int>, end: Int) {
		self.leftDelimiter = Delimiter(range: start..<body.lowerBound)
		self.rightDelimiter = Delimiter(range: body.upperBound..<end)
		super.init(range: body)
	}
	
}



// MARK: Facsimiles
public final class FacsimileContainer: Node {
	
}

public final class FacsimileBlock: Node, LeftDelimited, RightDelimited { // contains inlines directly
	
	public var leftDelimiter: Delimiter
	
	public var rightDelimiter: Delimiter
	
	init(start: Int, body: Range<Int>, end: Int) {
		self.leftDelimiter = Delimiter(range: start..<body.lowerBound)
		self.rightDelimiter = Delimiter(range: body.upperBound..<end)
		super.init(range: body)
	}
	
}



// MARK: Description
public final class Description: Node, LeftDelimited, RightDelimited { // contains inlines directly
	
	public var leftDelimiter: Delimiter
	
	public var rightDelimiter: Delimiter
	
	init(start: Int, body: Range<Int>, end: Int) {
		self.leftDelimiter = Delimiter(range: start..<body.lowerBound)
		self.rightDelimiter = Delimiter(range: body.upperBound..<end)
		super.init(range: body)
	}
	
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
