import XCTest
@testable import Cue

class CueTests: XCTestCase {
    func testExample() {
		let str = "Chapter 1 - Test\nA *test* for [every] cue //feature\n> Facsimiles\n---\nCue: Direction.\n^Dual Cue: ~Lyrics\n.Forced"
		
		let html = Cue(str).html()
		
		print(html)
    }


    static var allTests : [(String, (CueTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
