import XCTest
@testable import GosenKit

import SyxPack
import ByteKit


final class GosenKitTests: XCTestCase {
    func testVolumeInit() {
        let volume: Volume = 50  // test ExpressibleByIntegerLiteral
        XCTAssertEqual(volume.value, 50)
    }
    
    func testVolumeDescription() {
        let volume: Volume = 50
        XCTAssertEqual("\(volume)", "50")
    }
    
    func testKeyName() {
        let key = Key(note: MIDINote(60))
        XCTAssertEqual(key.name, "C3")
    }

    func testKeyNumber() {
        let key = Key(name: "C3")
        XCTAssertEqual(key.note.value, 60)
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
        ("testkeyName", testKeyName),
        ("testKeyNumber", testKeyNumber),
    ]
    
    func test_DefaultValueIsInRange() {
        let gain = Gain()
        XCTAssertEqual(gain.value, 1)
    }
}
