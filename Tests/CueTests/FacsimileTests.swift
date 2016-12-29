//
//  FacsimileTests.swift
//  Cue
//
//  Created by Dylan McArthur on 12/27/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class FacsimileTests: XCTestCase {
    
	func testFacsimile1Line() {
		let ast = CueParser(">").ast()
		
		let doc = Document(startIndex: 0, endIndex: 1, offset: 0)
		
		let fb = FacsimileBlock(startIndex: 0, endIndex: 1)
		doc.addChild(fb)
		
		let re = SearchResult(startIndex: 0, endIndex: 1)
		let f = Facsimile(startIndex: 0, endIndex: 1, result: re)
		fb.addChild(f)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testFacsimile2Lines() {
		let ast = CueParser(">\n>").ast()
		
		let doc = Document(startIndex: 0, endIndex: 3, offset: 0)
		
		let fb = FacsimileBlock(startIndex: 0, endIndex: 3)
		doc.addChild(fb)
		
		let re1 = SearchResult(startIndex: 0, endIndex: 2)
		let f1 = Facsimile(startIndex: 0, endIndex: 2, result: re1)
		fb.addChild(f1)
		
		let re2 = SearchResult(startIndex: 2, endIndex: 3)
		let f2 = Facsimile(startIndex: 2, endIndex: 3, result: re2)
		fb.addChild(f2)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
		
}
