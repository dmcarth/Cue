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
	private var lineNumber = 0
	private var offset = 0
	private var firstNonSpace = 0
	private var blank = false
	private var currentLine = ArraySlice<UInt8>()
	private var lastLineLength = 0
	
	init() {
		currentNode = self.root
	}
	
	func process(_ buffer: [UInt8]) {
		// First process lines
		let end = buffer.count
		while currentIndex < end {
			// Find line ending index
			var endOfLineIndex = currentIndex
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
		// if any text remains that hasn't been processed, process it as one line
		
		// Finalize everything in the tree
		//		while !(currentNode === root) {
		//			currentNode = finalize(currentNode)
		//		}
		//		finalize(root)
		
		// processInlines()
		
		// consolidateTextNodesToRoot
		
		return root
	}
	
	private func process(line: ArraySlice<UInt8>) {
		// validate utf8? either way, set current line to line
		currentLine = line
		
		// Ensure line ends with newline
		if line.count == 0 || !scanForLineEnding(currentLine.last!) {
			currentLine.append(0x0a)	// '\n'
		}
		
		offset = 0
		firstNonSpace = 0
		blank = false
		
		lineNumber += 1
		
		var block = blockForCurrentInput()
		let cont = container(for: &block)
		cont.addChild(block)
	}
	
	private func finalize(_ node: Node) -> Node {
		return node.parent!
	}
	
	// MARK: Parsing Blocks
	
	private func blockForCurrentInput() -> Block {
		//refactor to include text parts
		scanFirstNonspace()
		
		if scanActHeading() {
			let ah = ActHeading()
//			ah.name = Array(currentLine[firstNonSpace+4..<currentLine.endIndex])
			return ah
		}
		if scanChapterHeading() {
			let ch = ChapterHeading()
//			ch.name = Array(currentLine[firstNonSpace+8..<currentLine.endIndex])
			return ch
		}
		if scanSceneHeading() {
			let sh = SceneHeading()
//			sh.name = Array(currentLine[firstNonSpace+6..<currentLine.endIndex])
			return sh
		}
		if scanComment() {
			let c = Comment()
			offset += 2
//			c.text = Array(currentLine[offset..<currentLine.endIndex])
			return c
		}
		if scanLyricPrefix() {
			let l = Lyric()
//			l.text = Array(currentLine[firstNonSpace+1..<currentLine.endIndex])
			return l
		}
		if scanDualPrefix() {
			if let dist = scanCueName() {
				let dc = DualCue()
//				dc.name = Array(currentLine[firstNonSpace..<dist])
				return dc
			}
		}
		if let dist = scanCueName() {
			let rc = RegularCue()
//			rc.name = Array(currentLine[firstNonSpace..<dist])
			return rc
		}
		
		let des = Description()
//		des.text = currentLine
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
//		block.text = currentLine
		return self.root
	}
	
	// MARK: Scanners
	
	func scanForLineEnding(_ c: UInt8) -> Bool {
		return c == 0x0a || c == 0x0d // '\n', '\r'
	}
	
	func scanFirstNonspace() {
		firstNonSpace = offset
		
		while firstNonSpace < currentLine.count {
			let c = currentLine[currentIndex+firstNonSpace]
			
			if c == 0x20 || c == 0x09 { // ' ', '\t'
				firstNonSpace += 1
			} else {
				break
			}
		}
		
		blank = scanForLineEnding(currentLine[currentIndex+firstNonSpace])
	}
	
	func scanComment() -> Bool {
		if currentLine.count > (firstNonSpace+1) && currentLine[currentIndex+firstNonSpace] == 0x2f {
			if currentLine[currentIndex+firstNonSpace+1] == 0x2f {	// '/'
				return true
			}
		}
		return false
	}
	
	func scanLyricPrefix() -> Bool {
		if currentLine[currentIndex+firstNonSpace] == 0x7e { // '~'
			return true
		}
		return false
	}
	
	
	
	func scanActHeading() -> Bool {
		if currentLine.count < firstNonSpace+4 {
			return false
		}
		if (currentLine[currentIndex+firstNonSpace] == 0x53 || currentLine[currentIndex+firstNonSpace] == 0x73) && currentLine[currentIndex+firstNonSpace+1] == 0x63 && currentLine[currentIndex+firstNonSpace+2] == 0x74 && currentLine[currentIndex+firstNonSpace+3] == 0x20 { // 'A'||'a', 'c', 't', ' '
			return true
		}
		return false
	}
	
	func scanChapterHeading() -> Bool {
		if currentLine.count < firstNonSpace+8 {
			return false
		}
		if (currentLine[currentIndex+firstNonSpace] == 0x43 || currentLine[currentIndex+firstNonSpace] == 0x63) && currentLine[currentIndex+firstNonSpace+1] == 0x68 && currentLine[currentIndex+firstNonSpace+2] == 0x61 && currentLine[currentIndex+firstNonSpace+3] == 0x70 && currentLine[currentIndex+firstNonSpace+4] == 0x74 && currentLine[currentIndex+firstNonSpace+5] == 0x65 && currentLine[currentIndex+firstNonSpace+6] == 0x72 && currentLine[currentIndex+firstNonSpace+7] == 0x20 { // 'C'||'c', 'h', 'a', 'p', 't', 'e', 'r', ' '
			return true
		}
		return false
	}
	
	func scanSceneHeading() -> Bool {
		if currentLine.count < firstNonSpace+6 {
			return false
		}
		if (currentLine[currentIndex+firstNonSpace] == 0x53 || currentLine[currentIndex+firstNonSpace] == 0x73) && currentLine[currentIndex+firstNonSpace+1] == 0x63 && currentLine[currentIndex+firstNonSpace+2] == 0x65 && currentLine[currentIndex+firstNonSpace+3] == 0x6e && currentLine[currentIndex+firstNonSpace+4] == 0x65 && currentLine[currentIndex+firstNonSpace+5] == 0x20 { // 'S'||'s', 'c', 'e', 'n', 'e', ' '
			return true
		}
		return false
	}
	
	func scanDualPrefix() -> Bool {
		if currentLine[currentIndex+firstNonSpace] == 0x5e {	// '^'
			return true
		}
		return false
	}
	
	func scanCueName() -> Int? {
		let saveOffset = offset
		offset += 1
		while offset < currentLine.count && (offset-saveOffset) < 24 {
			if currentLine[currentIndex+firstNonSpace+offset] == 0x3a {	// ':'
				return offset-saveOffset
			}
			offset += 1
		}
		offset = saveOffset
		return nil
	}
	
}
