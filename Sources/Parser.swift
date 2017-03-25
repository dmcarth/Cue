//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public final class Cue {
	
	public typealias Index = Int
	
	typealias C = UTF16
	
	let data: [UInt16]
	
	let root: Document
	
	var lineNumber = 0
	
	var charNumber: Index
	
	var endOfLineCharNumber: Index
	
	public init(_ str: String) {
		self.data = [UInt16](str.utf16)
		self.charNumber = data.startIndex
		self.endOfLineCharNumber = data.endIndex
		self.root = Document(range: charNumber..<endOfLineCharNumber)
		
		parseBlocks()
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
	
	public var namedEntitiesDictionary: [String: Array<Index>] {
		return NamedEntities(self).map
	}
	
	public func html() -> String {
		return HTMLMarkupRenderer(parser: self).output
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
		
		// Then we try to find an appropriate container node. If none can be found, block will be replaced.
		let container = appropriateContainer(for: &block)
		container.addChild(block)
		
		// Only now can we parse first-line lyrics, because appropriateContainer() may have changed the current block
		if let cueBlock = block as? CueBlock {
			if let result = scanForLyricPrefix(at: cueBlock.direction.range.lowerBound) {
				let lyricContainer = LyricContainer(range: result.range.lowerBound..<endOfLineCharNumber)
				let lyricBlock = LyricBlock(left: result.range, body: result.range.upperBound..<endOfLineCharNumber)
				lyricContainer.addChild(lyricBlock)
				
				cueBlock.direction.children = [lyricContainer]
				
				// Lyrics are deeply nested. We may as well parse their inlines now rather than add an edge case later.
				parseInlines(for: lyricBlock)
			}
		}
		
		// Parse inlines as appropriate
		switch block {
		case is FacsimileBlock, is Description, is LyricBlock:
			parseInlines(for: block)
		case let header as Header:
			if let title = header.title {
				parseInlines(for: title)
			}
		case let cue as CueBlock:
			let direction = cue.direction
			if direction.children.isEmpty {
				parseInlines(for: direction)
			}
		default:
			break
		}
	}
	
	func blockForLine() -> Node {
		let wc = scanForFirstNonspace(startingAt: charNumber)
		
		if let header = scanForHeading(at: wc) {
			
			return header
		} else if scanForTheEnd(at: wc) {
			let end = EndBlock(range: charNumber..<endOfLineCharNumber)
			
			return end
		} else if let result = scanForFacsimile(at: wc) {
			let facsimile = FacsimileBlock(left: charNumber..<result.range.upperBound, body: result.range.upperBound..<endOfLineCharNumber)
			
			return facsimile
		} else if let result = scanForLyricPrefix(at: wc) {
			let lyricBlock = LyricBlock(left: charNumber..<result.range.upperBound, body: result.range.upperBound..<endOfLineCharNumber)
			
			return lyricBlock
		} else if let cueBlock = scanForDualCue(at: wc) {
			return cueBlock
		}
		
		let description = Description(range: charNumber..<endOfLineCharNumber)
		return description
	}
	
	func appropriateContainer(for block: inout Node) -> Node {
		switch block {
		// These block types can only ever be level-1
		case is Header, is Description, is EndBlock:
			return root
			
		// A CueBlock is always level-2, but regular cues need their own initial parent CueContainer
		case is CueBlock:
			if !(block is DualCue) {
				let cueContainer = CueContainer(range: block.rangeIncludingMarkers)
				root.addChild(cueContainer)
				
				return cueContainer
			} else if let last = root.children.last as? CueContainer {
				last.extendLengthToInclude(node: block)
				return last
			}
			
		// FacsimileBlocks are also always level-2
		case is FacsimileBlock:
			// If last child of root is a FacsimileContainer and the current block is a FacsimileBlock, then attach the current block to this container
			if let last = root.children.last as? FacsimileContainer {
				last.extendLengthToInclude(node: block)
				return last
			}
			
			// First line. Initialize new container
			let facsimileContainer = FacsimileContainer(range: block.rangeIncludingMarkers)
			root.addChild(facsimileContainer)
			
			return facsimileContainer
			
		// Lyric Blocks are always level-4. Any LyricBlock that comes to us at this point is guaranteed not to be a first line so we can ignore that edge case
		case is LyricBlock:
			guard let cueContainer = root.children.last as? CueContainer else { break }
			
			guard let cueBlock = cueContainer.children.last as? CueBlock else { break }
			
			let direction = cueBlock.direction
			
			guard let content = direction.children.last as? LyricContainer else { break }
			
			content.extendLengthToInclude(node: block)
			direction.extendLengthToInclude(node: content)
			cueBlock.extendLengthToInclude(node: direction)
			cueContainer.extendLengthToInclude(node: cueBlock)
			return content
		default:
			break
		}
		
		// Invalid syntax, time to fail gracefully
		block = Description(range: charNumber..<endOfLineCharNumber)
		return root
	}
	
}

// MARK: - Inline Parsing
extension Cue {
	
