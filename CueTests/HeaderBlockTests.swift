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
		
		let doc = Document(startIndex: 0, endIndex: 7)
		
		let head = Heading(startIndex: 0, endIndex: 7)
		doc.addChild(head)
		
		let key = Keyword(startIndex: 0, endIndex: 5)
		key.type = .scene
		head.addChild(key)
		
		let del = Delimiter(startIndex: 5, endIndex: 6)
		del.type = .whitespace
		head.addChild(del)
		
		let id = Identifier(startIndex: 6, endIndex: 7)
		head.addChild(id)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}

	func testHeaderSceneDashA() {
		let parser = CueParser("Scene a - a")
		
		let ast = parser.parse()
		
		let doc = Document(startIndex: 0, endIndex: 11)
		
		let head = Heading(startIndex: 0, endIndex: 11)
		doc.addChild(head)
		
		let key = Keyword(startIndex: 0, endIndex: 5)
		key.type = .scene
		head.addChild(key)
		
		let del = Delimiter(startIndex: 5, endIndex: 6)
		del.type = .whitespace
		head.addChild(del)
		
		let id = Identifier(startIndex: 6, endIndex: 8)
		head.addChild(id)
		
		let del1 = Delimiter(startIndex: 8, endIndex: 10)
		del1.type = .hyphen
		head.addChild(del1)
		
		let raw = RawText(startIndex: 10, endIndex: 11)
		head.addChild(raw)
		
		XCTAssertEqual(ast.debugString(), doc.debugString())
	}

}
