//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Cue {
	
	var data: String.UTF16View
	
	var flatTableOfContents = [TableOfContentsItem]()
	
	var namedEntities = NamedEntities()
	
	var root: Document
	
	var lineNumber = 0
	
	var charNumber: String.UTF16Index
	
	var endOfLineCharNumber: String.UTF16Index
	
	public init(_ string: String) {
		self.data = string.utf16
		self.charNumber = data.startIndex
		self.endOfLineCharNumber = data.endIndex
		self.root = Document(startIndex: charNumber, endIndex: endOfLineCharNumber)
		
		parseBlocks()
	}
	
	public func ast() -> Document {
		return root
	}
	
	public func tableOfContents() -> [TableOfContentsItem] {
		// TODO: Return a tree of references to header nodes in the ast
		return flatTableOfContents
	}
	
	public func namedEntitiesDictionary() -> [String: Array<String.UTF16Index>] {
		return namedEntities.names
	}
	
}

// MARK: - Block Parsing
extension Cue {
	
	func parseBlocks() {
		// Enumerate lines
		while charNumber < data.endIndex {
			// Find line ending
			endOfLineCharNumber = charNumber
			while endOfLineCharNumber < data.endIndex {
				let backtrack = endOfLineCharNumber
				endOfLineCharNumber.advance(in: data)
				if scanForLineEnding(at: backtrack) {
					break
				}
			}
			
			lineNumber += 1
			
			processLine()
			
			charNumber = endOfLineCharNumber
		}
		
		root.endIndex = endOfLineCharNumber
	}
	
