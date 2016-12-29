//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public struct CueParser {
	
	var data = [UInt16]()
	
	var root = Document()
	
	var lineNumber = 0
	
	var charNumber = 0
	
	var endOfLineCharNumber = 0
	
	public init(_ string: String) {
		let bytes = [UInt16](string.utf16)
		data = bytes
		
		// useful for debugging
		endOfLineCharNumber = data.count
	}
	
	public static func parse(_ string: String) -> Node {
		var parser = CueParser(string)
		return parser.parse()
	}
	
	public mutating func parse() -> Node {
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
	
	mutating func parseBlocks() {
		// Enumerate lines
		while charNumber < data.count {
			// Find line ending
			endOfLineCharNumber = charNumber
			while endOfLineCharNumber < data.count {
				endOfLineCharNumber += 1
				if scanForLineEnding(at: endOfLineCharNumber-1) {
					break
				}
			}
			
			lineNumber += 1
			
			processLine()
			
			charNumber = endOfLineCharNumber
		}
		
		root.endIndex = data.count
	}
	
	mutating func processLine() {
		// First we parse the current line as a block node and then we try to find an appropriate container node. If none can be found, we'll just assume the current line is description.
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
			
			if let result = scanForLyricPrefix(at: last.startIndex) {
				let lyb = LyricBlock(startIndex: result.startIndex, endIndex: endOfLineCharNumber)
				let ly = Lyric(startIndex: result.startIndex, endIndex: endOfLineCharNumber, result: result)
				lyb.addChild(ly)
				
				// Lyrics are deeply nested. It's easier to  parse them now instead of adding an edge case later.
				parseInlines(for: ly, startingAt: result.endIndex)
				
				cb.removeLastChild()
				cb.addChild(lyb)
			}
		}
		
		// Parse RawText into a stream of inlines. Excepting deeply nested nodes, RawText will always be the last child at this stage
		if let raw = block.children.last as? RawText {
			parseInlines(for: block, startingAt: raw.startIndex)
		}
	}
	
	func blockForLine() -> Block {
		let wc = scanForFirstNonspace(startingAt: charNumber)
		
		if let results = scanForHeading(at: wc) {
			let he = Heading(startIndex: wc, endIndex: endOfLineCharNumber, results: results)
			
			return he
		} else if scanForTheEnd(at: wc) {
			let en = EndBlock(startIndex: wc, endIndex: endOfLineCharNumber, offset: 0)
			
			return en
		} else if let result = scanForComment(at: wc) {
			let com = CommentBlock(startIndex: charNumber, endIndex: endOfLineCharNumber, results: result)
			
			return com
		} else if let result = scanForFacsimile(at: wc) {
			let cit = Facsimile(startIndex: charNumber, endIndex: endOfLineCharNumber, result: result)
			
			return cit
		} else if let result = scanForLyricPrefix(at: wc) {
			let ly = Lyric(startIndex: charNumber, endIndex: endOfLineCharNumber, result: result)
			
			return ly
		} else if let result = scanForDualCue(at: wc) {
			let du = DualCue(startIndex: charNumber, endIndex: endOfLineCharNumber, results: result)
			
			return du
		} else if let result = scanForCue(at: wc) {
			let cu = RegularCue(startIndex: charNumber, endIndex: endOfLineCharNumber, results: result)
			
			return cu
		}
		
		let des = Description(startIndex: charNumber, endIndex: endOfLineCharNumber)
		return des
	}
	
	func appropriateContainer(for block: inout Block) -> Node {
		var container: Node = root
		
		switch block {
		// These block types can only ever be level-1
		case is Heading, is EndBlock, is Description, is CommentBlock:
			return root
		// A RegularCue is always level-2, with it's own initial parent CueBlock
		case is RegularCue:
			let cueBlockContainer = CueBlock(startIndex: block.startIndex, endIndex: block.endIndex)
			root.addChild(cueBlockContainer)
			return cueBlockContainer
		// The same is true for the first line of a facsimile.
		case is Facsimile:
			// But the only way to know if this is a new line is to check the lastChild of the root, if present.
			if let lastChild = root.children.last {
				if lastChild is FacsimileBlock { break }
			}
			
			// First line. Initialize new container
			let facsimileBlockContainer = FacsimileBlock(startIndex: block.startIndex, endIndex: block.endIndex)
			root.addChild(facsimileBlockContainer)
			return facsimileBlockContainer
		default:
			break
		}
		
		// If none of those predetermined cases match, iterate down the tree, checking each lastchild in succession
		while let lastChild = container.children.last {
			container = lastChild
			
			var foundBreakingStatement = false
			
			// If we're going to be adding the block to a deeply nested container, ensure that the container's parents are resized to include the new block.
			switch container {
			case is FacsimileBlock:
				if block is Facsimile {
					return container
				}
			case is CueBlock:
				if block is DualCue {
					container.parent!.endIndex = block.endIndex
					return container
				}
				break
			case is LyricBlock:
				if block is Lyric {
					container.parent!.endIndex = block.endIndex
					container.parent!.parent!.endIndex = block.endIndex
					return container
				}
				break
			case is RegularCue, is DualCue:
				if block is Lyric {
					break // To drop down the tree
				}
				fallthrough
			default:
				// Invalid syntax, time to fail gracefully
				foundBreakingStatement = true
			}
			
			if foundBreakingStatement { break }
			
		}
		
		block = Description(startIndex: charNumber, endIndex: endOfLineCharNumber)
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
	
	public func scanForLineEnding(at i: Int) -> Bool {
		let c = data[i]
		
		return c == 0x000a || c == 0x000d // '\n', '\r'
	}
	
	public func scanForWhitespace(at i: Int) -> Bool {
		let c = data[i]
		
		// ' ', '\t', newline
		return c == 0x0020 || c == 0x0009 || scanForLineEnding(at: i)
	}
	
	public func scanForFirstNonspace(startingAt i: Int) -> Int {
		var j = i
		
		while j < endOfLineCharNumber {
			if scanForWhitespace(at: j) {
				j += 1
			} else {
				break
			}
		}
		
		return j
	}
	
	public func scanForHyphen(startingAt i: Int) -> Int {
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
	public func scanForHeading(at i: Int) -> [SearchResult]? {
		var type: Keyword.KeywordType
		var j = i
		
		if scanForActHeading(at: i) {
			type = .act
			j += 3
		} else if scanForSceneHeading(at: i) {
			type = .scene
			j += 5
		} else if scanForChapterHeading(at: i) {
			type = .chapter
			j += 7
		} else {
			return nil
		}
		let keyResult = SearchResult(startIndex: i, endIndex: j, keywordType: type)
		
		
		let k = scanForFirstNonspace(startingAt: j)
		guard k < endOfLineCharNumber else {
			return nil
		}
		let wResult = SearchResult(startIndex: j, endIndex: k)
		
		let l = scanForHyphen(startingAt: k)
		let idResult = SearchResult(startIndex: k, endIndex: l)
		
		var results = [keyResult, wResult, idResult]
		
		if l < endOfLineCharNumber {
			let m = scanForFirstNonspace(startingAt: l+1)
			let hResult = SearchResult(startIndex: l, endIndex: m)
			let titleResult = SearchResult(startIndex: m, endIndex: endOfLineCharNumber)
			results.append(contentsOf: [hResult, titleResult])
		}
		
		return results
	}
	
	public func scanForActHeading(at i: Int) -> Bool {
		guard endOfLineCharNumber > i + 3 else {
			return false
		}
		
		if (data[i] == 0x0041 || data[i] == 0x0061) &&
			(data[i+1] == 0x0063 || data[i+1] == 0x0043) &&
			(data[i+2] == 0x0074 || data[i+2] == 0x0054) {	// 'A', 'c', 't' case insensitive
			let wc = scanForFirstNonspace(startingAt: i+3)
			
			guard wc > i+3 else { return false }
			
			return true
		}
		
		return false
	}
	
	public func scanForChapterHeading(at i: Int) -> Bool {
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
			let wc = scanForFirstNonspace(startingAt: i+7)
			
			guard wc > i+7 else { return false }
			
			return true
		}
		
		return false
	}
	
	public func scanForSceneHeading(at i: Int) -> Bool {
		guard endOfLineCharNumber > i + 5 else {
			return false
		}
		
		
		if (data[i] == 0x0053 || data[i] == 0x0073) &&
			(data[i+1] == 0x0063 || data[i+1] == 0x0043) &&
			(data[i+2] == 0x0065 || data[i+2] == 0x0045) &&
			(data[i+3] == 0x006e || data[i+3] == 0x004e) &&
			(data[i+4] == 0x0065 || data[i+4] == 0x0045) {	// 'S', 'c', 'e', 'n', 'e' case insensititve
			let wc = scanForFirstNonspace(startingAt: i+5)
			
			guard wc > i+5 else { return false }
			
			return true
		}
		
		return false
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "//" and any additional "/", [1] covers whitespace (if any)
	public func scanForComment(at i: Int) -> [SearchResult]? {
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
			let wc = scanForFirstNonspace(startingAt: j)
			let result2 = SearchResult(startIndex: j, endIndex: wc)
			return [result1, result2]
		}
		
		return nil
	}
	
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - Returns: Result covers ">" and any whitespace
	public func scanForFacsimile(at i: Int) -> SearchResult? {
		guard endOfLineCharNumber > i else {
			return nil
		}
		
		if data[i] == 0x003e { // ">"
			let j = scanForFirstNonspace(startingAt: i+1)
			
			return SearchResult(startIndex: i, endIndex: j)
		}
		
		return nil
	}
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - returns: Result covers "~"
	public func scanForLyricPrefix(at i: Int) -> SearchResult? {
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
	public func scanForDualCue(at i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 2 else {
			return nil
		}
		
		if data[i] == 0x005e {	// '^'
			guard let result2 = scanForCue(at: i+1) else {
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
	public func scanForCue(at i: Int) -> [SearchResult]? {
		var j = i
		var state = 0
		var matched = false
		while j < endOfLineCharNumber {
			
			switch state {
			case 0:
				// initial state
				if data[j] != 0x003a && data[j] != 0x005b { // not ':' or '['
					state = 1
				} else {
					return nil
				}
				
			case 1:
				// find colon
				if data[j] == 0x003a { // ':'
					matched = true
				} else if j-i > 22 || data[j] == 0x005b { // cue can not be > 24 (23 chars + :), and should not contain brackets.
					return nil
				} else {
					state = 1
				}
				
			default:
				return nil
			}
			
			if matched {
				let result1 = SearchResult(startIndex: i, endIndex: j)
				let wc = scanForFirstNonspace(startingAt: j+1)
				let result2 = SearchResult(startIndex: result1.endIndex, endIndex: wc)
				
				return [result1, result2]
			}
			
			j += 1
		}
		
		return nil
	}
	
	func scanForTheEnd(at index: Int) -> Bool {
		guard endOfLineCharNumber > index && index + 7 == data.count else {
			return false
		}
		
		if (data[index] == 0x0054 || data[index] == 0x0074) &&
			(data[index+1] == 0x0048 || data[index+1] == 0x0068) &&
			(data[index+2] == 0x0045 || data[index+2] == 0x0065) &&
			(data[index+3] == 0x0020) &&
			(data[index+4] == 0x0045 || data[index+4] == 0x0065) &&
			(data[index+5] == 0x004e || data[index+5] == 0x006e) &&
			(data[index+6] == 0x0044 || data[index+6] == 0x0064) {	// 'T', 'h', 'e', ' ', 'E', 'n', 'd' case insensitive
			return true
		}
		
		return false
	}
	
}
