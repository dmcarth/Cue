//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

@objc public class CueParser: NSObject {
	
	var data = [UInt16]()
	
	var root = Document()
	
	var lineNumber = 0
	
	var charNumber = 0
	
	var endOfLineCharNumber = 0
	
	public class func parse(_ string: String) -> Node {
		let bytes = [UInt16](string.utf16)
		let parser = CueParser(with: bytes)
		return parser.parse()
	}
	
	public override init() {
		super.init()
	}
	
	public init<S: Sequence>(with bytes: S) where S.Iterator.Element == UInt16 {
		data = Array(bytes)
		
		// useful for debugging
		endOfLineCharNumber = data.count
	}
	
	public init(_ string: String) {
		let bytes = [UInt16](string.utf16)
		data = bytes
		
		// useful for debugging
		endOfLineCharNumber = data.count
	}
	
	public func parse() -> Node {
		root = Document()
		lineNumber = 0
		charNumber = 0
		endOfLineCharNumber = 0
		
		parseBlocks()
		
		return root
	}
	
}

// MARK: - Block Parsing
extension CueParser {
	
	func parseBlocks() {
		// Enumerate lines
		while charNumber < data.count {
			//	Find line ending
			endOfLineCharNumber = charNumber
			while endOfLineCharNumber < data.count {
				endOfLineCharNumber += 1
				if scanForLineEnding(atIndex: endOfLineCharNumber-1) {
					break
				}
			}
			
			lineNumber += 1
			
			processLine()
			
			charNumber = endOfLineCharNumber
		}
		
		root.endIndex = data.count
	}
	
	func processLine() {
		var block = blockForLine()
		block.lineNumber = lineNumber
		
		let container = appropriateContainer(for: &block)
		container.addChild(block)
		container.startIndex = min(container.startIndex, block.startIndex)
		container.endIndex = max(container.endIndex, block.endIndex)
		
		// Only now can we parse first-line lyrics, because appropriateContainer() may have changed the original block
		if let cb = block as? Cue {
			guard cb.children.last! is RawText else {
				return
			}
			
			let last: Node = cb.children.last!
			
			if let result = scanForLyricPrefix(atIndex: last.startIndex) {
				let ly = Lyric(startIndex: result.startIndex, endIndex: endOfLineCharNumber)
				ly.addDefaultChildren(for: result)
				
				parseInlines(for: ly, startingAt: result.endIndex)
				
				cb.removeLastChild()
				cb.addChild(ly)
			}
		}
		
		// Parse RawText into a stream of inlines. RawText, if present, will always be the last child at this stage
		if let raw = block.children.last as? RawText {
			parseInlines(for: block, startingAt: raw.startIndex)
		}
	}
	
	func blockForLine() -> Block {
		let wc = scanForFirstNonspace(startingAtIndex: charNumber)
		
		if let results = scanForHeading(atIndex: wc) {
			let he = Heading(startIndex: wc, endIndex: endOfLineCharNumber)
			
			he.addDefaultChildren(for: results)
			
			return he
		} else if let result = scanForComment(atIndex: wc) {
			let com = CommentBlock(startIndex: charNumber, endIndex: endOfLineCharNumber)
			
			com.addDefaultChildren(for: result)
			
			return com
		} else if let result = scanForLyricPrefix(atIndex: wc) {
			let ly = Lyric(startIndex: charNumber, endIndex: endOfLineCharNumber)
			
			ly.addDefaultChildren(for: result)
			
			return ly
		} else if let result = scanForDualCue(atIndex: wc) {
			let du = DualCue(startIndex: charNumber, endIndex: endOfLineCharNumber)
			
			du.addDefaultChildren(for: result)
			
			return du
		} else if let result = scanForCue(atIndex: wc) {
			let cu = RegularCue(startIndex: charNumber, endIndex: endOfLineCharNumber)
			
			cu.addDefaultChildren(for: result)
			
			return cu
		}
		
		let des = Description(startIndex: charNumber, endIndex: endOfLineCharNumber)
		let te = RawText(startIndex: wc, endIndex: endOfLineCharNumber)
		des.addChild(te)
		return des
	}
	
