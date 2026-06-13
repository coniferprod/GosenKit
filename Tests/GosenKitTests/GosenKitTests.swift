import XCTest
@testable import GosenKit

import SyxPack
import ByteKit


final class GosenKitTests: XCTestCase {
    func testKeyNumber() {
        let key = Key(name: "C3")
        XCTAssertEqual(key.note, 60)
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
}
