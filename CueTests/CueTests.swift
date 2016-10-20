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
    
    func testExample() {
		
	}
	
	func testBaselineForParsing() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		let uis = [UInt16](str.utf16)
		
		self.measure {
			var wc = 0
			for _ in uis {
				wc += 1
			}
			print(wc)
		}
	}
    
    func testPerformanceExample() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		let bytes = [UInt8](str.utf8)
		let parser = CueDown()
		
        self.measure {
			let ast = parser.parse(document: bytes)
        }
    }
    
}
