//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public class Cue {
	
	public typealias Index = Int
	
	var data: [UInt16]
	
	var root: Document
	
	var lineNumber = 0
	
	var charNumber: Index
	
	var endOfLineCharNumber: Index
	
	public init(_ input: [UInt16]) {
		self.data = input
		self.charNumber = data.startIndex
		self.endOfLineCharNumber = data.endIndex
		self.root = Document(range: charNumber..<endOfLineCharNumber)
		
		parseBlocks()
	}
	
	public convenience init(_ string: String) {
		let bytes = [UInt16](string.utf16)
		self.init(bytes)
	}
	
}

// MARK: - Views
extension Cue {
	
	public var ast: Document {
		return root
	}
	
	public var tableOfContents: [TableOfContentsItem] {
		return TableOfContents(self).contents
	}
	
//	public var namedEntitiesDictionary: [String: Array<Index>] {
//		return NamedEntities(self).map
//	}
	
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
				endOfLineCharNumber = data.index(after: endOfLineCharNumber)
				if scanForLineEnding(at: backtrack) {
					break
				}
			}
			
			lineNumber += 1
			
			processLine()
			
			charNumber = endOfLineCharNumber
		}
		
	}
	
	func processLine() {
		// First we parse the current line as a block node.
		var block = blockForLine()
		block.lineNumber = lineNumber
		
		// Then we try to find an appropriate container node. If none can be found, block will be replaced.
		let container = appropriateContainer(for: &block)
		container.addChild(block)
		
		// Only now can we parse first-line lyrics, because appropriateContainer() may have changed the current block
		if let cueBlock = block as? CueBlock {
			guard let content = cueBlock.content as? TextStream else {
				return
			}
			
			if let result = scanForLyricPrefix(at: content.range.lowerBound) {
				let lyricContainer = LyricContainer(range: result.range.lowerBound..<endOfLineCharNumber)
				let lyricBlock = LyricBlock(start: result.range, content: result.range.upperBound..<endOfLineCharNumber)
				lyricContainer.addChild(lyricBlock)
				
				cueBlock.content = lyricContainer
				
				// Lyrics are deeply nested. We may as well parse their inlines now rather than add an edge case later.
				let stream = lyricBlock.textStream
				parseInlines(for: stream, startingAt: result.range.upperBound)
			}
		}
		
		// Parse TextStream into a stream of inlines. Except for in deeply nested nodes, TextStream, if present, will always be the last child of the current block.
		if let stream = block.children.last as? TextStream {
			parseInlines(for: stream, startingAt: stream.range.lowerBound)
		}
	}
	
	func blockForLine() -> AbstractNode {
		let wc = scanForFirstNonspace(startingAt: charNumber)
		
		// FIXME: Handle edge cases and provide syntactic sugar
		if let header = scanForHeading(at: wc) {
			return header
		} else if scanForTheEnd(at: wc) {
			let end = EndBlock(range: charNumber..<endOfLineCharNumber)
			
			return end
		} else if let result = scanForFacsimile(at: wc) {
			let facsimile = FacsimileBlock(start: result.range, content: result.range.upperBound..<endOfLineCharNumber)
			
			return facsimile
		} else if let result = scanForLyricPrefix(at: wc) {
			let lyric = LyricBlock(start: result.range, content: result.range.upperBound..<endOfLineCharNumber)
			
			return lyric
		} else if let cueBlock = scanForDualCue(at: wc) {
			return cueBlock
		}
		
		let description = DescriptionBlock(range: charNumber..<endOfLineCharNumber)
		return description
	}
	
	func appropriateContainer(for block: inout AbstractNode) -> AbstractContainer {
		switch block {
		// These block types can only ever be level-1
		case is HeaderBlock, is DescriptionBlock, is EndBlock:
			return root
			
		// A CueBlock is always level-2, but regular cues need their own initial parent CueContainer
		case is CueBlock:
			if (block as! CueBlock).isRegular {
				let cueContainer = CueContainer(range: block.range)
				root.addChild(cueContainer)
				return cueContainer
			} else if let cueContainer = root.children.last as? CueContainer {
				return cueContainer
			}
			
		// FacsimileBlocks are also always level-2
		case is FacsimileBlock:
			// If last child of root is a FacsimileContainer and the current block is a FacsimileBlock, then attach the current block to this container
			if let facsimileContainer = root.children.last as? FacsimileContainer {
				return facsimileContainer
			}
			
			// First line. Initialize new container
			let facsimileContainer = FacsimileContainer(range: block.range)
			root.addChild(facsimileContainer)
			return facsimileContainer
			
		// Lyric Blocks are always level-4. Any LyricBlock that comes to us at this point is guaranteed to be not be a first line so we can ignore that edge case
		case is LyricBlock:
			guard let cueContainer = root.children.last as? CueContainer  else { break }
			
			guard let cueBlock = cueContainer.children.last as? CueBlock else { break }
			
			guard let content = cueBlock.content as? LyricContainer else { break }
			
			return content
		default:
			break
		}
		
		// Invalid syntax, time to fail gracefully
		block = DescriptionBlock(range: charNumber..<endOfLineCharNumber)
		return root
	}
	
}

