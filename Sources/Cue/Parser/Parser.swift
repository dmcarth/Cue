//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public final class Cue {
	
	typealias C = UTF16
	
	typealias Buffer = UnsafeBufferPointer<UInt16>
	
	let data: [UInt16]
	
	let root: Document
	
	var lineNumber = 0
	
	var charNumber: Int
	
	var endOfLineCharNumber: Int
	
	public init(_ str: String) {
		self.data = [UInt16](str.utf16)
		self.charNumber = data.startIndex
		self.endOfLineCharNumber = data.endIndex
		self.root = Document(range: charNumber..<endOfLineCharNumber)
		
		self.data.withUnsafeBufferPointer { buffer in
			parseBlocks(in: buffer)
		}
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
	
	public var namedEntitiesDictionary: [String: Array<Int>] {
		return NamedEntities(self).map
	}
	
	public func html() -> String {
		return HTMLMarkupRenderer(parser: self).output
	}
	
}

// MARK: - Block Parsing
extension Cue {
	
	func parseBlocks(in buffer: Buffer) {
		
		// Enumerate lines
		while charNumber < buffer.endIndex {
			// Find line ending
			endOfLineCharNumber = charNumber
			while endOfLineCharNumber < buffer.endIndex {
				let backtrack = endOfLineCharNumber
				endOfLineCharNumber += 1
				if buffer.scanForLineEnding(at: backtrack) {
					break
				}
			}
			
			lineNumber += 1
			
			processLine(in: buffer)
			
			charNumber = endOfLineCharNumber
		}
		
	}
	
	func processLine(in buffer: Buffer) {
		// First we parse the current line as a block node.
		var block = blockForLine(in: buffer)
		
		// Then we try to find an appropriate container node. If none can be found, block will be replaced.
		let container = appropriateContainer(for: &block, in: buffer)
		container.addChild(block)
		
		// Only now can we parse first-line lyrics, because appropriateContainer() may have changed the current block
		if let cueBlock = block as? CueBlock {
			if let lyricBlock = scanForLyric(in: buffer, at: cueBlock.direction.range.lowerBound) {
				let lyricContainer = LyricContainer(range: lyricBlock.range.lowerBound..<endOfLineCharNumber)
				lyricContainer.addChild(lyricBlock)
				
				cueBlock.removeLastChild()
				cueBlock.addChild(lyricContainer)
				cueBlock.direction = lyricContainer
				
				// Lyrics are deeply nested. We may as well parse their inlines now rather than add an edge case later.
				parseInlines(for: lyricBlock, in: buffer)
			}
		}
		
		// Parse inlines as appropriate
		switch block {
		case is FacsimileBlock, is Description, is LyricBlock:
			parseInlines(for: block, in: buffer)
		case let header as Header:
			if let title = header.title {
				parseInlines(for: title, in: buffer)
			}
		case let cue as CueBlock:
			let direction = cue.direction
			if direction.children.isEmpty {
				parseInlines(for: direction, in: buffer)
			}
		default:
			break
		}
	}
	
	func blockForLine(in buffer: Buffer) -> Node {
		let wc = buffer.scanForFirstNonspace(at: charNumber, limit: endOfLineCharNumber)
		
		if let br = scanForBreak(in: buffer, at: wc) {
			
			return br
		} else if let header = scanForHeader(in: buffer, at: wc) {
			
			return header
		} else if let end = scanForTheEnd(in: buffer, at: wc) {
			
			return end
		} else if let facsimile = scanForFacsimile(in: buffer, at: wc) {
			
			return facsimile
		} else if let lyricBlock = scanForLyric(in: buffer, at: wc) {
			
			return lyricBlock
		} else if let cueBlock = scanForDualCue(in: buffer, at: wc) {
			
			return cueBlock
		}
		
		let ewc = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: wc)
		
		let description = Description(start: charNumber, body: wc..<ewc, end: endOfLineCharNumber)
		return description
	}
	
	func appropriateContainer(for block: inout Node, in buffer: Buffer) -> Node {
		switch block {
		// These block types can only ever be level-1
		case is Header, is Description, is EndBlock, is HorizontalBreak:
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
		
		let wc = buffer.scanForFirstNonspace(at: charNumber, limit: endOfLineCharNumber)
		let ewc = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: wc)
		
		// Invalid syntax, time to fail gracefully
		block = Description(start: charNumber, body: wc..<ewc, end: endOfLineCharNumber)
		return root
	}
	
}

// MARK: - Inline Parsing
extension Cue {
	
