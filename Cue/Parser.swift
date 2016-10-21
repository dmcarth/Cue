//
//  Parser.swift
//  Cue
//
//  Created by Dylan McArthur on 10/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

class CueParser {
	
	private var root = Document()
	private var currentNode: Node
	private var currentIndex = 0
	private var endOfLineIndex = 0
	private var lineNumber = 0
	private var offset = 0
	private var firstNonSpace = 0
	private var blank = false
	private var currentLine = ArraySlice<UInt16>()
	private var data = [UInt16]()
	private var lastLineLength = 0
	
	init() {
		currentNode = self.root
	}
	
	func process(_ buffer: [UInt16]) {
		data = buffer
		
		// First process lines
		let end = buffer.count
		while currentIndex < end {
			// Find line ending index
			endOfLineIndex = currentIndex
			while endOfLineIndex < end {
				if scanForLineEnding(buffer[endOfLineIndex]) {
					endOfLineIndex += 1
					break
				}
				endOfLineIndex += 1
			}
			
			// Process line
			process(line: buffer[currentIndex..<endOfLineIndex])
			
			currentIndex = endOfLineIndex
		}
	}
	
	func finish() -> Node {
		// Finalize everything in the tree
		finalize(root)
		
		processInlines()
		
		root.length = currentIndex
		
		return root
	}
	
	private func process(line: ArraySlice<UInt16>) {
		// validate utf8? either way, set current line to line
		currentLine = line
		
		// Ensure line ends with newline
		if line.count == 0 || !scanForLineEnding(currentLine.last!) {
			currentLine.append(0x000a)	// '\n'
		}
		
		offset = 0
		firstNonSpace = 0
		blank = false
		
		lineNumber += 1
		
		var block = blockForCurrentInput()
		block.location = currentIndex
		block.length = endOfLineIndex-currentIndex
		
		let cont = container(for: &block)
		cont.addChild(block)
		cont.location = min(cont.location, block.location)
		if cont.location+cont.length < block.location+block.length {
			cont.length = block.location + block.length - cont.location
		}
		
		if let cb = block as? Cue {
			scanFirstNonspace()
			
			if scanLyricPrefix() {
				let ly = Lyric()
				ly.location = currentIndex+firstNonSpace
				ly.length = endOfLineIndex - ly.location
				cb.addChild(ly)
				let del = Delimiter()
				del.location = ly.location
				del.length = 1
				ly.addChild(del)
				let te = Text()
				te.location = currentIndex+firstNonSpace+1
				te.length = endOfLineIndex - te.location
				cb.addChild(te)
			} else {
				let te = Text()
				te.location = currentIndex+firstNonSpace
				te.length = endOfLineIndex - te.location
				cb.addChild(te)
			}
		} else {
			scanFirstNonspace()
			
			let te = Text()
			te.location = currentIndex+firstNonSpace
			te.length = endOfLineIndex-te.location
			block.addChild(te)
		}
	}
	
	private func finalize(_ node: Node) {
//		node.enumerate { (leaf) in
//			if leaf is Block {
//				let start = (leaf.children.last != nil) ?  (leaf.children.last!.location+leaf.children.last!.length) : leaf.location
//				
//				let te = Text()
//				te.location = start
//				te.length = leaf.location+leaf.length-te.location
//				leaf.addChild(te)
//			}
//		}
	}
	
	// MARK: Parsing Blocks
	
	private func blockForCurrentInput() -> Block {
		scanFirstNonspace()
		
		if scanActHeading() {
			let ah = ActHeading()
			return ah
		}
		if scanChapterHeading() {
			let ch = ChapterHeading()
			return ch
		}
		if scanSceneHeading() {
			let sh = SceneHeading()
			return sh
		}
		if scanComment() {
			let c = Comment()
			let del = Delimiter()
			del.location = firstNonSpace+currentIndex
			del.length = 2
			c.addChild(del)
			offset += 2
			return c
		}
		if scanLyricPrefix() {
			let l = Lyric()
			let del = Delimiter()
			del.location = firstNonSpace+currentIndex
			del.length = 1
			l.addChild(del)
			return l
		}
		if scanDualPrefix() {
			if let dist = scanCueName() {
				let dc = DualCue()
				dc.addName(ofLength: dist, atIndex: firstNonSpace+currentIndex)
				offset = 1+dist+firstNonSpace
				return dc
			}
		}
		if let dist = scanCueName() {
			let rc = RegularCue()
			rc.addName(ofLength: dist, atIndex: firstNonSpace+currentIndex)
			offset = 1+dist+firstNonSpace
			return rc
		}
		
		let des = Description()
		return des
	}
	
