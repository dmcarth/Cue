//
//  InlineTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/25/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class EmphasisTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testStarStar() {
		let ast = CueParser.parse("**")
		
		let doc = Document(startIndex: 0, endIndex: 2)
		let desc = Description(startIndex: 0, endIndex: 2)
		doc.addChild(desc)
		let raw = RawText(startIndex: 0, endIndex: 2)
		desc.addChild(raw)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testStarA() {
		let ast = CueParser.parse("*a")
		
		let doc = Document(startIndex: 0, endIndex: 2)
		let desc = Description(startIndex: 0, endIndex: 2)
		doc.addChild(desc)
		let raw = RawText(startIndex: 0, endIndex: 2)
		desc.addChild(raw)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testAStar() {
		let ast = CueParser.parse("a*")
		
		let doc = Document(startIndex: 0, endIndex: 2)
		let desc = Description(startIndex: 0, endIndex: 2)
		doc.addChild(desc)
		let raw = RawText(startIndex: 0, endIndex: 2)
		desc.addChild(raw)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testAStarA() {
		let ast = CueParser.parse("a*a")
		
		let doc = Document(startIndex: 0, endIndex: 3)
		let desc = Description(startIndex: 0, endIndex: 3)
		doc.addChild(desc)
		let raw = RawText(startIndex: 0, endIndex: 3)
		desc.addChild(raw)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testStarAStar() {
		let ast = CueParser.parse("*a*")
		
		let doc = Document(startIndex: 0, endIndex: 3)
		let desc = Description(startIndex: 0, endIndex: 3)
		doc.addChild(desc)
		let del1 = Delimiter(startIndex: 0, endIndex: 1)
		desc.addChild(del1)
		let em = Emphasis(startIndex: 1, endIndex: 2)
		desc.addChild(em)
		let del2 = Delimiter(startIndex: 2, endIndex: 3)
		desc.addChild(del2)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
	
	func testStarAStarAStar() {
		let ast = CueParser.parse("*a*a*")
		
		let doc = Document(startIndex: 0, endIndex: 5)
		let desc = Description(startIndex: 0, endIndex: 5)
		doc.addChild(desc)
		let del1 = Delimiter(startIndex: 0, endIndex: 1)
		desc.addChild(del1)
		let em = Emphasis(startIndex: 1, endIndex: 2)
		desc.addChild(em)
		let del2 = Delimiter(startIndex: 2, endIndex: 3)
		desc.addChild(del2)
		let raw = RawText(startIndex: 3, endIndex: 5)
		desc.addChild(raw)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}
    
}
