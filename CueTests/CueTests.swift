//
//  CueTests.swift
//  CueTests
//
//  Created by Dylan McArthur on 10/11/16.
//  Copyright © 2016 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import Cue

class CueTests: XCTestCase {
	
    override func setUp() {
        super.setUp()
		
    }
    
    override func tearDown() {
		
        super.tearDown()
    }
    
    func testPerformanceExample() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		let bytes = [UInt16](str.utf16)
		let parser = CueParser(with: bytes)
		
        self.measure {
			_ = parser.parse()
        }
    }
	
}