	private func container(for block: inout Block) -> Node {
		var container: Node = self.root
		
		switch block {
		// These block types can only ever be level-1
		case is ActHeading, is ChapterHeading, is SceneHeading, is Description, is Comment:
			return container
		// A regular cue is always level-2, with it's own initial parent cueBlock
		case is RegularCue:
			let cueBlockContainer = CueBlock()
			cueBlockContainer.location = currentIndex
			cueBlockContainer.length = endOfLineIndex-currentIndex
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
		
		block = Description()
		return self.root
	}
	
	// MARK: Parsing Inlines
	
	func processInlines() {
		
		root.enumerate { (leaf) in
			guard leaf is Text else { return }
			
			var stack = [(String, Int)]()
			
			var i = leaf.location
			var buff = [UInt16]()
			while i < leaf.location+leaf.length {
				let c = data[i]
				
				if c == 0x002a {
					stack.append(("*", i))
				}
				else if c == 0x005b {
					stack.append(("[", i))
				}
				else if c == 0x005d {	// ']'
					
				}
				
				
				i += 1
			}
		}
		
	}
	
	// MARK: Scanners
	
	func scanForLineEnding(_ c: UInt16) -> Bool {
		return c == 0x000a || c == 0x000d // '\n', '\r'
	}
	
	func scanFirstNonspace() {
		firstNonSpace = offset
		
		while firstNonSpace < currentLine.count {
			let c = currentLine[currentIndex+firstNonSpace]
			
			if c == 0x0020 || c == 0x0009 { // ' ', '\t'
				firstNonSpace += 1
			} else {
				break
			}
		}
		
		blank = scanForLineEnding(currentLine[currentIndex+firstNonSpace])
	}
	
	func scanComment() -> Bool {
		if currentLine.count > (firstNonSpace+1) && currentLine[currentIndex+firstNonSpace] == 0x002f {
			if currentLine[currentIndex+firstNonSpace+1] == 0x002f {	// '/'
				return true
			}
		}
		return false
	}
	
	func scanLyricPrefix() -> Bool {
		if currentLine[currentIndex+firstNonSpace] == 0x007e { // '~'
			return true
		}
		return false
	}
	
	
	
	func scanActHeading() -> Bool {
		if currentLine.count < firstNonSpace+4 {
			return false
		}
		if (currentLine[currentIndex+firstNonSpace] == 0x0053 || currentLine[currentIndex+firstNonSpace] == 0x0073) && currentLine[currentIndex+firstNonSpace+1] == 0x0063 && currentLine[currentIndex+firstNonSpace+2] == 0x0074 && currentLine[currentIndex+firstNonSpace+3] == 0x0020 { // 'A'||'a', 'c', 't', ' '
			return true
		}
		return false
	}
	
	func scanChapterHeading() -> Bool {
		if currentLine.count < firstNonSpace+8 {
			return false
		}
		if (currentLine[currentIndex+firstNonSpace] == 0x0043 || currentLine[currentIndex+firstNonSpace] == 0x0063) && currentLine[currentIndex+firstNonSpace+1] == 0x0068 && currentLine[currentIndex+firstNonSpace+2] == 0x0061 && currentLine[currentIndex+firstNonSpace+3] == 0x0070 && currentLine[currentIndex+firstNonSpace+4] == 0x0074 && currentLine[currentIndex+firstNonSpace+5] == 0x0065 && currentLine[currentIndex+firstNonSpace+6] == 0x0072 && currentLine[currentIndex+firstNonSpace+7] == 0x0020 { // 'C'||'c', 'h', 'a', 'p', 't', 'e', 'r', ' '
			return true
		}
		return false
	}
	
	func scanSceneHeading() -> Bool {
		if currentLine.count < firstNonSpace+6 {
			return false
		}
		if (currentLine[currentIndex+firstNonSpace] == 0x0053 || currentLine[currentIndex+firstNonSpace] == 0x0073) && currentLine[currentIndex+firstNonSpace+1] == 0x0063 && currentLine[currentIndex+firstNonSpace+2] == 0x0065 && currentLine[currentIndex+firstNonSpace+3] == 0x006e && currentLine[currentIndex+firstNonSpace+4] == 0x0065 && currentLine[currentIndex+firstNonSpace+5] == 0x0020 { // 'S'||'s', 'c', 'e', 'n', 'e', ' '
			return true
		}
		return false
	}
	
	func scanDualPrefix() -> Bool {
		if currentLine[currentIndex+firstNonSpace] == 0x005e {	// '^'
			return true
		}
		return false
	}
	
	func scanCueName() -> Int? {
		let saveOffset = offset
		offset += 1
		while offset < currentLine.count && (offset-saveOffset) < 24 {
			if currentLine[currentIndex+firstNonSpace+offset] == 0x003a {	// ':'
				return offset-saveOffset
			}
			offset += 1
		}
		offset = saveOffset
		return nil
	}
	
}