// MARK: - Inline Parsing
extension Cue {
	
	func parseInlines(for stream: TextStream, startingAt i: Int) {
		var spans = InlineCollection()
		
		var stack = [InlineMarker]()
		
		var j = i
		var foundBreakingStatement = false
		while j < endOfLineCharNumber {
			let c = data[j]
			
			let k = data.index(after: j)
			switch c {
			case UTF16.asterisk:
				let marker = InlineMarker(type: .asterisk, range: j..<k)
				
				guard let last = stack.last else {
					stack.append(marker)
					break
				}
				
				if last.type == marker.type {
					stack.removeLast()
					
					guard last.range.upperBound < marker.range.lowerBound else { break }
					
					let em = Emphasis(start: last.range, stop: marker.range)
					spans.push(em)
					break
				}
				
				fatalError("Uknown state when parsing emphasis")
				
			case UTF16.leftBracket:
				let marker = InlineMarker(type: .openBracket, range: j..<k)
				
				guard let last = stack.last else {
					stack.append(marker)
					break
				}
				
				guard last.type != .openBracket else { break }
				
				stack.append(marker)
				
			case UTF16.rightBracket:
				let marker = InlineMarker(type: .closeBracket, range: j..<k)
				
				guard let last = stack.last else {
					stack.append(marker)
					break
				}
				
				if last.type == .openBracket {
					stack.removeLast()
					
					guard last.range.upperBound < marker.range.lowerBound else { break }
					
					let ref = Reference(start: last.range, stop: marker.range)
					spans.push(ref)
					break
				}
				
				fatalError("Unknown state when parsing reference")
				
			case UTF16.slash:
				guard k < endOfLineCharNumber else { break }
				
				if data[k] == UTF16.slash {
					let com = Comment(range: j..<endOfLineCharNumber)
					spans.push(com)
					foundBreakingStatement = true
				}
			default:
				break
			}
			
			if foundBreakingStatement { break }
			
			j = k
		}
		
		guard !spans.isEmpty else { return }
		
		j = i
		
		// Run through spans
		for span in spans {
			// Any space between spans should be Literal
			if span.range.lowerBound > j {
				let lit = Literal(range: j..<span.range.lowerBound)
				stream.addChild(lit)
			}
			
			stream.addChild(span)
			
			j = span.range.upperBound
		}
		
		// Add any reaming text as literal
		if j < endOfLineCharNumber {
			let lit = Literal(range: j..<endOfLineCharNumber)
			stream.addChild(lit)
		}
	}
	
}

// MARK: - Scanners
extension Cue {
	
	func scanForLineEnding(at i: Index) -> Bool {
		let c = data[i]
		
		return c == UTF16.linefeed || c == UTF16.carriage
	}
	
	func scanForWhitespace(at i: Index) -> Bool {
		let c = data[i]
		
		return c == UTF16.space || c == UTF16.tab || scanForLineEnding(at: i)
	}
	
	func scanForFirstNonspace(startingAt i: Index) -> Index {
		var j = i
		
		while j < endOfLineCharNumber {
			if scanForWhitespace(at: j) {
				j = data.index(after: j)
			} else {
				break
			}
		}
		
		return j
	}
	
	func scanForHyphen(startingAt i: Index) -> Index {
		var j = i
		
		while j < endOfLineCharNumber {
			if data[j] == UTF16.hyphen {
				break
			} else {
				j = data.index(after: j)
			}
		}
		
		return j
	}
	
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers the keyword, [1] covers whitespace, [2] covers the id, [3-4] covers the hyphen and title if present.
	func scanForHeading(at i: Index) -> HeaderBlock? {
		var type: HeaderBlock.HeaderType
		var j = i
		
		if scanForActHeading(at: i) {
			type = .act
			j = data.index(j, offsetBy: 3)
		} else if scanForSceneHeading(at: i) {
			type = .scene
			j = data.index(j, offsetBy: 5)
		} else if scanForChapterHeading(at: i) {
			type = .chapter
			j = data.index(j, offsetBy: 7)
		} else if scanForPage(at: i) {
			type = .page
			j = data.index(j, offsetBy: 4)
		} else {
			return nil
		}
		let keyRange: Range<Index> = i..<j
		
		let k = scanForFirstNonspace(startingAt: j)
		guard k < endOfLineCharNumber else { return nil }
		
		var l = scanForHyphen(startingAt: k)
		let m = data.index(after: l)
		while scanForWhitespace(at: data.index(before: l)), l > i {
			l = data.index(before: l)
		}
		let idRange: Range<Index> = k..<l
		
		var nameRange: (Range<Index>, Range<Index>)? = nil
		if m < endOfLineCharNumber {
			let n = scanForFirstNonspace(startingAt: m)
			let hyphenRange: Range<Index> = l..<n
			let titleRange: Range<Index> = n..<endOfLineCharNumber
			nameRange = (hyphenRange, titleRange)
		}
		
		return HeaderBlock(type: type, keyword: keyRange, identifier: idRange, name: nameRange)
	}
	