	func parseInlines(for stream: Node) {
		let i = stream.range.lowerBound
		
		var queue = Queue<Node>()
		
		var stack = DelimiterStack<Index>()
		
		var j = i
		var foundBreakingStatement = false
		while j < endOfLineCharNumber {
			let c = data[j]
			
			let k = data.index(after: j)
			switch c {
			case C.asterisk:
				let marker = InlineMarker(type: .asterisk, range: j..<k)
				
				if let last = stack.popToOpeningAsterisk() {
					let em = Emphasis(left: last.range, body: last.range.upperBound..<marker.range.lowerBound, right: marker.range)
					queue.enqueue(em)
					break
				}
				
				stack.push(marker)
				
			case C.openBracket:
				let marker = InlineMarker(type: .openBracket, range: j..<k)
				
				stack.push(marker)
				
			case C.closeBracket:
				let marker = InlineMarker(type: .closeBracket, range: j..<k)
				
				if let last = stack.popToOpeningBracket() {
					let ref = Reference(left: last.range, body: last.range.upperBound..<marker.range.lowerBound, right: marker.range)
					queue.enqueue(ref)
					break
				}
				
			case C.slash:
				guard k < endOfLineCharNumber else { break }
				
				if data[k] == C.slash {
					let l = data.index(after: k)
					let com = Comment(left: j..<l, body: l..<endOfLineCharNumber)
					queue.enqueue(com)
					foundBreakingStatement = true
				}
				
			default:
				break
			}
			
			if foundBreakingStatement { break }
			
			j = k
		}
		
		j = i
		
		while let next = queue.dequeue() {
			let nextRange = next.rangeIncludingMarkers
			
			if nextRange.lowerBound > j {
				let lit = Literal(range: j..<nextRange.lowerBound)
				stream.addChild(lit)
			}
			
			stream.addChild(next)
			
			j = nextRange.upperBound
		}
		
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
		
		return c == C.linefeed || c == C.carriage
	}
	
	func scanForWhitespace(at i: Index) -> Bool {
		let c = data[i]
		
		return c == C.space || c == C.tab || scanForLineEnding(at: i)
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
			if data[j] == C.hyphen {
				break
			} else {
				j = data.index(after: j)
			}
		}
		
		return j
	}
	
	func scanForHeading(at i: Index) -> Node? {
		var type: Header.HeaderType
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
		
		let key = Keyword(range: keyRange)
		let id = Identifier(range: idRange)
		
		var title: Title? = nil
		if m < endOfLineCharNumber {
			let n = scanForFirstNonspace(startingAt: m)
			let hyphenRange: Range<Index> = l..<n
			let titleRange: Range<Index> = n..<endOfLineCharNumber
			
			title = Title(left: hyphenRange, body: titleRange)
		}
		
		let header = Header(type: type, keyword: key, identifier: id, title: title)
		return header
	}
	
	func scanForActHeading(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 3) < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if data[j] == C.A {
			j = data.index(after: j)
			if data[j] == C.c {
				j = data.index(after: j)
				if data[j] == C.t {
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
		if data[j] == C.C {
			j = data.index(after: j)
			if data[j] == C.h {
				j = data.index(after: j)
				if data[j] == C.a {
					j = data.index(after: j)
					if data[j] == C.p {
						j = data.index(after: j)
						if data[j] == C.t {
							j = data.index(after: j)
							if data[j] == C.e {
								j = data.index(after: j)
								if data[j] == C.r {
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
		if data[j] == C.S {
			j = data.index(after: j)
			if data[j] == C.c {
				j = data.index(after: j)
				if data[j] == C.e {
					j = data.index(after: j)
					if data[j] == C.n {
						j = data.index(after: j)
						if data[j] == C.e {
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
		if data[j] == C.P {
			j = data.index(after: j)
			if data[j] == C.a {
				j = data.index(after: j)
				if data[j] == C.g {
					j = data.index(after: j)
					if data[j] == C.e {
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
		
		if data[i] == C.rightAngle { // ">"
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
		
		if data[i] == C.tilde {	// '~'
			return SearchResult(range: i..<data.index(after: i))
		}
		
		return nil
	}
	
	func scanForDualCue(at i: Index) -> Node? {
		let j = data.index(after: i)
		
		guard j < endOfLineCharNumber else {
			return nil
		}
		
		var del: Range<Index>? = nil
		if data[i] == C.caret {	// '^'
			del = i..<j
		}
		
		guard let cueResults = scanForCue(at: del?.upperBound ?? i) else { return nil }
		
		let name = Name(body: cueResults[0].range, right: cueResults[1].range)
		let direction = Direction(range: cueResults[1].range.upperBound..<endOfLineCharNumber)
		
		var cue: CueBlock
		if let del = del {
			cue = DualCue(left: del, name: name, direction: direction)
		} else {
			cue = CueBlock(name: name, direction: direction)
		}
		
		return cue
	}
	
	func scanForCue(at i: Index) -> [SearchResult]? {
		var j = i
		var distance = 0
		while j < endOfLineCharNumber {
			let c = data[j]
			
			guard distance <= 24 else { break }
			
			if c == C.colon {
				let nameResult = SearchResult(range: i..<j)
				let k = scanForFirstNonspace(startingAt: data.index(after: j))
				let colonResult = SearchResult(range: j..<k)
				return [nameResult, colonResult]
			} else if c == C.openBracket {
				break
			}
			
			distance += 1
			j = data.index(after: j)
		}
		
		return nil
	}
	
	func scanForTheEnd(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 7) == data.endIndex else {
			return false
		}
		
		var j = i
		if data[j] == C.T {
			j = data.index(after: j)
			if data[j] == C.h {
				j = data.index(after: j)
				if data[j] == C.e {
					j = data.index(after: j)
					if data[j] == C.space {
						j = data.index(after: j)
						if data[j] == C.E {
							j = data.index(after: j)
							if data[j] == C.n {
								j = data.index(after: j)
								if data[j] == C.d {
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
