//
//  WhitespaceScannerTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/22/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class WhitespaceScannerTests: XCTestCase {

    func testEmpty() {
       let parser = CueParser("")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 0)
    }
	
	func testChar() {
		let parser = CueParser("a")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 0)
	}
	
	func testNewline() {
		let parser = CueParser("\n")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 1)
	}
	
	func testSpace() {
		let parser = CueParser(" ")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 1)
	}
	
	func testTab() {
		let parser = CueParser("\t")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 1)
	}
	
	func testSpaceChar() {
		let parser = CueParser(" a")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 1)
	}
	
	func testSpaceSpaceChar() {
		let parser = CueParser("  a")
		
		let wc = parser.scanForFirstNonspace(startingAt: 0)
		
		XCTAssertEqual(wc, 2)
	}

}
