import XCTest
@testable import GosenKit

final class GosenKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(GosenKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
