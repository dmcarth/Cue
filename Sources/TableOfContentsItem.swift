//
//  TableOfContentsItem.swift
//  Cue
//
//  Created by Dylan McArthur on 1/26/17.
//
//

public struct TableOfContentsItem {
	
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
	public var location: HybridUTF16Index
	
	public init(type: ContentType, location: HybridUTF16Index) {
		self.type = type
		self.location = location
	}
	
}
