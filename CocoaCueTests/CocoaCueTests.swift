//
//  CocoaCueTests.swift
//  CocoaCueTests
//
//  Created by Dylan McArthur on 9/5/17.
//  Copyright © 2017 Dylan McArthur. All rights reserved.
//

import XCTest
@testable import CocoaCue

class CocoaCueTests: XCTestCase {
	
	func testOutline() {
		let str = "Scene 1 - Test\nHarry: (O.S.) I **hate** ice-cream.\nSamantha: You monster! // too much\n> Hallo\n> Und hi!"
		
		let cue = Cue(str)
		
		cue.dump()
	}
	
	func testHamlet() {
		let url = Bundle(for: CocoaCueTests.self).url(forResource: "hamlet", withExtension: "txt")!
		let str = try! String(contentsOf: url)
		
		measure {
			_ = Cue(str)
		}
	}
	
    func testBenchmark() {
        let url = Bundle(for: CocoaCueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: url)
		
		let buff = UnsafeMutablePointer(mutating: (str as NSString).utf8String)
		let len = strlen(buff)
		
        self.measure {
			_ = Parser(cString: buff, len: len)
        }
    }
    
}
