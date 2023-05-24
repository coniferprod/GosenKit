import XCTest
import SyxPack
@testable import GosenKit

final class ToneMapTests: XCTestCase {
    func testToneMap_initEmpty() {
        let toneMap = ToneMap()
        
        XCTAssertEqual(toneMap.includedCount, 0)
    }
    
    func testToneMap_initFromData() {
        // Create SysEx data for tone map.
        var data = ByteArray(repeating: 0x00, count: ToneMap.dataSize)
        data[0].setBit(0)  // set Tone No. A001 to be included

        if let toneMap = ToneMap(data: data) {
            // Should have one tone included, and it is the first one
            XCTAssertTrue(toneMap.includedCount == 1 && toneMap[0])
        }
        else {
            XCTFail("Unable to initialize tone map from data")
        }
    }
    
    func testToneMap_includes() {
        let toneMap = ToneMap()
        toneMap[63] = true
        XCTAssertTrue(toneMap.includes(tone: 64))
    }
    
    func testToneMap_asData_isRightSize() {
        let toneMap = ToneMap()
        let data = toneMap.asData()
        XCTAssertEqual(data.count, ToneMap.dataSize)
    }
    
    func testToneMap_oneIncluded() {
        let toneMap = ToneMap()
        toneMap[64] = true
        XCTAssertTrue(toneMap[64])
    }
    
    func testToneMap_asData_oneIncluded() {
        // Create a SysEx tone map and set A120 to be included.
        // In the MIDI spec section 3.1.1, the example states
        // that <sub18> bit0=1 means "Tone No.A120 included".
        // Sub-bytes are numbered from one in the spec, here from zero.
        var data = ByteArray(repeating: 0x00, count: ToneMap.dataSize)
        data[17].setBit(0)

        if let toneMap = ToneMap(data: data) {
            XCTAssertTrue(toneMap[119])  // tones numbered here from zero
        }
        else {
            XCTFail("Unable to create tone map")
        }
    }
}

