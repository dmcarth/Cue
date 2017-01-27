//
//  TOCNode.swift
//  Cue
//
//  Created by Dylan McArthur on 1/26/17.
//
//

public class TOCNode {
	
	public weak var parent: TOCNode?
	public var children = [TOCNode]()
	
	public enum ContentType {
		case act
		case chapter
		case scene
		case page
		case reference
		
		init(keyword: Keyword.KeywordType) {
			switch keyword {
			case .act:
				self = .act
			case .chapter:
				self = .chapter
			case .scene:
				self = .scene
			}
		}
	}
	
	public var type: ContentType
	public var location: Int
	
	public init(type: ContentType, location: Int) {
		self.type = type
		self.location = location
	}
	
}
