import XCTest
@testable import GosenKit

final class GosenKitTests: XCTestCase {
    func testNoteName() {
        XCTAssertEqual(noteName(for: 60), "C4")
    }

    func testKeyNumber() {
        XCTAssertEqual(keyNumber(for: "C4"), 60)
    }
    

    static var allTests = [
        ("testNoteName", testNoteName),
        ("testKeyNumber", testKeyNumber),
    ]
}
