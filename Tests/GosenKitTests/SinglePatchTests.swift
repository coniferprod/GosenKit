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

}
