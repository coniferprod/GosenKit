import XCTest
@testable import GosenKit

final class AdditiveKitTests: XCTestCase {
    func testAsData() {
        var singlePatch = SinglePatch()
        singlePatch.common.name = "FooBar"
        singlePatch.common.volume = 115
        
        var source1 = singlePatch.sources[0]
        source1.oscillator.waveType = .additive
        source1.oscillator.waveNumber = 512
        
        var add1 = AdditiveKit()  // use default settings
        
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
        
        var levels = HarmonicLevels()
        levels.soft = [
                        127, 0, 0, 0, 120, 0, 0, 0,
                        105, 0, 0, 0, 102, 0, 0, 0,
                        97, 0, 0, 0, 89, 0, 0, 0,
                        0, 0, 0, 0, 78, 0, 0, 0,
                        64, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
                    ]
        levels.loud = [
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0
                    ]
        
        add1.levels = levels
        
        var envelope = HarmonicEnvelope()
        envelope.segment0 = HarmonicEnvelope.Segment(rate: 125, level: 63)
        envelope.segment1 = HarmonicEnvelope.Segment(rate: 92, level: 63)
        envelope.segment2 = HarmonicEnvelope.Segment(rate: 49, level: 63)
        envelope.segment3 = HarmonicEnvelope.Segment(rate: 39, level: 49)
        envelope.loopType = .off
            
        for i in 0..<AdditiveKit.harmonicCount {
            add1.envelopes[i] = envelope
        }
        singlePatch.additiveKits["s1"] = add1
        print(singlePatch)
        
        XCTAssertEqual(add1.asData(), [])
        
        
    }
}