	func parseInlines(for stream: Node, in buffer: Buffer) {
		let nodeRange = stream.range
		let i = stream.range.lowerBound
		
		var queue = Queue<Node>()
		
		var stack = DelimiterStack()
		
		var j = i
		var foundBreakingStatement = false
		while j < nodeRange.upperBound {
			let c = buffer[j]
			
			let k = j + 1
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
				
				if buffer[k] == C.slash {
					let l = k + 1
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
	
	func scanForBreak(in buffer: Buffer, at i: Int) -> HorizontalBreak? {
		guard i + 3 < endOfLineCharNumber else {
			return nil
		}
		
		var j = i
		var distance = 0
		while j < endOfLineCharNumber {
			if buffer[j] != C.hyphen {
				break
			}
			
			j += 1
			distance += 1
		}
		
		guard distance >= 3, buffer.scanForFirstNonspace(at: j, limit: endOfLineCharNumber) == endOfLineCharNumber else {
			return nil
		}
		
		return HorizontalBreak(range: charNumber..<endOfLineCharNumber)
	}
	
	func scanForHeader(in buffer: Buffer, at i: Int) -> Header? {
		var type: Header.HeaderType
		var j = i
		
		if let h = scanForForcedHeader(in: buffer, at: i) {
			return h
		} else if scanForActHeading(in: buffer, at: i) {
			type = .act
			j += 3
		} else if scanForSceneHeading(in: buffer, at: i) {
			type = .scene
			j += 5
		} else if scanForChapterHeading(in: buffer, at: i) {
			type = .chapter
			j += 7
		} else if scanForPage(in: buffer, at: i) {
			type = .page
			j += 4
		} else {
			return nil
		}
		let keyRange: Range<Int> = i..<j
		
		let k = buffer.scanForFirstNonspace(at: j, limit: endOfLineCharNumber)
		guard k < endOfLineCharNumber else { return nil }
		
		var l = buffer.scanForHyphen(at: k, limit: endOfLineCharNumber)
		var m = l + 1
		l = buffer.scanBackwardForFirstNonspace(at: l, limit: charNumber)
		let idRange: Range<Int> = k..<l
		
		let key = Keyword(range: keyRange)
		let id = Identifier(range: idRange)
		
		var title: Title? = nil
		if m < endOfLineCharNumber {
			m = buffer.scanForFirstNonspace(at: m, limit: endOfLineCharNumber)
			let n = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: m)
			let hyphenRange: Range<Int> = l..<m
			let titleRange: Range<Int> = m..<n
			
			title = Title(left: hyphenRange, body: titleRange)
		}
		
		let header = Header(type: type, start: charNumber, keyword: key, identifier: id, title: title, end: endOfLineCharNumber)
		return header
	}
	
	func scanForForcedHeader(in buffer: Buffer, at i: Int) -> Header? {
		guard i < endOfLineCharNumber, buffer[i] == C.period else { return nil }
		
		let j = i + 1
		var k = j
		while k < endOfLineCharNumber {
			if buffer.scanForWhitespace(at: k) {
				break
			}
			
			k += 1
		}
		let key = Keyword(range: j..<k)
		var id: Identifier? = nil
		var title: Title? = nil
		
		let idStart = buffer.scanForFirstNonspace(at: k, limit: endOfLineCharNumber)
		var hyphenStart = idStart
		var hyphenEnd = idStart
		if idStart < endOfLineCharNumber {
			hyphenStart = buffer.scanForHyphen(at: idStart, limit: endOfLineCharNumber)
			hyphenEnd = hyphenStart + 1
			hyphenStart = buffer.scanBackwardForFirstNonspace(at: hyphenStart, limit: idStart)
			id = Identifier(range: idStart..<hyphenStart)
		}
		
		if hyphenEnd < endOfLineCharNumber {
			hyphenEnd = buffer.scanForFirstNonspace(at: hyphenEnd, limit: endOfLineCharNumber)
			let titleEnd = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: hyphenEnd)
			title = Title(left: hyphenStart..<hyphenEnd, body: hyphenEnd..<titleEnd)
		}
		
		let header = Header(type: .forced, start: charNumber, keyword: key, identifier: id, title: title, end: endOfLineCharNumber)
		return header
	}
	
	func scanForActHeading(in buffer: Buffer, at i: Int) -> Bool {
		guard i + 3 < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if buffer[j] == C.A {
			j += 1
			if buffer[j] == C.c {
				j += 1
				if buffer[j] == C.t {
					return true
				}
			}
		}
		
		return false
	}
	
	func scanForChapterHeading(in buffer: Buffer, at i: Int) -> Bool {
		guard i + 7 < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if buffer[j] == C.C {
			j += 1
			if buffer[j] == C.h {
				j += 1
				if buffer[j] == C.a {
					j += 1
					if buffer[j] == C.p {
						j += 1
						if buffer[j] == C.t {
							j += 1
							if buffer[j] == C.e {
								j += 1
								if buffer[j] == C.r {
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
	
	func scanForSceneHeading(in buffer: Buffer, at i: Int) -> Bool {
		guard i + 5 < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if buffer[j] == C.S {
			j += 1
			if buffer[j] == C.c {
				j += 1
				if buffer[j] == C.e {
					j += 1
					if buffer[j] == C.n {
						j += 1
						if buffer[j] == C.e {
							return true
						}
					}
				}
			}
		}
		
		return false
	}
	
	func scanForPage(in buffer: Buffer, at i: Int) -> Bool {
		guard i + 4 < endOfLineCharNumber else {
			return false
		}
		
		var j = i
		if buffer[j] == C.P {
			j += 1
			if buffer[j] == C.a {
				j += 1
				if buffer[j] == C.g {
					j += 1
					if buffer[j] == C.e {
						return true
					}
				}
			}
		}
		
		return false
	}
	
	func scanForFacsimile(in buffer: Buffer, at i: Int) -> FacsimileBlock? {
		guard i < endOfLineCharNumber  else {
			return nil
		}
		
		if buffer[i] == C.rightAngle { // ">"
			let j = buffer.scanForFirstNonspace(at: i + 1, limit: endOfLineCharNumber)
			let k = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: j)
			
			return FacsimileBlock(start: charNumber, body: j..<k, end: endOfLineCharNumber)
		}
		
		return nil
	}
	
	func scanForLyric(in buffer: Buffer, at i: Int) -> LyricBlock? {
		guard i < endOfLineCharNumber else {
			return nil
		}
		
		if buffer[i] == C.tilde {	// '~'
			let j = i + 1
			let k = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: j)
			
			return LyricBlock(start: charNumber, body: j..<k, end: endOfLineCharNumber)
		}
		
		return nil
	}
	
	func scanForDualCue(in buffer: Buffer, at i: Int) -> CueBlock? {
		let j = i + 1
		
		guard j < endOfLineCharNumber else {
			return nil
		}
		
		var del: Range<Int>? = nil
		if buffer[i] == C.caret {	// '^'
			del = charNumber..<j
		}
		
		guard let cueResults = scanForCue(in: buffer, at: del?.upperBound ?? i) else { return nil }
		
		let name = Name(body: cueResults[0].range, right: cueResults[1].range)
		let ewc = buffer.scanBackwardForFirstNonspace(at: endOfLineCharNumber, limit: cueResults[1].range.upperBound)
		let direction = DirectionBlock(body: cueResults[1].range.upperBound..<ewc, end: endOfLineCharNumber)
		
		var cue: CueBlock
		if let del = del {
			cue = CueBlock(left: del, isDual: true, name: name, direction: direction)
		} else {
			cue = CueBlock(left: charNumber..<cueResults[0].range.lowerBound, isDual: false, name: name, direction: direction)
		}
		
		return cue
	}
	
	func scanForCue(in buffer: Buffer, at i: Int) -> [SearchResult]? {
		var j = i
		var distance = 0
		while j < endOfLineCharNumber {
			let c = buffer[j]
			
			guard distance <= 24 else { break }
			
			if c == C.colon {
				let nameResult = SearchResult(range: i..<j)
				let k = buffer.scanForFirstNonspace(at: j + 1, limit: endOfLineCharNumber)
				let colonResult = SearchResult(range: j..<k)
				return [nameResult, colonResult]
			} else if c == C.openBracket {
				break
			}
			
			distance += 1
			j += 1
		}
		
		return nil
	}
	
	func scanForTheEnd(in buffer: Buffer, at i: Int) -> EndBlock? {
		guard i + 7 == buffer.endIndex else {
			return nil
		}
		
		var j = i
		if buffer[j] == C.T {
			j += 1
			if buffer[j] == C.h {
				j += 1
				if buffer[j] == C.e {
					j += 1
					if buffer[j] == C.space {
						j += 1
						if buffer[j] == C.E {
							j += 1
							if buffer[j] == C.n {
								j += 1
								if buffer[j] == C.d {
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
