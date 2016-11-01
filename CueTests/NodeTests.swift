//
//  NodeTests.swift
//  Cue
//
//  Created by Dylan McArthur on 10/26/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class NodeTests: XCTestCase {
    
	func testAddChild() {
		let des = Description(startIndex: 0, endIndex: 2)
		let raw1 = RawText(startIndex: 0, endIndex: 1)
		let raw2 = RawText(startIndex: 1, endIndex: 2)
		des.addChild(raw1)
		des.addChild(raw2)
		
		XCTAssertEqual(raw1.next!, raw2)
	}
	
	func testRemoveLastChild() {
		let des = Description(startIndex: 0, endIndex: 2)
		let raw1 = RawText(startIndex: 0, endIndex: 1)
		let raw2 = RawText(startIndex: 1, endIndex: 2)
		des.addChild(raw1)
		des.addChild(raw2)
		
		des.removeLastChild()
		
		XCTAssertNil(raw1.next)
	}
		
}
