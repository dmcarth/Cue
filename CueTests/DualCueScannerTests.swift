//
//  DualCueScannerTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/22/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class DualCueScannerTests: XCTestCase {

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
		
		let result = parser.scanForDualCue(atIndex: 0)
		
		XCTAssertNil(result)
    }
	
	func testCaret() {
		let parser = CueParser("^")
		
		let result = parser.scanForDualCue(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testCaretA() {
		let parser = CueParser("^a")
		
		let result = parser.scanForDualCue(atIndex: 0)
		
		XCTAssertNil(result)
	}
	
	func testCaretAColon() {
		let parser = CueParser("^a:")
		
		let result = parser.scanForDualCue(atIndex: 0)
		
		let expectedResult = [SearchResult(startIndex: 0, endIndex: 1),SearchResult(startIndex: 1, endIndex: 2), SearchResult(startIndex: 2, endIndex: 3)]
		
		XCTAssertEqual(result!, expectedResult)
	}
	
	

}
