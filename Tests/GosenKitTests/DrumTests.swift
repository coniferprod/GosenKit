import XCTest
import SyxPack
@testable import GosenKit

final class DrumTests: XCTestCase {

    func test_DrumInstrument_fromData() {
        // Kawai K5000W Drum Instrument I01
        let data: ByteArray = [
            // 0xf0, 0x40, 0x00,
            
            // Dump header
            // 0x20, 0x00, 0x0a, 0x11,
            // 0x00,  // sub1 = 0x00 = INST No. 01
                        
            // Drum instrument = checksum + common + source
            
            0x64,  // checksum
            
            // Common data
            0x00,  // dummy
            0x7f,  // volume
            0x02,  // Gate
            0x00,  // excl group
            0x03,  // effect path
            0x01,  // src_mute (fixed at 0x01)
            
            // Source data
            0x72,  // Volume
            0x40,  // Pan
            0x00, 0x01,  // wave No. MSB and LSB
            0x40,  // DCO coarse
            0x40,  // DCO fine
            0x40, 0x40, 0x40,  // DCO Pitch Env
            0x00,  // DCF cutoff
            0x7f,  // DCF cutoff velo depth
            0x00, 0x00, 0x7f, 0x0a,  // DCA env
            0x3f, 0x40, 0x40,  // DCA vel sens
            
            // 0xf7
        ]
        
        switch DrumInstrument.parse(from: data) {
        case .success(let instrument):
            XCTAssertEqual(instrument.common.volume.value, 127)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func test_DrumKit_fromData() {
        // Kawai K5000W Kit from Single B
        let data: ByteArray = [
            // 0xf0, 0x40, 0x00, 0x20, 0x00, 0x0a, 0x10,
            
            0x2a,  // checksum
            
            // Effect data
            0x01, 0x00,
            0x00, 0x03, 0x14, 0x2d, 0x27, 0x0b, 0x00, 0x00, 0x05, 0x09,
            0x00, 0x0b, 0x00, 0x00, 0x05, 0x09, 0x00, 0x0b, 0x00, 0x00,
            0x05, 0x09, 0x00, 0x0b, 0x00, 0x00, 0x05, 0x09, 0x00, 0x40,
            0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x01, 0x54, 0x65, 0x63,
            0x68, 0x6e, 0x6f, 0x20, 0x20, 0x7f, 0x02, 0x00, 0x40, 0x02,
            0x00, 0x40, 0x00, 0x01, 0x00, 0x07, 0x00, 0x09, 0x00, 0x0b,
            0x00, 0x10, 0x00, 0x1a, 0x00, 0x1b, 0x00, 0x1d, 0x00, 0x1f,
            0x00, 0x26, 0x00, 0x15, 0x00, 0x16, 0x00, 0x17, 0x00, 0x2d,
            0x01, 0x56, 0x00, 0x2e, 0x00, 0x62, 0x00, 0x48, 0x00, 0x61,
            0x00, 0x49, 0x00, 0x60, 0x00, 0x4a, 0x00, 0x5f, 0x00, 0x5e,
            0x01, 0x04, 0x00, 0x5d, 0x01, 0x0f, 0x01, 0x12, 0x01, 0x07,
            0x01, 0x13, 0x01, 0x11, 0x01, 0x14, 0x00, 0x7c, 0x01, 0x26,
            0x01, 0x06, 0x01, 0x27, 0x01, 0x28, 0x01, 0x20, 0x01, 0x21,
            0x01, 0x22, 0x01, 0x29, 0x01, 0x2a, 0x01, 0x16, 0x01, 0x17,
            0x01, 0x1a, 0x01, 0x1b, 0x01, 0x19, 0x01, 0x1e, 0x01, 0x4f,
            0x01, 0x50, 0x00, 0x05, 0x00, 0x06, 0x00, 0x08, 0x00, 0x0a,
            0x00, 0x0c, 0x00, 0x0e, 0x00, 0x18, 0x00, 0x1c, 0x00, 0x1e,
            0x00, 0x20, 0x00, 0x21, 0x00, 0x24, 0x00, 0x25, 0x00, 0x00,
            
            // 0xf7
        ]
        
        switch DrumKit.parse(from: data) {
        case .success(let kit):
            XCTAssertEqual(kit.common.name, PatchName("Techno"))
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}
