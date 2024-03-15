import XCTest
@testable import GosenKit
import SyxPack

final class OscillatorTests: XCTestCase {
    func testOscillator_waveNumberFromBytes() {
        let msb: Byte = 0x02
        let lsb: Byte = 0x66
        
        switch Wave.parse(msb: msb, lsb: lsb) {
        case .success(let wave):
            XCTAssertEqual(Wave.pcm(359), wave)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testOscillator_bytesFromWaveNumber() {
        let bs: ByteArray = [0x02, 0x66]
        let wave = Wave.pcm(359)
        XCTAssertEqual(bs, wave.asData())
    }
}
