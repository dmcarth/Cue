//
//  CommentScannerTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/22/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class CommentScannerTests: XCTestCase {
	
	func testEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForComment(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testA() {
		let parser = CueParser("a")
		
		let result = parser.scanForComment(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testSlash() {
		let parser = CueParser("/")
		
		let result = parser.scanForComment(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testSlashSpace() {
		let parser = CueParser("/ ")
		
		let result = parser.scanForComment(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testSlashA() {
		let parser = CueParser("/a")
		
		let result = parser.scanForComment(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testSlashSlash() {
		let parser = CueParser("//")
		
		let result = parser.scanForComment(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 2)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testSlashSlashSpace() {
		let parser = CueParser("// ")
		
		let result = parser.scanForComment(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 2),SearchResult(startIndex: 2, endIndex: 3)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testSlashSlashA() {
		let parser = CueParser("//a")
		
		let result = parser.scanForComment(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 2)]
		
		XCTAssertEqual(result!, expectedResult)
	}

}
