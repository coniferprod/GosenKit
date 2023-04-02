import XCTest
@testable import GosenKit
import SyxPack

final class OscillatorTests: XCTestCase {
    func testOscillator_waveNumberFromBytes() {
        let msb: Byte = 0x02
        let lsb: Byte = 0x66
        if let waveNumber = Wave.numberFromBytes(msb, lsb) {
            XCTAssertEqual(359, waveNumber)
        }
        else {
            XCTFail("Unable to convert MSB and LSB to wave number")
        }
    }
    
    func testOscillator_bytesFromWaveNumber() {
        let bs: ByteArray = [0x02, 0x66]
        let wave = Wave(number: 359)
        XCTAssertEqual(bs, wave.asData())
    }
}
