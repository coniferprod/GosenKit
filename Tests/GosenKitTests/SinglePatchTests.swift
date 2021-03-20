import XCTest
@testable import GosenKit

final class SinglePatchTests: XCTestCase {
    func testSinglePatchName() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.name, "NewSound")
    }

    func testAmplifierEnvelope() {
        let env = AmplifierEnvelope(attackTime: 0, decay1Time: 0, decay1Level: 127, decay2Time: 0, decay2Level: 127, releaseTime: 0)
        XCTAssertEqual(env.attackTime, 0)
        XCTAssertEqual(env.decay1Time, 0)
        XCTAssertEqual(env.decay1Level, 127)
        XCTAssertEqual(env.decay2Time, 0)
        XCTAssertEqual(env.decay2Level, 127)
    }
    
    func testAmplifierEnvelope_asData() {
        let env = AmplifierEnvelope(attackTime: 0, decay1Time: 0, decay1Level: 127, decay2Time: 0, decay2Level: 127, releaseTime: 0)
        XCTAssertEqual(env.asData(), [0, 0, 127, 0, 127, 0])
    }
    
    func testAmplifierKeyScalingControl_asData() {
        let control = AmplifierKeyScalingControl()
        XCTAssertEqual(control.asData(), [64, 64, 64, 64])
    }
    
    func testAmplifierVelocityControl_asData() {
        let control = AmplifierVelocityControl()
        XCTAssertEqual(control.asData(), [0, 64, 64, 64])
    }
    
    func testAmplifier_asData() {
        var amp = Amplifier()
        amp.velocityCurve = 5
        XCTAssertEqual(amp.asData()[0], 4)
    }
    
    func testDefaultSourceCount() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.sourceCount, single.sources.count)
    }
    
    func testSinglePatch_asData() {
        var single = SinglePatch()
        
        var source1 = single.sources[0]
        source1.oscillator.waveType = .additive
        source1.oscillator.waveNumber = 512
        
        var add1 = AdditiveKit()
        let ff = FormantFilterBands(
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
                            127, 124, 121, 118, 115, 112, 109, 106,
                            103, 100, 97, 94, 91, 88, 85, 82,
                            79, 76, 73, 70, 67, 64, 61, 58,
                            55, 52, 49, 46, 43, 40, 37, 34,
                            31, 28, 25, 22, 19, 16, 13, 10,
                            7, 4, 1, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0
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
        envelope.segment0 = HarmonicEnvelopeSegment(rate: 125, level: 63)
        envelope.segment1 = HarmonicEnvelopeSegment(rate: 92, level: 63)
        envelope.segment2 = HarmonicEnvelopeSegment(rate: 49, level: 63)
        envelope.segment3 = HarmonicEnvelopeSegment(rate: 39, level: 49)
        envelope.loopType = .off

        for i in 0..<AdditiveKit.harmonicCount {
            add1.envelopes[i] = envelope
        }
        
        single.additiveKits["s1"] = add1

        print(single)
        XCTAssertEqual(single.asData(), [])

    }
    
}
