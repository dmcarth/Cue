//
//  Inline.swift
//  Cue
//
//  Created by Dylan McArthur on 12/14/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Inline: Node {}

public class Keyword: Inline {
	public enum KeywordType {
		case act
		case chapter
		case scene
	}
	var type: KeywordType = .act
}
public class Identifier: Inline {}

public class RawText: Inline {}
public class CommentText: Inline {}
public class Delimiter: Inline {
	public enum DelimiterType {
		case whitespace
		case dual
		case lyric
		case facsimile
		case emph
		case colon
		case hyphen
		case openBracket
		case closeBracket
	}
	public var type: DelimiterType = .whitespace
}
public class Name: Inline {}
public class Emphasis: Inline {}
public class Reference: Inline {}
