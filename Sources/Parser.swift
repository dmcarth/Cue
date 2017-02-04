//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

public final class Cue<S: BidirectionalCollection, C: Codec> where
	S.Iterator.Element == C.CodeUnit,
	S.SubSequence: BidirectionalCollection,
	S.SubSequence.Iterator.Element == S.Iterator.Element
{
	
	public typealias Index = S.Index
	
	let data: S
	
	let root: Node<Index>
	
	var lineNumber = 0
	
	var charNumber: Index
	
	var endOfLineCharNumber: Index
	
	@_specialize(String.UTF16View, UTF16)
	@_specialize(Array<UInt16>, UTF16)
	public init(input: S, codec: C.Type) {
		self.data = input
		self.charNumber = data.startIndex
		self.endOfLineCharNumber = data.endIndex
		self.root = Node(type: .document, range: charNumber..<endOfLineCharNumber)
		
		parseBlocks()
	}
	
}

// MARK: - Views
extension Cue {
	
	public var ast: Node<Index> {
		return root
	}
	
	public var tableOfContents: [TableOfContentsItem<Index>] {
		var contents = [TableOfContentsItem<Index>]()
		
		root.enumerate { (node) in
			if case .headerBlock(let type) = node.type {
				let itemType = TableOfContentsType.init(keyword: type)
				let item = TableOfContentsItem(type: itemType, location: node.range.lowerBound)
				contents.append(item)
			} else if case .reference = node.type {
				let item = TableOfContentsItem(type: .reference, location: node.range.lowerBound)
				contents.append(item)
			}
		}
		
		return contents
	}
	
	public var namedEntitiesDictionary: [String: Array<Index>] {
		return NamedEntities(self).map
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
//		block.lineNumber = lineNumber
		
		// Then we try to find an appropriate container node. If none can be found, block will be replaced.
		let container = appropriateContainer(for: &block)
		container.addChild(block)
		
		// Only now can we parse first-line lyrics, because appropriateContainer() may have changed the current block
		if case .cueBlock(_) = block.type {
			guard let last = block.children.last else { return }
			
			guard case .textStream = last.type else { return }
			
			if let result = scanForLyricPrefix(at: last.range.lowerBound) {
				let lyricContainer = Node(type: .lyricContainer, range: result.range.lowerBound..<endOfLineCharNumber)
				let lyricBlock = Node(type: .lyricBlock, range: result.range.lowerBound..<endOfLineCharNumber)
				let tilde = Node(type: .delimiter, range: result.range)
				lyricBlock.addChild(tilde)
				let stream = Node(type: .textStream, range: result.range.upperBound..<endOfLineCharNumber)
				lyricBlock.addChild(stream)
				lyricContainer.addChild(lyricBlock)
				
				block.replaceLastChild(with: lyricContainer)
				
				// Lyrics are deeply nested. We may as well parse their inlines now rather than add an edge case later.
				parseInlines(for: stream)
			}
		}
		
		// Parse TextStream into a stream of inlines. Except for in deeply nested nodes, TextStream, if present, will always be the last child of the current block.
		if let last = block.children.last {
			guard case .textStream = last.type else { return }
			
			parseInlines(for: last)
		}
	}
	
