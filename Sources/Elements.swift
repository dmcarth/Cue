//
//  Elements.swift
//  Cue
//
//  Created by Dylan McArthur on 1/28/17.
//
//

//final public class Document: AbstractContainer {
//	// headerBlock, descriptionBlock, cueContainer, facsimileContainer, and/or endBlock
//}
//
//final public class HeaderBlock: AbstractNode {
//	
//	public enum HeaderType {
//		case act
//		case chapter
//		case scene
//		case page
//	}
//	
//	public var type: HeaderType
//
//	public var keyword: Literal
//	
//	public var identifier: Literal
//	
//	public var name: (Delimiter, TextStream)?
//	
//	override public var children: [AbstractNode] {
//		var children: [AbstractNode] = [keyword, identifier]
//		if let name = name {
//			children.append(name.0)
//			children.append(name.1)
//		}
//		return children
//	}
//	
//	public init(type: HeaderType, keyword: Range<Int>, identifier: Range<Int>, name: (Range<Int>, Range<Int>)?) {
//		self.type = type
//		self.keyword = Literal(range: keyword)
//		self.identifier = Literal(range: identifier)
//		self.keyword.next = self.identifier
//		
//		var upperBound = identifier.upperBound
//		if let name = name {
//			self.name = (Delimiter(range: name.0), TextStream(range: name.1))
//			self.identifier.next = self.name!.0
//			self.name!.0.next = self.name!.1
//			upperBound = name.1.upperBound
//		}
//		
//		super.init(range: keyword.lowerBound..<upperBound)
//	}
//	
//}
//
//final public class DescriptionBlock: AbstractNode {
//	
//	public var textStream: TextStream
//	
//	override public var children: [AbstractNode] {
//		return [textStream]
//	}
//	
//	override init(range: Range<Int>) {
//		self.textStream = TextStream(range: range)
//		
//		super.init(range: range)
//	}
//	
//}
//
//final public class CueContainer: AbstractContainer {
//	// children are all cueBlocks
//}
//
//final public class CueBlock: AbstractNode {
//	
//	public var delimiter: Delimiter?
//	
//	public var isRegular: Bool {
//		return delimiter == nil
//	}
//	
//	public var isDual: Bool {
//		return !isRegular
//	}
//	
//	public var name: Literal
//	
//	public var space: Delimiter
//	
//	public var content: AbstractContainer // Either TextStream or LyricContainer
//	
//	override public var children: [AbstractNode] {
//		var children: [AbstractNode] = isDual ? [delimiter!] : []
//		children.append(contentsOf: [name, space, content])
//		return children
//	}
//	
//	public init(start: Range<Int>?, name: Range<Int>, space: Range<Int>, content: Range<Int>) {
//		var lowerBound = name.lowerBound
//		if let start = start {
//			self.delimiter = Delimiter(range: start)
//			lowerBound = start.lowerBound
//		}
//		self.name = Literal(range: name)
//		self.space = Delimiter(range: space)
//		self.content = TextStream(range: content)
//		
//		super.init(range: lowerBound..<content.upperBound)
//	}
//	
//}
//
//final public class LyricContainer: AbstractContainer {
//	// children are lyricBlocks
//	
//}
//
//final public class LyricBlock: AbstractNode {
//	
//	public var delimiter: Delimiter
//	
//	public var textStream: TextStream
//	
//	override public var children: [AbstractNode] {
//		return [delimiter, textStream]
//	}
//	
//	public init(start: Range<Int>, content: Range<Int>) {
//		self.delimiter = Delimiter(range: start)
//		self.textStream = TextStream(range: content)
//		
//		super.init(range: start.lowerBound..<content.upperBound)
//	}
//}
//
//final public class FacsimileContainer: AbstractContainer {
//	// children are all facsimileBlocks
//}
//
//final public class FacsimileBlock: AbstractNode {
//	
//	public var delimiter: Delimiter
//	
//	public var textStream: TextStream
//	
//	override public var children: [AbstractNode] {
//		return [delimiter, textStream]
//	}
//	
//	public init(start: Range<Int>, content: Range<Int>) {
//		self.delimiter = Delimiter(range: start)
//		self.textStream = TextStream(range: content)
//		
//		super.init(range: start.lowerBound..<content.upperBound)
//	}
//	
//}
//
//final public class EndBlock: AbstractNode {
//	
//}
