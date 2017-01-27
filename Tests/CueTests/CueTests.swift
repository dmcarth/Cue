import XCTest
@testable import Cue

class CueTests: XCTestCase {
	
    func testPerformanceExample() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: fileURL)
		
		self.measure {
			_ = Cue(str)
		}
	}

    static var allTests : [(String, (CueTests) -> () throws -> Void)] {
        return [
            ("testPerformanceExample", testPerformanceExample),
        ]
    }
	
}