	func appropriateContainer(for block: inout Block) -> Node {
		var container: Node = root
		
		switch block {
		// These block types can only ever be level-1
		case is Heading, is Description, is CommentBlock:
			return root
		// A regular cue is always level-2, with it's own initial parent cueBlock
		case is RegularCue:
			let cueBlockContainer = CueBlock(startIndex: block.startIndex, endIndex: block.endIndex)
			root.addChild(cueBlockContainer)
			return cueBlockContainer
		default:
			break
		}
		
		//	If none of those predetermined cases match, iterate down the tree, checking each lastchild in succession
		while let lastChild = container.children.last {
			container = lastChild
			
			var foundBreakingStatement = false
			
			switch container {
			case is LyricBlock:
				if block is Lyric {
					return container
				}
				break
			case is CueBlock:
				if block is DualCue {
					return container
				}
				break
			case is RegularCue, is DualCue:
				if block is Lyric {
					let lyb = LyricBlock(startIndex: block.startIndex, endIndex: block.endIndex)
					container.addChild(lyb)
					return lyb
				}
				fallthrough
			default:
				// Invalid syntax, time to fail gracefully
				foundBreakingStatement = true
			}
			
			if foundBreakingStatement { break }
		}
		
		//	If none of those cases have matched, it is because of some invalid syntax. Assume description
		block = Description()
		block.startIndex = charNumber
		block.endIndex = endOfLineCharNumber
		return root
	}
	
}

// MARK: - Inline Parsing
extension CueParser {
	
	func parseInlines(for block: Block, startingAt i: Int) {
		var spans = InlineCollection()
		
		var delimStack = DelimiterStack()
		
		var j = i
		while j < endOfLineCharNumber {
			let c = data[j]
			
			guard c == 0x002a || c == 0x005b || c == 0x005d else {
				j += 1
				continue
			}
			
			let del = Delimiter(startIndex: j, endIndex: j+1)
			switch c {
			case 0x002a:	// '*'
				del.type = .emph
				
				guard let last = delimStack.peek() else {
					delimStack.push(del)
					break
				}
				
				guard last.type != .openBracket else {
					break
				}
				
				if last.type == del.type {
					let _ = delimStack.pop()!
					
					guard last.endIndex < del.startIndex else { break }
					
					let em = Emphasis(startIndex: last.endIndex, endIndex: del.startIndex)
					spans.push(last)
					spans.push(em)
					spans.push(del)
					break
				}
				
				fatalError("Uknown state when parsing emphasis")
			case 0x005b:	// '['
				del.type = .openBracket
				
				guard let last = delimStack.peek() else {
					delimStack.push(del)
					break
				}
				
				guard last.type != .openBracket else {
					break
				}
				
				delimStack.push(del)
			case 0x005d:	// ']'
				del.type = .closeBracket
				
				guard let last = delimStack.peek() else {
					delimStack.push(del)
					break
				}
				
				if last.type == .openBracket {
					let _ = delimStack.pop()!
					
					guard last.endIndex < del.startIndex else { break }
					
					let ref = Reference(startIndex: last.endIndex, endIndex: del.startIndex)
					spans.push(last)
					spans.push(ref)
					spans.push(del)
					break
				}
				
				fatalError("Unknown state when parsing reference")
			default:
				break
			}
			
			j += 1
		}
		
		guard !spans.isEmpty else { return }
		
		block.removeLastChild()
		j = i
		
		// Run through span stack
		for span in spans {
			// Any space between spans should be just RawText
			if span.startIndex > j {
				let text = RawText(startIndex: j, endIndex: span.startIndex)
				block.addChild(text)
			}
			
			block.addChild(span)
			
			j = span.endIndex
		}
		
		// Add any remaining text as RawText
		if j < endOfLineCharNumber {
			let te = RawText(startIndex: j, endIndex: endOfLineCharNumber)
			block.addChild(te)
		}
	}
	
}

