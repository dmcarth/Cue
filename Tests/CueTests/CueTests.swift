import XCTest
@testable import Cue

class CueTests: XCTestCase {
	
    func testPerformanceExample() {
		let fileURL = Bundle(for: CueTests.self).url(forResource: "war+peace", withExtension: "txt")!
		var str = try! String(contentsOf: fileURL)
		
		let bytes = [UInt16](str.utf16)
		
		self.measure {
			_ = Cue(input: bytes, codec: UTF16.self)
		}
	}

    static var allTests : [(String, (CueTests) -> () throws -> Void)] {
        return [
            ("testPerformanceExample", testPerformanceExample),
        ]
    }
	
}
