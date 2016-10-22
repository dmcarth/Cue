//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

open class CueParser {
	
	let data: [UInt16]
	var root = Document()
	var lineNumber = 0
	var charNumber = 0
	var endOfLineCharNumber = 0
	
	open class func parse(_ string: String) -> Node {
		let bytes = [UInt16](string.utf16)
		return parse(bytes)
	}
	
	open class func parse(_ bytes: [UInt16]) -> Node {
		let parser = CueParser(bytes: bytes)
		return parser.parse()
	}
	
	public init(bytes: [UInt16]) {
		data = bytes
	}
	
	open func parse() -> Node {
		root = Document()
		lineNumber = 0
		charNumber = 0
		endOfLineCharNumber = 0
		
		parseBlocks()
		
		parseInlines()
		
		return root
	}
	
}

// Block Parsing
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
		block.startIndex = charNumber
		block.endIndex = endOfLineCharNumber
		
		let container = appropriateContainer(for: &block)
		container.addChild(block)
		container.startIndex = min(container.startIndex, block.startIndex)
		container.endIndex = max(container.endIndex, block.endIndex)
		
		// Ensure firstline lyrics are parsed
		if let cb = block as? Cue {
			guard cb.children.last! is Text else {
				print("not right")
				return
			}
			
			var last: Node = cb.children.last!
			
			if let result = scanForLyricPrefix(atIndex: last.startIndex) {
				let ly = Lyric(startIndex: result.startIndex, endIndex: endOfLineCharNumber)
				let delim = Delimiter(startIndex: result.startIndex, endIndex: result.endIndex)
				ly.addChild(delim)
				let te = Text(startIndex: delim.endIndex, endIndex: endOfLineCharNumber)
				ly.addChild(te)
				cb.children.removeLast()
				cb.addChild(ly)
			}
		}
	}
	
	func blockForLine() -> Block {
		let wc = scanForFirstNonspace(startingAtIndex: charNumber)
		
		if let result = scanForActHeading(atIndex: wc) {
			let ah = ActHeading()
			let te = Text(startIndex: result[0].startIndex, endIndex: endOfLineCharNumber)
			ah.addChild(te)
			return ah
		} else if let result = scanForChapterHeading(atIndex: wc) {
			let ch = ChapterHeading()
			let te = Text(startIndex: result[0].startIndex, endIndex: endOfLineCharNumber)
			ch.addChild(te)
			return ch
		} else if let result = scanForSceneHeading(atIndex: wc) {
			let sh = SceneHeading()
			let te = Text(startIndex: result[0].startIndex, endIndex: endOfLineCharNumber)
			sh.addChild(te)
			return sh
		} else if let result = scanForComment(atIndex: wc) {
			let com = Comment()
			let delim = Delimiter(startIndex: result[0].startIndex, endIndex: result[0].endIndex)
			if result.count == 2 {
				delim.endIndex = result[1].endIndex
			}
			com.addChild(delim)
			let te = Text(startIndex: delim.endIndex, endIndex: endOfLineCharNumber)
			com.addChild(te)
			return com
		} else if let result = scanForLyricPrefix(atIndex: wc) {
			let ly = Lyric()
			let delim = Delimiter(startIndex: result.startIndex, endIndex: result.endIndex)
			ly.addChild(delim)
			let te = Text(startIndex: delim.endIndex, endIndex: endOfLineCharNumber)
			ly.addChild(te)
			return ly
		} else if let result = scanForDualCue(atIndex: wc) {
			let du = DualCue()
			let del1 = Delimiter(startIndex: result[0].startIndex, endIndex: result[0].endIndex)
			du.addChild(del1)
			let name = Name(startIndex: result[1].startIndex, endIndex: result[1].endIndex)
			du.addChild(name)
			let del2 = Delimiter(startIndex: result[2].startIndex, endIndex: result[2].endIndex)
			du.addChild(del2)
			let te = Text(startIndex: del2.endIndex, endIndex: endOfLineCharNumber)
			du.addChild(te)
			return du
		} else if let result = scanForCue(atIndex: wc) {
			let cu = RegularCue()
			let name = Name(startIndex: result[0].startIndex, endIndex: result[0].endIndex)
			cu.addChild(name)
			let del2 = Delimiter(startIndex: result[1].startIndex, endIndex: result[1].endIndex)
			cu.addChild(del2)
			let te = Text(startIndex: del2.endIndex, endIndex: endOfLineCharNumber)
			cu.addChild(te)
			return cu
		}
		
		let des = Description()
		let te = Text(startIndex: wc, endIndex: endOfLineCharNumber)
		des.addChild(te)
		return des
	}
	
	func appropriateContainer(for block: inout Block) -> Node {
		var container: Node = self.root
		
		switch block {
		// These block types can only ever be level-1
		case is ActHeading, is ChapterHeading, is SceneHeading, is Description, is Comment:
			return container
		// A regular cue is always level-2, with it's own initial parent cueBlock
		case is RegularCue:
			let cueBlockContainer = CueBlock()
			cueBlockContainer.startIndex = block.startIndex
			cueBlockContainer.endIndex = block.endIndex
			container.addChild(cueBlockContainer)
			return cueBlockContainer
		default:
			break
		}
		
		//	If none of those predetermined cases match, iterate down the tree, checking each lastchild in succession
		while let lastChild = container.children.last {
			container = lastChild
			
			var foundBreakingStatement = false
			switch container {
			case is CueBlock:
				if block is DualCue {
					return container
				}
				break
			case is RegularCue, is DualCue:
				if block is Lyric {
					return container
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
		return self.root
	}
	
}

// Inline Parsing
extension CueParser {
	
	func parseInlines() {
		
		root.enumerate { (node) in
			guard node is Text else { return }
			
			let parent = node.parent!
			
			let stack = InlineStack()
			
			charNumber = node.startIndex
			endOfLineCharNumber = node.endIndex
			while charNumber < endOfLineCharNumber {
				let c = data[charNumber]
				
				switch c {
				case 0x002a:	// '*'
					guard let opener = stack.lastEmphasis else {
						let del = Delimiter(startIndex: charNumber, endIndex: charNumber+1)
						del.type = .emph
						stack.push(del)
						break
					}
					
					let em = Emphasis(startIndex: opener.startIndex, endIndex: charNumber+1)
					em.addChild(opener)
					let enddel = Delimiter(startIndex: charNumber, endIndex: charNumber+1)
					enddel.type = .emph
					em.addChild(enddel)
					while let _ = stack.pop() {
						// TODO: parse refs inside emphs
						if stack.count <= stack.lastEmphasisIndex! { break }
						if stack.count == 0 { break }
					}
					stack.push(em)
					stack.lastEmphasis = nil
					stack.lastEmphasisIndex = nil
					break
				case 0x005b:	// '['
					let del = Delimiter(startIndex: charNumber, endIndex: charNumber+1)
					del.type = .openBracket
					stack.push(del)
					break
				case 0x005d:	// ']'
					guard let opener = stack.lastBracket else {
						break
					}
					
					let ref = Reference(startIndex: opener.startIndex, endIndex: charNumber+1)
					ref.addChild(opener)
					let endDel = Delimiter(startIndex: charNumber, endIndex: charNumber+1)
					endDel.type = .closeBracket
					ref.addChild(endDel)
					while let _ = stack.pop() {
						if stack.count <= stack.lastBracketIndex! { break }
						if stack.count == 0 { break }
					}
					stack.push(ref)
					stack.lastBracket = nil
					stack.lastEmphasisIndex = nil
					break
				default:
					break
				}
				
				charNumber += 1
			}
			
			parent.children.removeLast()
			charNumber = node.startIndex
			
			// run through stack
			for span in stack.array {
				// take care of any interim text
				if span.startIndex > charNumber {
					let text = Text(startIndex: charNumber, endIndex: span.startIndex)
					parent.addChild(text)
				}
				
				parent.addChild(span)
				
				charNumber = span.endIndex
			}
			
			if charNumber < endOfLineCharNumber {
				let te = Text(startIndex: charNumber, endIndex: endOfLineCharNumber)
				parent.addChild(te)
			}
		}
		
	}
	
}

// Scanners
extension CueParser {
	
	func scanForLineEnding(atIndex i: Int) -> Bool {
		let c = data[i]
		
		return c == 0x000a || c == 0x000d // '\n', '\r'
	}
	
	func scanForFirstNonspace(startingAtIndex i: Int) -> Int {
		var j = i
		
		while j < endOfLineCharNumber {
			let c = data[j]
			
			if c == 0x0020 || c == 0x0009 {	// ' ', '\t'
				j += 1
			} else {
				break
			}
		}
		
		return j
	}
	
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "Act", [1] covers whitespace
	func scanForActHeading(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 4 else {
			return nil
		}
		
		if (data[i] == 0x0041 || data[i] == 0x0061) &&
			data[i+1] == 0x0063 && data[i+2] == 0x0074 {	// 'A'||'a', 'c', 't'
			let wc = scanForFirstNonspace(startingAtIndex: i+3)
			
			guard wc > i+4 else { return nil }
			
			var results = [SearchResult]()
			let result1 = SearchResult(startIndex: i, endIndex: i+3)
			results.append(result1)
			let result2 = SearchResult(startIndex: i+3, endIndex: wc)
			results.append(result2)
			return results
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "Chapter", [1] covers whitespace
	func scanForChapterHeading(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 8 else {
			return nil
		}
		
		if (data[i] == 0x0043 || data[i] == 0x0063) &&
			data[i+1] == 0x0068 && data[i+2] == 0x0061 && data[i+3] == 0x0070 && data[i+4] == 0x0074 && data[i+5] == 0x0065 && data[i+6] == 0x0072 {	// 'C'||'c', 'h', 'a', 'p', 't', 'e', 'r'
			let wc = scanForFirstNonspace(startingAtIndex: i+7)
			
			guard wc > i+4 else { return nil }
			
			var results = [SearchResult]()
			let result1 = SearchResult(startIndex: i, endIndex: i+7)
			results.append(result1)
			let result2 = SearchResult(startIndex: i+7, endIndex: wc)
			results.append(result2)
			return results
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "Scene", [1] covers whitespace
	func scanForSceneHeading(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 6 else {
			return nil
		}
		
		
		if (data[i] == 0x0053 || data[i] == 0x0073) &&
			data[i+1] == 0x0063 && data[i+2] == 0x0065 && data[i+3] == 0x006e && data[i+4] == 0x0065 {	// 'S'||'s', 'c', 'e', 'n', 'e'
			let wc = scanForFirstNonspace(startingAtIndex: i+5)
			
			guard wc > i+4 else { return nil }
			
			var results = [SearchResult]()
			let result1 = SearchResult(startIndex: i, endIndex: i+5)
			results.append(result1)
			let result2 = SearchResult(startIndex: i+5, endIndex: wc)
			results.append(result2)
			return results
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers "//" and any additional "/", optional [1] covers whitespace
	func scanForComment(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 3 else {
			return nil
		}
		
		var j = i
		while data[j] == 0x002f && j < endOfLineCharNumber {	// '/'
			j += 1
		}
		if j > i+1 {
			let wc = scanForFirstNonspace(startingAtIndex: j)
			
			var results = [SearchResult]()
			let result1 = SearchResult(startIndex: i, endIndex: j+1)
			results.append(result1)
			if wc > 0 {
				let result2 = SearchResult(startIndex: i+5, endIndex: wc)
				results.append(result2)
			}
			return results
		}
		
		return nil
	}
	
	/// Returns a SearchResult or nil if matching failed.
	///
	/// - returns: Result covers "~"
	func scanForLyricPrefix(atIndex i: Int) -> SearchResult? {
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
	func scanForDualCue(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i + 3 else {
			return nil
		}
		
		if data[i] == 0x005e {	// '^'
			var results = scanForCue(atIndex: i+1)
			
			guard results != nil else {
				return nil
			}
			
			let result1 = SearchResult(startIndex: i, endIndex: i+1)
			results!.insert(result1, at: 0)
			return results
		}
		
		return nil
	}
	
	/// Returns an array of SearchResults or nil if matching failed.
	///
	/// - returns: [0] covers Cue name, [1] covers ":" and any whitespace
	func scanForCue(atIndex i: Int) -> [SearchResult]? {
		guard endOfLineCharNumber > i+3 else {
			return nil
		}
		
		var j = i
		while j < endOfLineCharNumber && data[j] != 0x003a  {	// ':'
			if j-i > 24 { return nil }
			
			j += 1
		}
		if j < endOfLineCharNumber && j-i > 1 && data[j] == 0x003a  {
			guard data[j+1] != 0x003a else {
				return nil
			}
			
			let wc = scanForFirstNonspace(startingAtIndex: j+1)	//include room for the ':'
			
			var results = [SearchResult]()
			let result1 = SearchResult(startIndex: i, endIndex: j)
			results.append(result1)
			let result2 = SearchResult(startIndex: j, endIndex: wc)
			results.append(result2)
			return results
		}
		
		return nil
	}
	
}