	func processLine() {
		// First we parse the current line as a block node and then we try to find an appropriate container node. If none can be found, we'll just assume the current line is description.
		var block = blockForLine()
		block.lineNumber = lineNumber
		
		let container = appropriateContainer(for: &block)
		container.addChild(block)
		container.startIndex = min(container.startIndex, block.startIndex)
		container.endIndex = max(container.endIndex, block.endIndex)
		
		// Only now can we parse first-line lyrics, because appropriateContainer() may have changed the original block
		if let cb = block as? AbstractCue {
			guard cb.children.last! is RawText else {
				return
			}
			
			let last: Node = cb.children.last!
			
			if let result = scanForLyricPrefix(at: last.startIndex) {
				let lyb = LyricContainer(startIndex: result.startIndex, endIndex: endOfLineCharNumber)
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
			let he = Header(startIndex: wc, endIndex: endOfLineCharNumber, results: results)
			
			let type = TableOfContentsItem.ContentType.init(keyword: results[0].keywordType!)
			let toc = TableOfContentsItem(type: type, location: charNumber)
			flatTableOfContents.append(toc)
			
			return he
		} else if scanForTheEnd(at: wc) {
			let en = EndBlock(startIndex: wc, endIndex: endOfLineCharNumber, offset: wc)
			
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
		} else if let results = scanForDualCue(at: wc) {
			let du = DualCue(startIndex: charNumber, endIndex: endOfLineCharNumber, results: results)
			
			let nameResult = results[1]
			if let name = String(data[nameResult.startIndex..<nameResult.endIndex]) {
				namedEntities.addReference(to: name, at: nameResult.startIndex)
			}
			
			return du
		} else if let results = scanForCue(at: wc) {
			let cu = RegularCue(startIndex: charNumber, endIndex: endOfLineCharNumber, results: results)
			
			let nameResult = results[0]
			if let name = String(data[nameResult.startIndex..<nameResult.endIndex]) {
				namedEntities.addReference(to: name, at: nameResult.startIndex)
			}
			
			return cu
		}
		
		let des = Description(startIndex: charNumber, endIndex: endOfLineCharNumber)
		return des
	}
	
	func appropriateContainer(for block: inout Block) -> Node {
		var container: Node = root
		
		switch block {
		// These block types can only ever be level-1
		case is Header, is EndBlock, is Description, is CommentBlock:
			return container
		// A RegularCue is always level-2, with it's own initial parent CueBlock
		case is RegularCue:
			let cueContainer = CueContainer(startIndex: block.startIndex, endIndex: block.endIndex)
			container.addChild(cueContainer)
			return cueContainer
		// The same is true for the first line of a facsimile.
		case is Facsimile:
			// But the only way to know if this is a new line is to check the lastChild of the root, if present.
			if let lastChild = root.children.last {
				if lastChild is FacsimileContainer { break }
			}
			
			// First line. Initialize new container
			let facsimileContainer = FacsimileContainer(startIndex: block.startIndex, endIndex: block.endIndex)
			container.addChild(facsimileContainer)
			return facsimileContainer
		default:
			break
		}
		
		// If none of those predetermined cases match, iterate down the tree, checking each lastchild in succession
		while let lastChild = container.children.last {
			container = lastChild
			
			var foundBreakingStatement = false
			
			// If we're going to be adding the block to a deeply nested container, ensure that the container's parents are resized to include the new block.
			switch container {
			case is FacsimileContainer:
				if block is Facsimile {
					return container
				}
			case is CueContainer:
				if block is DualCue {
					container.parent!.endIndex = block.endIndex
					return container
				}
				break
			case is LyricContainer:
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
		if let last = flatTableOfContents.last, last.location == charNumber {
			flatTableOfContents.removeLast()
		}
		return root
	}
	
}

// MARK: - Inline Parsing
extension Cue {
	
	func parseInlines(for block: Block, startingAt i: String.UTF16Index) {
		var spans = InlineCollection()
		
		var delimStack = DelimiterStack()
		
		var j = i
		while j < endOfLineCharNumber {
			let c = data[j]
			
			guard c == 0x002a || c == 0x005b || c == 0x005d else {
				j.advance(in: data)
				continue
			}
			
			let del = Delimiter(startIndex: j, endIndex: j.advanced(in: data))
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
					
					let toc = TableOfContentsItem(type: .reference, location: last.endIndex)
					flatTableOfContents.append(toc)
					
					break
				}
				
				fatalError("Unknown state when parsing reference")
			default:
				break
			}
			
			j.advance(in: data)
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
extension Cue {
	
	func scanForLineEnding(at i: String.UTF16Index) -> Bool {
		let c = data[i]
		
		return c == 0x000a || c == 0x000d // '\n', '\r'
	}
	
	func scanForWhitespace(at i: String.UTF16Index) -> Bool {
		let c = data[i]
		
		// ' ', '\t', newline
		return c == 0x0020 || c == 0x0009 || scanForLineEnding(at: i)
	}
	
	func scanForFirstNonspace(startingAt i: String.UTF16Index) -> String.UTF16Index {
		var j = i
		
		while j < endOfLineCharNumber {
			if scanForWhitespace(at: j) {
				j.advance(in: data)
			} else {
				break
			}
		}
		
		return j
	}
	
	func scanForHyphen(startingAt i: String.UTF16Index) -> String.UTF16Index {
		var j = i
		
		while j < endOfLineCharNumber {
			if data[j] == 0x002d {	// '-'
				break
			} else {
				j.advance(in: data)
			}
		}
		
		return j
	}
	
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers the keyword, [1] covers whitespace, [2] covers the id, [3-4] covers the hyphen and title if present.
	func scanForHeading(at i: String.UTF16Index) -> [SearchResult]? {
		var type: Keyword.KeywordType
		var j = i
		
		if scanForActHeading(at: i) {
			type = .act
			j.advance(in: data, by: 3)
		} else if scanForSceneHeading(at: i) {
			type = .scene
			j.advance(in: data, by: 5)
		} else if scanForChapterHeading(at: i) {
			type = .chapter
			j.advance(in: data, by: 7)
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
			let m = scanForFirstNonspace(startingAt: l.advanced(in: data))
			let hResult = SearchResult(startIndex: l, endIndex: m)
			let titleResult = SearchResult(startIndex: m, endIndex: endOfLineCharNumber)
			results.append(contentsOf: [hResult, titleResult])
		}
		
		return results
	}
	
	func scanForActHeading(at i: String.UTF16Index) -> Bool {
		guard i.advanced(in: data, by: 3) < endOfLineCharNumber else {
			return false
		}
		
		// 'A', 'c', 't' case insensitive
		var j = i
		if data[j] == 0x0041 || data[j] == 0x0061 {
			j.advance(in: data)
			if data[j] == 0x0063 || data[j] == 0x0043 {
				j.advance(in: data)
				if data[j] == 0x0074 || data[j] == 0x0054 {
					j.advance(in: data)
					let wc = scanForFirstNonspace(startingAt: j)
					
					guard wc > j else { return false }
					
					return true
				}
			}
		}
		
		return false
	}
	
	func scanForChapterHeading(at i: String.UTF16Index) -> Bool {
		guard i.advanced(in: data, by: 7) < endOfLineCharNumber else {
			return false
		}
		
		// 'C', 'h', 'a', 'p', 't', 'e', 'r' case insensitive
		var j = i
		if data[j] == 0x0043 || data[j] == 0x0063 {
			j.advance(in: data)
			if data[j] == 0x0068 || data[j] == 0x0048 {
				j.advance(in: data)
				if data[j] == 0x0061 || data[j] == 0x0041 {
					j.advance(in: data)
					if data[j] == 0x0070 || data[j] == 0x0050 {
						j.advance(in: data)
						if data[j] == 0x0074 || data[j] == 0x0054 {
							j.advance(in: data)
							if data[j] == 0x0065 || data[j] == 0x0045 {
								j.advance(in: data)
								if data[j] == 0x0072 || data[j] == 0x0052 {
									j.advance(in: data)
									let wc = scanForFirstNonspace(startingAt: j)
									
									guard wc > j else { return false }
									
									return true
								}
							}
						}
					}
				}
			}
		}
		
		return false
	}
	
	func scanForSceneHeading(at i: String.UTF16Index) -> Bool {
		guard i.advanced(in: data, by: 5) < endOfLineCharNumber else {
			return false
		}
		
		
		// 'S', 'c', 'e', 'n', 'e' case insensititve
		var j = i
		if data[j] == 0x0053 || data[j] == 0x0073 {
			j.advance(in: data)
			if data[j] == 0x0063 || data[j] == 0x0043 {
				j.advance(in: data)
				if data[j] == 0x0065 || data[j] == 0x0045 {
					j.advance(in: data)
					if data[j] == 0x006e || data[j] == 0x004e {
						j.advance(in: data)
						if data[j] == 0x0065 || data[j] == 0x0045 {
							j.advance(in: data)
							let wc = scanForFirstNonspace(startingAt: j)
							
							guard wc > j else { return false }
							
							return true
						}
					}
				}
			}
		}
		
		return false
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "//" and any additional "/", [1] covers whitespace (if any)
	func scanForComment(at i: String.UTF16Index) -> [SearchResult]? {
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
					result1.endIndex = j.advanced(in: data)
					state = 2
				} else {
					return nil
				}
				
			case 2:
				
				if c == 0x002f { // '/'
					result1.endIndex = j.advanced(in: data)
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
			
			j.advance(in: data)
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
	func scanForFacsimile(at i: String.UTF16Index) -> SearchResult? {
		guard i < endOfLineCharNumber  else {
			return nil
		}
		
		if data[i] == 0x003e { // ">"
			let j = scanForFirstNonspace(startingAt: i.advanced(in: data))
			
			return SearchResult(startIndex: i, endIndex: j)
		}
		
		return nil
	}
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - returns: Result covers "~"
	func scanForLyricPrefix(at i: String.UTF16Index) -> SearchResult? {
		guard i < endOfLineCharNumber else {
			return nil
		}
		
		if data[i] == 0x007e {	// '~'
			return SearchResult(startIndex: i, endIndex: i.advanced(in: data))
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "^", [1] covers Cue name, [2] covers ":" and any whitespace
	func scanForDualCue(at i: String.UTF16Index) -> [SearchResult]? {
		let j = i.advanced(in: data)
		
		guard j < endOfLineCharNumber else {
			return nil
		}
		
		if data[i] == 0x005e {	// '^'
			guard let result2 = scanForCue(at: j) else {
				return nil
			}
			
			let result1 = SearchResult(startIndex: i, endIndex: j)
			var results = [result1]
			results.append(contentsOf: result2)
			return results
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers Cue name, [1] covers ":" and any whitespace
	func scanForCue(at i: String.UTF16Index) -> [SearchResult]? {
		var j = i
		var state = 0
		var matched = false
		var distance = 0
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
				} else if distance >= 23 || data[j] == 0x005b { // cue can not be > 24 (23 chars + :), and should not contain brackets.
					return nil
				} else {
					state = 1
				}
				
			default:
				return nil
			}
			
			if matched {
				let result1 = SearchResult(startIndex: i, endIndex: j)
				let wc = scanForFirstNonspace(startingAt: j.advanced(in: data))
				let result2 = SearchResult(startIndex: result1.endIndex, endIndex: wc)
				
				return [result1, result2]
			}
			
			j.advance(in: data)
			distance += 1
		}
		
		return nil
	}
	
	func scanForTheEnd(at i: String.UTF16Index) -> Bool {
		guard i.advanced(in: data, by: 7) == data.endIndex else {
			return false
		}
		
		// 'T', 'h', 'e', ' ', 'E', 'n', 'd' case insensitive
		var j = i
		if (data[j] == 0x0054 || data[j] == 0x0074) {
			j.advance(in: data)
			if (data[j] == 0x0048 || data[j] == 0x0068) {
				j.advance(in: data)
				if (data[j] == 0x0045 || data[j] == 0x0065) {
					j.advance(in: data)
					if (data[j] == 0x0020) {
						j.advance(in: data)
						if (data[j] == 0x0045 || data[j] == 0x0065) {
							j.advance(in: data)
							if (data[j] == 0x004e || data[j] == 0x006e) {
								j.advance(in: data)
								if (data[j] == 0x0044 || data[j] == 0x0064) {
									return true
								}
							}
						}
					}
				}
			}
		}
		
		return false
	}
	
}
