import XCTest
@testable import Cue

class CueTests: XCTestCase {
    func testExample() {
		let str = "Chapter 1 - Test\nA *test* for [every] cue //feature\n> Facsimiles\n---\n\n\nCue: Direction.\n^Dual Cue: ~Lyrics\n.Forced"
		
		let html = Cue(str).html()
		
		print(html)
    }
	
	func testBenchmark() {
		let url = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: url)
		
		measure {
			_ = Cue(str)
		}
	}

    static var allTests : [(String, (CueTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
