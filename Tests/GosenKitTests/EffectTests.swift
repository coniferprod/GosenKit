import XCTest
@testable import GosenKit

final class EffectTests: XCTestCase {
    func testEffectSettings_fromData() {
        /*
        guard let patchURL = Bundle.module.url(forResource: "PowerK5K", withExtension: "syx") else {
            XCTFail("Test patch file not found")
            return
        }
        
        guard let data = try? Data(contentsOf: patchURL) else {
            XCTFail("Unable to read test patch file")
            return
        }

        let offset = 10 // 9 bytes for single patch SysEx header, then one-byte checksum
        // The effect data is 31 bytes right after the checksum.
        let effectData = data.subdata(in: offset..<offset+31).bytes
        */
        
        // Can't get loading test patch from bundle to work reliably,
        // so using the actual bytes:
        let effectData: ByteArray = [0x02, 0x00, 0x46, 0x14, 0x1A, 0x00, 0x00, 0x1D,
                                     0x64, 0x64, 0x00, 0x00, 0x00, 0x15, 0x63, 0x06,
                                     0x4A, 0x00, 0x00, 0x10, 0x18, 0x55, 0x04, 0x55,
                                     0x02, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00]

        let effectSettings = EffectSettings(data: effectData)

        XCTAssertEqual(effectSettings.algorithm, 3)  // original byte is 0x02, algorithm values are 1~4
        
    }
    
    func testEffectDefinition_fromData() {
        let data: ByteArray = [0x00, 0x46, 0x14, 0x1A, 0x00, 0x00]
        let effectDefinition = EffectDefinition(data: data)
        XCTAssertEqual(effectDefinition.kind, .hall1)

    }
    
}

