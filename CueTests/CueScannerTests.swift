//
//  ScannerTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/22/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class CueScannerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForCue(atIndex: 0)
		
		XCTAssertNil(result)
	}

    func testColon() {
		let parser = CueParser(":")
		
		let result = parser.scanForCue(atIndex: 0)
		
		XCTAssertNil(result)
    }
	
	func testColonColon() {
		let parser = CueParser("::")
		
		let result = parser.scanForCue(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testAColon() {
		let parser = CueParser("a:")
		
		let result = parser.scanForCue(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 1),SearchResult(startIndex: 1, endIndex: 2)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testAAColon() {
		let parser = CueParser("aa:")
		
		let result = parser.scanForCue(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 2),SearchResult(startIndex: 2, endIndex: 3)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testAColonSpace() {
		let parser = CueParser("a: ")
		
		let result = parser.scanForCue(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 1),SearchResult(startIndex: 1, endIndex: 3)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testAColonSpaceSpace() {
		let parser = CueParser("a:  ")
		
		let result = parser.scanForCue(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 1),SearchResult(startIndex: 1, endIndex: 4)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func testAColonSpaceSpaceA() {
		let parser = CueParser("a:  a")
		
		let result = parser.scanForCue(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 1),SearchResult(startIndex: 1, endIndex: 4)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	func test24AColon() {
		let parser = CueParser("aaaaaaaaaaaaaaaaaaaaaaaa:")
		
		let result = parser.scanForCue(atIndex: 0)
		
		XCTAssertNil(result)
	}

}
