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
		let ast = CueParser("a: ~a").ast()
		
		let doc = Document(startIndex: 0, endIndex: 5, offset: 0)
		
		let cb = CueBlock(startIndex: 0, endIndex: 5)
		doc.addChild(cb)
		
		let re1 = SearchResult(startIndex: 0, endIndex: 1)
		let re2 = SearchResult(startIndex: 1, endIndex: 3)
		
		let rc = RegularCue(startIndex: 0, endIndex: 5, results: [re1, re2])
		cb.addChild(rc)
		rc.removeLastChild()
		
		let lyb = LyricBlock(startIndex: 3, endIndex: 5)
		rc.addChild(lyb)
		
		let re3 = SearchResult(startIndex: 3, endIndex: 4)
		
		let ly1 = Lyric(startIndex: 3, endIndex: 5, result: re3)
		lyb.addChild(ly1)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testCueLyric2Lines() {
		let ast = CueParser("a: ~a\n~a").ast()
		
		let doc = Document(startIndex: 0, endIndex: 8, offset: 0)
		
		let cb = CueBlock(startIndex: 0, endIndex: 8)
		doc.addChild(cb)
		
		let re1 = SearchResult(startIndex: 0, endIndex: 1)
		let re2 = SearchResult(startIndex: 1, endIndex: 3)
		
		let rc = RegularCue(startIndex: 0, endIndex: 8, results: [re1, re2])
		cb.addChild(rc)
		rc.removeLastChild()
		
		let lyb = LyricBlock(startIndex: 3, endIndex: 8)
		rc.addChild(lyb)
		
		let re3 = SearchResult(startIndex: 3, endIndex: 4)
		
		let ly1 = Lyric(startIndex: 3, endIndex: 6, result: re3)
		lyb.addChild(ly1)
		
		let re4 = SearchResult(startIndex: 6, endIndex: 7)
		
		let ly2 = Lyric(startIndex: 6, endIndex: 8, result: re4)
		lyb.addChild(ly2)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testCueLyric3Lines() {
		let ast = CueParser("a: ~a\n~a\n~a").ast()
		
		let doc = Document(startIndex: 0, endIndex: 11, offset: 0)
		
		let cb = CueBlock(startIndex: 0, endIndex: 11)
		doc.addChild(cb)
		
		let re1 = SearchResult(startIndex: 0, endIndex: 1)
		let re2 = SearchResult(startIndex: 1, endIndex: 3)
		
		let rc = RegularCue(startIndex: 0, endIndex: 11, results: [re1, re2])
		cb.addChild(rc)
		rc.removeLastChild()
		
		let lyb = LyricBlock(startIndex: 3, endIndex: 11)
		rc.addChild(lyb)
		
		let re3 = SearchResult(startIndex: 3, endIndex: 4)
		
		let ly1 = Lyric(startIndex: 3, endIndex: 6, result: re3)
		lyb.addChild(ly1)
		
		let re4 = SearchResult(startIndex: 6, endIndex: 7)
		
		let ly2 = Lyric(startIndex: 6, endIndex: 9, result: re4)
		lyb.addChild(ly2)
		
		let re5 = SearchResult(startIndex: 9, endIndex: 10)
		
		let ly3 = Lyric(startIndex: 9, endIndex: 11, result: re5)
		lyb.addChild(ly3)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
    
}
