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
		let str = "Scene 1 - Test\nHarry: (O.S.) I **hate** ice-cream.\nSamantha: You monster! // too much"
		
		let cue = Cue(str)
		
		cue.dump()
	}
	
	func testHamlet() {
		let url = Bundle(for: CocoaCueTests.self).url(forResource: "hamlet", withExtension: "txt")!
		let str = try! String(contentsOf: url)
//		var str = ""
//		for _ in 0..<18 {
//			str += base
//		}
//		str += str
//		str += str
//		str += str
//		str += str
		
		measure {
			_ = Cue(str)
		}
	}
	
    func testBenchmark() {
        let url = Bundle(for: CocoaCueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		var str = try! String(contentsOf: url)
//		str += str
//		str += str
//		str += str
//		str += str
//		str += str
		
        self.measure {
            _ = Cue(str)
        }
    }
    
}