// MARK: - Scanners
extension CueParser {
	
	public func scanForLineEnding(atIndex i: Int) -> Bool {
		let c = data[i]
		
		return c == 0x000a || c == 0x000d // '\n', '\r'
	}
	
	public func scanForWhitespace(atIndex i: Int) -> Bool {
		let c = data[i]
		
		// ' ', '\t', newline
		return c == 0x0020 || c == 0x0009 || scanForLineEnding(atIndex: i)
	}
	
	public func scanForFirstNonspace(startingAtIndex i: Int) -> Int {
		var j = i
		
		while j < endOfLineCharNumber {
			if scanForWhitespace(atIndex: j) {
				j += 1
			} else {
				//return j
				break
			}
		}
		
		return j
	}
	
	public func scanForHyphen(startingAtIndex i: Int) -> Int {
		var j = i
		
		while j < endOfLineCharNumber {
			if data[j] == 0x002d {	// '-'
				break
			} else {
				j += 1
			}
		}
		
		return j
	}
	
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers the keyword, [1] covers whitespace, [2] covers the id, [3-4] covers the hyphen and title if present.
	public func scanForHeading(atIndex i: Int) -> [SearchResult]? {
		var type: Keyword.KeywordType
		var j = i
		
		if scanForActHeading(atIndex: i) {
			type = .act
			j += 3
		} else if scanForSceneHeading(atIndex: i) {
			type = .scene
			j += 5
		} else if scanForChapterHeading(atIndex: i) {
			type = .chapter
			j += 7
		} else {
			return nil
		}
		let keyResult = SearchResult(startIndex: i, endIndex: j, keywordType: type)
		
		
		let k = scanForFirstNonspace(startingAtIndex: j)
		guard k < endOfLineCharNumber else {
			return nil
		}
		let wResult = SearchResult(startIndex: j, endIndex: k)
		
		let l = scanForHyphen(startingAtIndex: k)
		let idResult = SearchResult(startIndex: k, endIndex: l)
		
		var results = [keyResult, wResult, idResult]
		
		if l < endOfLineCharNumber {
			let m = scanForFirstNonspace(startingAtIndex: l+1)
			let hResult = SearchResult(startIndex: l, endIndex: m)
			let titleResult = SearchResult(startIndex: m, endIndex: endOfLineCharNumber)
			results.append(contentsOf: [hResult, titleResult])
		}
		
		return results
	}
	
	public func scanForActHeading(atIndex i: Int) -> Bool {
		guard endOfLineCharNumber > i + 3 else {
			return false
		}
		
		if (data[i] == 0x0041 || data[i] == 0x0061) &&
			(data[i+1] == 0x0063 || data[i+1] == 0x0043) &&
			(data[i+2] == 0x0074 || data[i+2] == 0x0054) {	// 'A', 'c', 't' case insensitive
			let wc = scanForFirstNonspace(startingAtIndex: i+3)
			
			guard wc > i+3 else { return false }
			
			return true
		}
		
		return false
	}
	
	public func scanForChapterHeading(atIndex i: Int) -> Bool {
		guard endOfLineCharNumber > i + 7 else {
			return false
		}
		
		if (data[i] == 0x0043 || data[i] == 0x0063) &&
			(data[i+1] == 0x0068 || data[i+1] == 0x0048) &&
			(data[i+2] == 0x0061 || data[i+2] == 0x0041) &&
			(data[i+3] == 0x0070 || data[i+3] == 0x0050) &&
			(data[i+4] == 0x0074 || data[i+4] == 0x0054) &&
			(data[i+5] == 0x0065 || data[i+5] == 0x0045) &&
			(data[i+6] == 0x0072 || data[i+6] == 0x0052) {	// 'C', 'h', 'a', 'p', 't', 'e', 'r' case insensitive
			let wc = scanForFirstNonspace(startingAtIndex: i+7)
			
			guard wc > i+7 else { return false }
			
			return true
		}
		
		return false
	}
	
