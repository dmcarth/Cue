//
//  LyricScannerTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/22/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class LyricScannerTests: XCTestCase {

    func testEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForLyricPrefix(atIndex: 0)
		
		XCTAssertNil(result)
    }
	
	func testTilde() {
		let parser = CueParser("~")
		
		let result = parser.scanForLyricPrefix(atIndex: 0)
		
		let expectedResult = SearchResult(startIndex: 0, endIndex: 1)
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testTildeA() {
		let parser = CueParser("~a")
		
		let result = parser.scanForLyricPrefix(atIndex: 0)
		
		let expectedResult = SearchResult(startIndex: 0, endIndex: 1)
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testATilde() {
		let parser = CueParser("a~")
		
		let result = parser.scanForLyricPrefix(atIndex: 0)
		
		XCTAssertNil(result)
	}

}
