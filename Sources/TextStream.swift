//
//  TextStream.swift
//  Cue
//
//  Created by Dylan McArthur on 1/28/17.
//
//

//final public class TextStream: AbstractContainer {
//	// children can be literal, comment, emphasis, and/or reference
//}
//
//final public class Literal: AbstractNode {
//	
//}
//
//final public class Comment: AbstractNode {
//	
//}
//
//final public class Emphasis: AbstractNode {
//	
//	public var delimiters: (Delimiter, Delimiter)
//	
//	public var literal: Literal
//	
//	override public var children: [AbstractNode] {
//		return [delimiters.0, literal, delimiters.1]
//	}
//	
//	public init(start: Range<Int>, stop: Range<Int>) {
//		self.delimiters = (Delimiter(range: start), Delimiter(range: stop))
//		self.literal = Literal(range: start.upperBound..<stop.lowerBound)
//		
//		super.init(range: start.lowerBound..<stop.upperBound)
//	}
//}
//
//final public class Reference: AbstractNode {
//	
//	public var delimiters: (Delimiter, Delimiter)
//	
//	public var link: Literal
//	
//	override public var children: [AbstractNode] {
//		return [delimiters.0, link, delimiters.1]
//	}
//	
//	public init(start: Range<Int>, stop: Range<Int>) {
//		self.delimiters = (Delimiter(range: start), Delimiter(range: stop))
//		self.link = Literal(range: start.upperBound..<stop.lowerBound)
//		
//		super.init(range: start.lowerBound..<stop.upperBound)
//	}
//}
//
//final public class Delimiter: AbstractNode {
//	
//}