	public func scanForSceneHeading(atIndex i: Int) -> Bool {
		guard endOfLineCharNumber > i + 5 else {
			return false
		}
		
		
		if (data[i] == 0x0053 || data[i] == 0x0073) &&
			(data[i+1] == 0x0063 || data[i+1] == 0x0043) &&
			(data[i+2] == 0x0065 || data[i+2] == 0x0045) &&
			(data[i+3] == 0x006e || data[i+3] == 0x004e) &&
			(data[i+4] == 0x0065 || data[i+4] == 0x0045) {	// 'S', 'c', 'e', 'n', 'e' case insensititve
			let wc = scanForFirstNonspace(startingAtIndex: i+5)
			
			guard wc > i+5 else { return false }
			
			return true
		}
		
		return false
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "//" and any additional "/", [1] covers whitespace (if any)
	public func scanForComment(atIndex i: Int) -> [SearchResult]? {
		var result1 = SearchResult(startIndex: i, endIndex: i)
		
		var j = i
		var state = 0
		var matched = false
		var breakingStatement = false
		while j < endOfLineCharNumber {
			let c = data[j]
			
			switch state {
			case 0:
				
				if c == 0x002f { // '/'
					state = 1
				} else {
					return nil
				}
				
			case 1:
				
				if c == 0x002f { // '/'
					matched = true
					result1.endIndex = j+1
					state = 2
				} else {
					return nil
				}
				
			case 2:
				
				if c == 0x002f { // '/'
					result1.endIndex = j+1
					break
				} else {
					breakingStatement = true
				}
				
			default:
				return nil
			}
			
			if breakingStatement {
				break
			}
			
			j += 1
		}
		
		if matched {
			let wc = scanForFirstNonspace(startingAtIndex: j)
			let result2 = SearchResult(startIndex: j, endIndex: wc)
			return [result1, result2]
		}
		
		return nil
	}
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - returns: Result covers "~"
	public func scanForLyricPrefix(atIndex i: Int) -> SearchResult? {
		guard endOfLineCharNumber > i else {
			return nil
		}
		
		if data[i] == 0x007e {	// '~'
			return SearchResult(startIndex: i, endIndex: i+1)
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "^", [1] covers Cue name, [2] covers ":" and any whitespace
	public func scanForDualCue(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 2 else {
			return nil
		}
		
		if data[i] == 0x005e {	// '^'
			guard let result2 = scanForCue(atIndex: i+1) else {
				return nil
			}
			
			let result1 = SearchResult(startIndex: i, endIndex: i+1)
			var results = [result1]
			results.append(contentsOf: result2)
			return results
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers Cue name, [1] covers ":" and any whitespace
	public func scanForCue(atIndex i: Int) -> [SearchResult]? {
		var j = i
		var state = 0
		var matched = false
		while j < endOfLineCharNumber {
			
			switch state {
			case 0:
				// initial state
				if data[j] != 0x003a { // not ':'
					state = 1
				} else {
					return nil
				}
				
			case 1:
				// find colon
				if data[j] == 0x003a { // ':'
					matched = true
				} else if j-i > 22 { // cue can not be > 24 (23 chars + :)
					return nil
				} else {
					state = 1
				}
				
			default:
				return nil
			}
			
			if matched {
				let result1 = SearchResult(startIndex: i, endIndex: j)
				let wc = scanForFirstNonspace(startingAtIndex: j+1)
				let result2 = SearchResult(startIndex: result1.endIndex, endIndex: wc)
				
				return [result1, result2]
			}
			
			j += 1
		}
		
		return nil
	}
	
}
