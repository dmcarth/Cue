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
			if let lyricBlock = scanForLyric(at: cueBlock.direction.range.lowerBound) {
				let lyricContainer = LyricContainer(range: lyricBlock.range.lowerBound..<endOfLineCharNumber)
				lyricContainer.addChild(lyricBlock)
				
				cueBlock.removeLastChild()
				cueBlock.addChild(lyricContainer)
				cueBlock.direction = lyricContainer
				
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
		
		if let header = scanForHeader(at: wc) {
			
			return header
		} else if let end = scanForTheEnd(at: wc) {
			
			return end
		} else if let facsimile = scanForFacsimile(at: wc) {
			
			return facsimile
		} else if let lyricBlock = scanForLyric(at: wc) {
			
			return lyricBlock
		} else if let cueBlock = scanForDualCue(at: wc) {
			
			return cueBlock
		}
		
		let ewc = scanBackwardForFirstNonspace(startingAt: endOfLineCharNumber)
		
		let description = Description(start: charNumber, body: wc..<ewc, end: endOfLineCharNumber)
		return description
	}
	
	func appropriateContainer(for block: inout Node) -> Node {
		switch block {
		// These block types can only ever be level-1
		case is Header, is Description, is EndBlock:
			return root
			
		// A CueBlock is always level-2, but regular cues need their own initial parent CueContainer
		case let cueBlock as CueBlock:
			if !cueBlock.isDual {
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
		
		let wc = scanForFirstNonspace(startingAt: charNumber)
		let ewc = scanBackwardForFirstNonspace(startingAt: endOfLineCharNumber)
		
		// Invalid syntax, time to fail gracefully
		block = Description(start: charNumber, body: wc..<ewc, end: endOfLineCharNumber)
		return root
	}
	
}

// MARK: - Inline Parsing
extension Cue {
	
	func parseInlines(for stream: Node) {
		let nodeRange = stream.range
		let i = stream.range.lowerBound
		
		var queue = Queue<Node>()
		
		var stack = DelimiterStack<Index>()
		
		var j = i
		var foundBreakingStatement = false
		while j < nodeRange.upperBound {
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
					let com = Comment(left: j..<l, body: l..<nodeRange.upperBound)
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
			let lit = Literal(range: j..<nodeRange.upperBound)
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
	
	func scanBackwardForFirstNonspace(startingAt i: Index) -> Index {
		var j = i
		
		while j > charNumber {
			let backtrack = data.index(before: j)
			
			if scanForWhitespace(at: backtrack) {
				j = backtrack
			} else {
				break
			}
		}
		
		return j
	}
	
	func scanForHeader(at i: Index) -> Header? {
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
		var m = data.index(after: l)
		l = scanBackwardForFirstNonspace(startingAt: l)
		let idRange: Range<Index> = k..<l
		
		let key = Keyword(range: keyRange)
		let id = Identifier(range: idRange)
		
		var title: Title? = nil
		if m < endOfLineCharNumber {
			m = scanForFirstNonspace(startingAt: m)
			let n = scanBackwardForFirstNonspace(startingAt: endOfLineCharNumber)
			let hyphenRange: Range<Index> = l..<m
			let titleRange: Range<Index> = m..<n
			
			title = Title(left: hyphenRange, body: titleRange)
		}
		
		let header = Header(type: type, start: charNumber, keyword: key, identifier: id, title: title, end: endOfLineCharNumber)
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
	
	func scanForFacsimile(at i: Index) -> FacsimileBlock? {
		guard i < endOfLineCharNumber  else {
			return nil
		}
		
		if data[i] == C.rightAngle { // ">"
			let j = scanForFirstNonspace(startingAt: data.index(after: i))
			let k = scanBackwardForFirstNonspace(startingAt: endOfLineCharNumber)
			
			return FacsimileBlock(start: charNumber, body: j..<k, end: endOfLineCharNumber)
		}
		
		return nil
	}
	
	func scanForLyric(at i: Index) -> LyricBlock? {
		guard i < endOfLineCharNumber else {
			return nil
		}
		
		if data[i] == C.tilde {	// '~'
			let j = data.index(after: i)
			let k = scanBackwardForFirstNonspace(startingAt: endOfLineCharNumber)
			
			return LyricBlock(start: charNumber, body: j..<k, end: endOfLineCharNumber)
		}
		
		return nil
	}
	
	func scanForDualCue(at i: Index) -> CueBlock? {
		let j = data.index(after: i)
		
		guard j < endOfLineCharNumber else {
			return nil
		}
		
		var del: Range<Index>? = nil
		if data[i] == C.caret {	// '^'
			del = charNumber..<j
		}
		
		guard let cueResults = scanForCue(at: del?.upperBound ?? i) else { return nil }
		
		let name = Name(body: cueResults[0].range, right: cueResults[1].range)
		let ewc = scanBackwardForFirstNonspace(startingAt: endOfLineCharNumber)
		let direction = DirectionBlock(body: cueResults[1].range.upperBound..<ewc, end: endOfLineCharNumber)
		
		var cue: CueBlock
		if let del = del {
			cue = CueBlock(left: del, isDual: true, name: name, direction: direction)
		} else {
			cue = CueBlock(left: charNumber..<cueResults[0].range.lowerBound, isDual: false, name: name, direction: direction)
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
	
	func scanForTheEnd(at i: Index) -> EndBlock? {
		guard data.index(i, offsetBy: 7) == data.endIndex else {
			return nil
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
									return EndBlock(start: charNumber, body: i..<i+7, end: endOfLineCharNumber)
								}
							}
						}
					}
				}
			}
		}
		
		return nil
	}
	
}