	func blockForLine() -> Node<Index> {
		let wc = scanForFirstNonspace(startingAt: charNumber)
		
		if let header = scanForHeading(at: wc) {
			
			return header
		} else if scanForTheEnd(at: wc) {
			let end = Node(type: .endBlock, range: wc..<endOfLineCharNumber)
			
			return end
		} else if let result = scanForFacsimile(at: wc) {
			let facsimile = Node(type: .facsimileBlock, range: wc..<endOfLineCharNumber)
			let angle = Node(type: .delimiter, range: result.range)
			facsimile.addChild(angle)
			let stream = Node(type: .textStream, range: result.range.upperBound..<endOfLineCharNumber)
			facsimile.addChild(stream)
			
			return facsimile
		} else if let result = scanForLyricPrefix(at: wc) {
			let lyricBlock = Node(type: .lyricBlock, range: wc..<endOfLineCharNumber)
			let tilde = Node(type: .delimiter, range: result.range)
			lyricBlock.addChild(tilde)
			let stream = Node(type: .textStream, range: result.range.upperBound..<endOfLineCharNumber)
			lyricBlock.addChild(stream)
			
			return lyricBlock
		} else if let cueBlock = scanForDualCue(at: wc) {
			return cueBlock
		}
		
		let description = Node(type: .descriptionBlock, range: charNumber..<endOfLineCharNumber)
		let stream = Node(type: .textStream, range: charNumber..<endOfLineCharNumber)
		description.addChild(stream)
		return description
	}
	
	func appropriateContainer(for block: inout Node<Index>) -> Node<Index> {
		switch block.type {
		// These block types can only ever be level-1
		case .headerBlock, .descriptionBlock, .endBlock:
			return root
			
		// A CueBlock is always level-2, but regular cues need their own initial parent CueContainer
		case .cueBlock(let isDual):
			if isDual {
				let cueContainer = Node(type: .cueContainer, range: block.range)
				root.addChild(cueContainer)
				
				return cueContainer
			} else if let last = root.children.last {
				guard case .cueContainer = last.type else { break }
				
				return last
			}
			
		// FacsimileBlocks are also always level-2
		case .facsimileBlock:
			// If last child of root is a FacsimileContainer and the current block is a FacsimileBlock, then attach the current block to this container
			if let last = root.children.last {
				if case .facsimileContainer = last.type {
					return last
				}
			}
			
			// First line. Initialize new container
			let facsimileContainer = Node(type: .facsimileContainer, range: block.range)
			root.addChild(facsimileContainer)
			return facsimileContainer
			
		// Lyric Blocks are always level-4. Any LyricBlock that comes to us at this point is guaranteed to be not be a first line so we can ignore that edge case
		case .lyricBlock:
			guard let cueContainer = root.children.last else { break }
			
			guard case .cueContainer = cueContainer.type else { break }
			
			guard let cueBlock = cueContainer.children.last else { break }
			
			guard case .cueBlock = cueBlock.type else { break }
			
			guard let content = cueBlock.children.last else { break }
			
			guard case .lyricContainer = content.type else { break }
			
			return content
		default:
			break
		}
		
		// Invalid syntax, time to fail gracefully
		block = Node(type: .descriptionBlock, range: charNumber..<endOfLineCharNumber)
		let stream = Node(type: .textStream, range: charNumber..<endOfLineCharNumber)
		block.addChild(stream)
		return root
	}
	
}

// MARK: - Inline Parsing
extension Cue {
	
	func parseInlines(for stream: Node<Index>) {
		let i = stream.range.lowerBound
		
		var queue = Queue<Node<Index>>()
		
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
					let em = Node(type: .emphasis, range: last.range.lowerBound..<marker.range.upperBound)
					let d1 = Node(type: .delimiter, range: last.range)
					em.addChild(d1)
					let d2 = Node(type: .delimiter, range: marker.range)
					em.addChild(d2)
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
					let ref = Node(type: .reference, range: last.range.lowerBound..<marker.range.upperBound)
					let d1 = Node(type: .delimiter, range: last.range)
					ref.addChild(d1)
					let d2 = Node(type: .delimiter, range: marker.range)
					ref.addChild(d2)
					queue.enqueue(ref)
					break
				}
				
			case C.slash:
				guard k < endOfLineCharNumber else { break }
				
				if data[k] == C.slash {
					let com = Node(type: .comment,range: j..<endOfLineCharNumber)
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
			if next.range.lowerBound > j {
				let lit = Node(type: .literal, range: j..<next.range.lowerBound)
				stream.addChild(lit)
			}
			
			stream.addChild(next)
			
			j = next.range.upperBound
		}
		
