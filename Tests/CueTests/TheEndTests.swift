//
//  TheEndTests.swift
//  Cue
//
//  Created by Dylan McArthur on 12/27/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class TheEndTests: XCTestCase {
    
	func testEmpty() {
		let parser = CueParser("")
		
		let result = parser.scanForTheEnd(at: 0)
		
		XCTAssertFalse(result)
	}
	
	func testTheEndLower() {
		let parser = CueParser("the end")
		
		let result = parser.scanForTheEnd(at: 0)
		
		XCTAssertTrue(result)
	}
	
	func testTheEndUpper() {
		let parser = CueParser("THE END")
		
		let result = parser.scanForTheEnd(at: 0)
		
		XCTAssertTrue(result)
	}
	
	func testTheEndNewline() {
		let parser = CueParser("the end\n")
		
		let result = parser.scanForTheEnd(at: 0)
		
		XCTAssertFalse(result)
	}
	
}
