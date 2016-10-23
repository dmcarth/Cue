//
//  HeaderScannerTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/22/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class HeaderScannerTests: XCTestCase {

	func testActEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testActAct() {
		let parser = CueParser("Act")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testActActSpace () {
		let parser = CueParser("Act ")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 3), SearchResult(startIndex: 3, endIndex: 4)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testActactSpace () {
		let parser = CueParser("act ")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 3), SearchResult(startIndex: 3, endIndex: 4)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testChapterEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testChapterChapter() {
		let parser = CueParser("Chapter")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testChapterChapterSpace () {
		let parser = CueParser("Chapter ")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 7), SearchResult(startIndex: 7, endIndex: 8)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testChapterchapterSpace () {
		let parser = CueParser("chapter ")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 7), SearchResult(startIndex: 7, endIndex: 8)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testSceneEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testSceneScene() {
		let parser = CueParser("Scene")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testSceneSceneSpace () {
		let parser = CueParser("Scene ")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 5), SearchResult(startIndex: 5, endIndex: 6)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testScenesceneSpace () {
		let parser = CueParser("scene ")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 5), SearchResult(startIndex: 5, endIndex: 6)]
		
		XCTAssertEqual(result!, expectedResult)
	}

}
