//
//  CueBlockTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/29/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class CueBlockTests: XCTestCase {
    
    func testCueLyric1Line() {
		let parser = CueParser("a: ~a")
		
		let ast = parser.parse()
		print(ast)
		
		let doc = Document(startIndex: 0, endIndex: 5)
		
		let cb = CueBlock(startIndex: 0, endIndex: 5)
		doc.addChild(cb)
		
		let rc = RegularCue(startIndex: 0, endIndex: 5)
		cb.addChild(rc)
		
		let name = Name(startIndex: 0, endIndex: 1)
		rc.addChild(name)
		let delim = Delimiter(startIndex: 1, endIndex: 3)
		delim.type = .whitespace
		rc.addChild(delim)
		
		let lyb = LyricBlock(startIndex: 3, endIndex: 5)
		rc.addChild(lyb)
		
		let ly1 = Lyric(startIndex: 3, endIndex: 5)
		lyb.addChild(ly1)
		let lydel1 = Delimiter(startIndex: 3, endIndex: 4)
		lydel1.type = .lyric
		ly1.addChild(lydel1)
		let raw1 = RawText(startIndex: 4, endIndex: 5)
		ly1.addChild(raw1)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testCueLyric2Lines() {
		let parser = CueParser("a: ~a\n~a")
		
		let ast = parser.parse()
		print(ast)
		
		let doc = Document(startIndex: 0, endIndex: 8)
		
		let cb = CueBlock(startIndex: 0, endIndex: 8)
		doc.addChild(cb)
		
		let rc = RegularCue(startIndex: 0, endIndex: 8)
		cb.addChild(rc)
		
		let name = Name(startIndex: 0, endIndex: 1)
		rc.addChild(name)
		let delim = Delimiter(startIndex: 1, endIndex: 3)
		delim.type = .whitespace
		rc.addChild(delim)
		
		let lyb = LyricBlock(startIndex: 3, endIndex: 8)
		rc.addChild(lyb)
		
		let ly1 = Lyric(startIndex: 3, endIndex: 6)
		lyb.addChild(ly1)
		let lydel1 = Delimiter(startIndex: 3, endIndex: 4)
		lydel1.type = .lyric
		ly1.addChild(lydel1)
		let raw1 = RawText(startIndex: 4, endIndex: 6)
		ly1.addChild(raw1)
		
		let ly2 = Lyric(startIndex: 6, endIndex: 8)
		lyb.addChild(ly2)
		let lydel2 = Delimiter(startIndex: 6, endIndex: 7)
		lydel2.type = .lyric
		ly2.addChild(lydel2)
		let raw2 = RawText(startIndex: 7, endIndex: 8)
		ly2.addChild(raw2)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testCueLyric3Lines() {
		let parser = CueParser("a: ~a\n~a\n~a")
		
		let ast = parser.parse()
		print(ast)
		
		let doc = Document(startIndex: 0, endIndex: 11)
		
		let cb = CueBlock(startIndex: 0, endIndex: 11)
		doc.addChild(cb)
		
		let rc = RegularCue(startIndex: 0, endIndex: 11)
		cb.addChild(rc)
		
		let name = Name(startIndex: 0, endIndex: 1)
		rc.addChild(name)
		let delim = Delimiter(startIndex: 1, endIndex: 3)
		delim.type = .whitespace
		rc.addChild(delim)
		
		let lyb = LyricBlock(startIndex: 3, endIndex: 11)
		rc.addChild(lyb)
		
		let ly1 = Lyric(startIndex: 3, endIndex: 6)
		lyb.addChild(ly1)
		let lydel1 = Delimiter(startIndex: 3, endIndex: 4)
		lydel1.type = .lyric
		ly1.addChild(lydel1)
		let raw1 = RawText(startIndex: 4, endIndex: 6)
		ly1.addChild(raw1)
		
		let ly2 = Lyric(startIndex: 6, endIndex: 9)
		lyb.addChild(ly2)
		let lydel2 = Delimiter(startIndex: 6, endIndex: 7)
		lydel2.type = .lyric
		ly2.addChild(lydel2)
		let raw2 = RawText(startIndex: 7, endIndex: 9)
		ly2.addChild(raw2)
		
		let ly3 = Lyric(startIndex: 9, endIndex: 11)
		lyb.addChild(ly3)
		let lydel3 = Delimiter(startIndex: 9, endIndex: 10)
		lydel3.type = .lyric
		ly3.addChild(lydel3)
		let raw3 = RawText(startIndex: 10, endIndex: 11)
		ly3.addChild(raw3)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
    
}
