import XCTest
@testable import GosenKit

import SyxPack
import ByteKit


final class EffectTests: XCTestCase {
    func testEffectSettings_fromData() {
        // Effect section from common data (31 bytes) from PowerK5K:
        let effectData: ByteArray = [
            0x02,  // algorithm
            0x00, 0x46, 0x14, 0x1A, 0x00, 0x00,  // reverb
            0x1D, 0x64, 0x64, 0x00, 0x00, 0x00,  // effect 1
            0x15, 0x63, 0x06, 0x4A, 0x00, 0x00,  // effect 2
            0x10, 0x18, 0x55, 0x04, 0x55, 0x02,  // effect 3
            0x0B, 0x00, 0x00, 0x00, 0x00, 0x00   // effect 4
        ]

        switch EffectSettings.parse(from: effectData) {
        case .success(let effect):
            XCTAssertEqual(effect.algorithm.value, 3)  // original byte is 0x02, algorithm values are 1~4
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testEffectDefinition_fromData() {
        let data: ByteArray = [0x00, 0x46, 0x14, 0x1A, 0x00, 0x00]
        
        switch EffectDefinition.parse(from: data) {
        case .success(let effect):
            XCTAssertEqual(effect.kind, .hall1)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testEffectSettings_ABankINT_001() {
        let data: ByteArray = [
            0x00,
            0x08, 0x14, 0x10, 0x14, 0x0e, 0x0e,
            0x11, 0x3c, 0x21, 0x21, 0x08, 0x00,
            0x24, 0x00, 0x05, 0x2b, 0x0d, 0x24,
            0x1a, 0x17, 0x23, 0x28, 0x0e, 0x21,
            0x0b, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]
        
        switch EffectSettings.parse(from: data) {
        case .success(let effectSettings):
            XCTAssertEqual(effectSettings.algorithm.value, 1)  // original byte is 0x00, algorithm values are 1~4
            XCTAssertEqual(effectSettings.reverb.kind, .plate3)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testEffectSettings_ABankINT_017() {
        let data: ByteArray = [
            0x00, // Algorithm
            0x00, 0x00, 0x1C, 0x1A, 0x10, 0x3C, // Reverb
            0x2A, 0x3C, 0x0C, 0x0C, 0x27, 0x01, // Effect1
            0x11, 0x02, 0x69, 0x17, 0x00, 0x00, // Effect2
            0x23, 0x00, 0x06, 0x4B, 0x00, 0x00, // Effect3
            0x2A, 0x00, 0x0C, 0x0C, 0x00, 0x00, // Effect4
            // 41 41 40 40 3E 40 41 = GEQ
            // 00 = drum_mark
            //"50 79 70 65 72 20 20 20" = "Pyper   "
        ]
        switch EffectSettings.parse(from: data) {
        case .success(let effectSettings):
            XCTAssertEqual(effectSettings.algorithm.value, 1)  // original byte is 0x00, algorithm values are 1~4
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testReverb() {
        let data: ByteArray = [
            0x00, 0x00, 0x1C, 0x1A, 0x10, 0x3C, // Reverb
        ]
        switch EffectDefinition.parse(from: data) {
        case .success(let reverb):
            XCTAssertEqual(reverb.kind, EffectDefinition.Kind.hall1)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}
