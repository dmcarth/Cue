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
	
	func testIterator() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		let data = str.utf16
		var generator = data.makeIterator()
		
//		self.measure {
			var wc = 0
			while let _ = generator.next() {
				wc += 1
			}
			print(wc)
//		}
	}
	
	func testBaselineForParsing() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		let uis = [UInt16](str.utf16)
		
//		self.measure {
			var wc = 0
			for _ in uis {
				wc += 1
			}
			print(wc)
//		}
	}
    
    func testPerformanceExample() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		let bytes = [UInt16](str.utf16)
		let parser = CueParser(bytes)
		
        self.measure {
			let ast = parser.parse()
        }
    }
	
	func testCanPass() {
		let str = "Scene 1\n// *This* is a comment\nThis is ą test string.\nJoe: ~And my name is joe\n~Yes that is my name\n^Dave: And now for my turn!\nJoe: That's no fair! I wanted to talk\n"
		let utf16 = [UInt16](str.utf16)
		let down = CueParser(utf16)
		
		let ast = down.parse()
		
		ast.enumerate { (node) in
			print("\(node): \(node.startIndex) \(node.endIndex)")
			
			if node is RawText  {
				let dat = Array(utf16[node.startIndex..<node.endIndex])
				let st = String(utf16CodeUnits: dat, count: dat.count)
				print(st)
			}
		}
	}
	
}