	func scanForActHeading(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 3) < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if data[j] == UTF16.A {
			j = data.index(after: j)
			if data[j] == UTF16.c {
				j = data.index(after: j)
				if data[j] == UTF16.t {
					return true
				}
			}
		}
		
		return false
	}
	
	func scanForChapterHeading(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 7) < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if data[j] == UTF16.C {
			j = data.index(after: j)
			if data[j] == UTF16.h {
				j = data.index(after: j)
				if data[j] == UTF16.a {
					j = data.index(after: j)
					if data[j] == UTF16.p {
						j = data.index(after: j)
						if data[j] == UTF16.t {
							j = data.index(after: j)
							if data[j] == UTF16.e {
								j = data.index(after: j)
								if data[j] == UTF16.r {
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
	
	func scanForSceneHeading(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 5) < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if data[j] == UTF16.S {
			j = data.index(after: j)
			if data[j] == UTF16.c {
				j = data.index(after: j)
				if data[j] == UTF16.e {
					j = data.index(after: j)
					if data[j] == UTF16.n {
						j = data.index(after: j)
						if data[j] == UTF16.e {
							return true
						}
					}
				}
			}
		}
		
		return false
	}
	
	func scanForPage(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 4) < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if data[j] == UTF16.P {
			j = data.index(after: j)
			if data[j] == UTF16.a {
				j = data.index(after: j)
				if data[j] == UTF16.g {
					j = data.index(after: j)
					if data[j] == UTF16.e {
						return true
					}
				}
			}
		}
		
		return false
	}
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - Returns: Result covers ">" and any whitespace
	func scanForFacsimile(at i: Index) -> SearchResult? {
		guard i < endOfLineCharNumber  else {
			return nil
		}
		
		if data[i] == UTF16.rightAngle { // ">"
			let j = scanForFirstNonspace(startingAt: data.index(after: i))
			
			return SearchResult(range: i..<j)
		}
		
		return nil
	}
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - returns: Result covers "~"
	func scanForLyricPrefix(at i: Index) -> SearchResult? {
		guard i < endOfLineCharNumber else {
			return nil
		}
		
		if data[i] == UTF16.tilde {	// '~'
			return SearchResult(range: i..<data.index(after: i))
		}
		
		return nil
	}
	
	func scanForDualCue(at i: Index) -> CueBlock? {
		let j = data.index(after: i)
		
		guard j < endOfLineCharNumber else {
			return nil
		}
		
		var del: Range<Index>? = nil
		if data[i] == UTF16.caret {	// '^'
			del = i..<j
		}
		
		guard let cueResults = scanForCue(at: j) else { return nil }
		
		return CueBlock(start: del, name: cueResults[0].range, space: cueResults[1].range, content: cueResults[1].range.lowerBound..<endOfLineCharNumber)
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers Cue name, [1] covers ":" and any whitespace
	func scanForCue(at i: Index) -> [SearchResult]? {
		var j = i
		var state = 0
		var matched = false
		var distance = 0
		while j < endOfLineCharNumber {
			
			switch state {
			case 0:
				// initial state
				if data[j] != UTF16.colon && data[j] != UTF16.leftBracket { // not ':' or '['
					state = 1
				} else {
					return nil
				}
				
			case 1:
				// find colon
				if data[j] == UTF16.colon { // ':'
					matched = true
				} else if distance >= 23 || data[j] == UTF16.leftBracket { // cue can not be > 24 (23 chars + :), and should not contain brackets.
					return nil
				} else {
					state = 1
				}
				
			default:
				return nil
			}
			
			if matched {
				let result1 = SearchResult(range: i..<j)
				let wc = scanForFirstNonspace(startingAt: data.index(after: j))
				let result2 = SearchResult(range: result1.range.upperBound..<wc)
				
				return [result1, result2]
			}
			
			j = data.index(after: j)
			distance += 1
		}
		
		return nil
	}
	
	func scanForTheEnd(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 7) == data.endIndex else {
			return false
		}
		
		// 'T', 'h', 'e', ' ', 'E', 'n', 'd'
		var j = i
		if data[j] == UTF16.T {
			j = data.index(after: j)
			if data[j] == UTF16.h {
				j = data.index(after: j)
				if data[j] == UTF16.e {
					j = data.index(after: j)
					if data[j] == UTF16.space {
						j = data.index(after: j)
						if data[j] == UTF16.E {
							j = data.index(after: j)
							if data[j] == UTF16.n {
								j = data.index(after: j)
								if data[j] == UTF16.d {
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
