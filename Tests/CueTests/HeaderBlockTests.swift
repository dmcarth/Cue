//
//  HeaderBlockTests.swift
//  Cue
//
//  Created by Dylan McArthur on 12/13/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class HeaderBlockTests: XCTestCase {
	
	func testHeaderScene() {
		let parser = CueParser("Scene a")
		
		let ast = parser.parse()
		print(ast)
		
		let doc = Document(startIndex: 0, endIndex: 7, offset: 0)
		
		let re1 = SearchResult(startIndex: 0, endIndex: 5, keywordType: .scene)
		let re2 = SearchResult(startIndex: 5, endIndex: 6)
		let re3 = SearchResult(startIndex: 6, endIndex: 7)
		
		let head = Heading(startIndex: 0, endIndex: 7, results: [re1, re2, re3])
		doc.addChild(head)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}

	func testHeaderSceneDashA() {
		let parser = CueParser("Scene a - a")
		
		let ast = parser.parse()
		
		let doc = Document(startIndex: 0, endIndex: 11, offset: 0)
		
		let re1 = SearchResult(startIndex: 0, endIndex: 5, keywordType: .scene)
		let re2 = SearchResult(startIndex: 5, endIndex: 6)
		let re3 = SearchResult(startIndex: 6, endIndex: 8)
		let re4 = SearchResult(startIndex: 8, endIndex: 10)
		let re5 = SearchResult(startIndex: 10, endIndex: 11)
		
		let head = Heading(startIndex: 0, endIndex: 11, results: [re1, re2, re3, re4, re5])
		doc.addChild(head)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}

}
