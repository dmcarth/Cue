import XCTest
@testable import Cue

class CueTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Cue().text, "Hello, World!")
    }


    static var allTests : [(String, (CueTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
