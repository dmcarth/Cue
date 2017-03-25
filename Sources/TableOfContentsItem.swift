//
//  TableOfContentsItem.swift
//  Cue
//
//  Created by Dylan McArthur on 1/26/17.
//
//

public struct TableOfContentsItem {
	
	public var type: TableOfContentsType
	
	public var location: Int
	
	public init(type: TableOfContentsType, location: Int) {
		self.type = type
		self.location = location
	}
	
}


public enum TableOfContentsType {
	case act
	case chapter
	case scene
	case page
	case reference
	
	init(keyword: Header.HeaderType) {
		switch keyword {
		case .act:
			self = .act
		case .chapter:
			self = .chapter
		case .scene:
			self = .scene
		case .page:
			self = .page
		}
	}
}

