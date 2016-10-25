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
		
		XCTAssertFalse(result)
	}
	
	func testActAct() {
		let parser = CueParser("Act")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		XCTAssertFalse(result)
	}
	
	func testActActSpace () {
		let parser = CueParser("Act ")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		XCTAssertTrue(result)
	}
	
	func testActactSpace () {
		let parser = CueParser("act ")
		
		let result = parser.scanForActHeading(atIndex: 0)
		
		XCTAssertTrue(result)
	}
	
	func testChapterEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		XCTAssertFalse(result)
	}
	
	func testChapterChapter() {
		let parser = CueParser("Chapter")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		XCTAssertFalse(result)
	}
	
	func testChapterChapterSpace () {
		let parser = CueParser("Chapter ")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		XCTAssertTrue(result)
	}
	
	func testChapterchapterSpace () {
		let parser = CueParser("chapter ")
		
		let result = parser.scanForChapterHeading(atIndex: 0)
		
		XCTAssertTrue(result)
	}
	
	func testSceneEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		XCTAssertFalse(result)
	}
	
	func testSceneScene() {
		let parser = CueParser("Scene")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		XCTAssertFalse(result)
	}
	
	func testSceneSceneSpace () {
		let parser = CueParser("Scene ")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		XCTAssertTrue(result)
	}
	
	func testScenesceneSpace () {
		let parser = CueParser("scene ")
		
		let result = parser.scanForSceneHeading(atIndex: 0)
		
		XCTAssertTrue(result)
	}

}