		if j < endOfLineCharNumber {
			let lit = Node(type: .literal, range: j..<endOfLineCharNumber)
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
	
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers the keyword, [1] covers whitespace, [2] covers the id, [3-4] covers the hyphen and title if present.
	func scanForHeading(at i: Index) -> Node<Index>? {
		var type: HeaderType
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
		
		let header = Node(type: .headerBlock(type), range: i..<endOfLineCharNumber)
		let key = Node(type: .literal, range: keyRange)
		header.addChild(key)
		let id = Node(type: .literal, range: idRange)
		header.addChild(id)
		
		if m < endOfLineCharNumber {
			let n = scanForFirstNonspace(startingAt: m)
			let hyphenRange: Range<Index> = l..<n
			let titleRange: Range<Index> = n..<endOfLineCharNumber
			
			let hyphen = Node(type: .delimiter, range: hyphenRange)
			header.addChild(hyphen)
			let title = Node(type: .textStream, range: titleRange)
			header.addChild(title)
		}
		
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
	func scanForFacsimile(at i: Index) -> SearchResult<Index>? {
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
	func scanForLyricPrefix(at i: Index) -> SearchResult<Index>? {
		guard i < endOfLineCharNumber else {
			return nil
		}
		
		if data[i] == C.tilde {	// '~'
			return SearchResult(range: i..<data.index(after: i))
		}
		
		return nil
	}
	
	func scanForDualCue(at i: Index) -> Node<Index>? {
		let j = data.index(after: i)
		
		guard j < endOfLineCharNumber else {
			return nil
		}
		
		var del: Range<Index>? = nil
		if data[i] == C.caret {	// '^'
			del = i..<j
		}
		
		guard let cueResults = scanForCue(at: j) else { return nil }
		
		let cue = Node(type: .cueBlock(del != nil), range: i..<endOfLineCharNumber)
		if let delRange = del {
			let caret = Node(type: .delimiter, range: delRange)
			cue.addChild(caret)
		}
		let name = Node(type: .name, range: cueResults[0].range)
		cue.addChild(name)
		let colon = Node(type: .delimiter, range: cueResults[1].range)
		cue.addChild(colon)
		let stream = Node(type: .textStream, range: cueResults[1].range.lowerBound..<endOfLineCharNumber)
		cue.addChild(stream)
		
		return cue
	}
	
	func scanForCue(at i: Index) -> [SearchResult<Index>]? {
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
	
//	/// Returns an array of SearchResults or nil if matching failed.
//	///
//	/// - returns: [0] covers Cue name, [1] covers ":" and any whitespace
//	func scanForCue(at i: Index) -> [SearchResult]? {
//		var j = i
//		var state = 0
//		var matched = false
//		var distance = 0
//		while j < endOfLineCharNumber {
//			
//			switch state {
//			case 0:
//				// initial state
//				if data[j] != C.colon && data[j] != C.leftBracket { // not ':' or '['
//					state = 1
//				} else {
//					return nil
//				}
//				
//			case 1:
//				// find colon
//				if data[j] == C.colon { // ':'
//					matched = true
//				} else if distance >= 23 || data[j] == C.leftBracket { // cue can not be > 24 (23 chars + :), and should not contain brackets.
//					return nil
//				} else {
//					state = 1
//				}
//				
//			default:
//				return nil
//			}
//			
//			if matched {
//				let result1 = SearchResult(range: i..<j)
//				let wc = scanForFirstNonspace(startingAt: data.index(after: j))
//				let result2 = SearchResult(range: result1.range.upperBound..<wc)
//				
//				return [result1, result2]
//			}
//			
//			j = data.index(after: j)
//			distance += 1
//		}
//		
//		return nil
//	}
	
	func scanForTheEnd(at i: Index) -> Bool {
		guard data.index(i, offsetBy: 7) == data.endIndex else {
			return false
		}
		
		// 'T', 'h', 'e', ' ', 'E', 'n', 'd'
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
