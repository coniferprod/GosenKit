import XCTest
@testable import GosenKit

final class SinglePatchTests: XCTestCase {
    func testName() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.name, "NewSound")
    }

    func testDefaultSourceCount() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.sourceCount, single.sources.count)
    }
    
    /*
    func testSinglePatch_asData() {
        var single = SinglePatch()
        
        var source1 = single.sources[0]
        source1.oscillator.wave = Wave.additive
        
        var add1 = AdditiveKit()
        let ff = FormantFilter.Bands(
            data: ByteArray([
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 127, 127, 127, 127, 127, 127, 127,
                127, 126, 127, 127, 127, 127, 127, 126,
                
                126, 126, 124, 124, 124, 123, 122, 121,
                120, 120, 118, 118, 117, 116, 115, 114,
                113, 110, 109, 108, 107, 106, 105, 104,
                103, 101, 100, 98, 96, 95, 92, 91,
                88, 86, 84, 82, 80, 78, 76, 74,
                72, 68, 66, 63, 61, 57, 56, 54,
                50, 48, 46, 42, 39, 35, 31, 29,
                26, 23, 18, 14, 11, 5, 2, 0
            ])
        )
        add1.bands = ff

        let levels = HarmonicLevels(
            soft: [
                127, 124, 121, 118, 115, 112, 109, 106,
                103, 100, 97, 94, 91, 88, 85, 82,
                79, 76, 73, 70, 67, 64, 61, 58,
                55, 52, 49, 46, 43, 40, 37, 34,
                31, 28, 25, 22, 19, 16, 13, 10,
                7, 4, 1, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0
            ],
            loud: [
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0
            ]
        )

        add1.levels = levels

        let envelope = HarmonicEnvelope(
            segments: [
                HarmonicEnvelope.Segment(rate: 125, level: 63),
                HarmonicEnvelope.Segment(rate: 92, level: 63),
                HarmonicEnvelope.Segment(rate: 49, level: 63),
                HarmonicEnvelope.Segment(rate: 39, level: 49)
            ],
            loop: .off
        )

        for i in 0..<AdditiveKit.harmonicCount {
            add1.envelopes[i] = envelope
        }
        
        single.additiveKits["s1"] = add1

        print(single)
        XCTAssertEqual(single.asData(), [])
    }
    */
    
    // This test depends on a System Exclusive file found in the Resources directory of the test module.
    func testSinglePatch_fromData() {
        if let patchURL = Bundle.module.url(forResource: "PowerK5K", withExtension: "syx") {
            if let patchData = try? Data(contentsOf: patchURL) {
                let patch = SinglePatch(data: patchData.bytes)
                XCTAssert(patch.common.name == "PowerK5K")
            }
        }
    }
    
    func testPatchName_truncate() {
        @PatchName var longName = "MoreThan8Chars"
        XCTAssert(longName.count == PatchName.length)
    }
    
    func testPatchName_pad() {
        @PatchName var shortName = "Name"
        XCTAssert(shortName.count == PatchName.length)
        XCTAssert(shortName.last! == " ")
    }
}
