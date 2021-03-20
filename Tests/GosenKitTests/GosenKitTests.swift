import XCTest
@testable import GosenKit

final class GosenKitTests: XCTestCase {
    func testNoteName() {
        XCTAssertEqual(noteName(for: 60), "C4")
    }

    func testKeyNumber() {
        XCTAssertEqual(keyNumber(for: "C4"), 60)
    }
    
    func testNextByte() {
        let data: ByteArray = [0xde, 0xad, 0xbe, 0xef]
        var offset = 0
        var b = data.next(&offset)
        XCTAssertEqual(b, 0xde)
        XCTAssertEqual(offset, 1)
        b = data.next(&offset)
        XCTAssertEqual(b, 0xad)
        XCTAssertEqual(offset, 2)
    }

    static var allTests = [
        ("testNoteName", testNoteName),
        ("testKeyNumber", testKeyNumber),
    ]
}
