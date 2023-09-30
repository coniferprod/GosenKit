import XCTest
@testable import GosenKit

final class AmplifierTests: XCTestCase {
    func testEnvelope() {
        let env = Amplifier.Envelope(attackTime: 0, decay1Time: 0, decay1Level: 127, decay2Time: 0, decay2Level: 127, releaseTime: 0)
        XCTAssertEqual(env, Amplifier.Envelope(attackTime: 0, decay1Time: 0, decay1Level: 127, decay2Time: 0, decay2Level: 127, releaseTime: 0))
    }
    
    func testEnvelope_asData() {
        let env = Amplifier.Envelope(attackTime: 0, decay1Time: 0, decay1Level: 127, decay2Time: 0, decay2Level: 127, releaseTime: 0)
        XCTAssertEqual(env.asData(), [0, 0, 127, 0, 127, 0])
    }
    
    func testKeyScalingControl_asData() {
        let control = Amplifier.Modulation.KeyScalingControl()
        XCTAssertEqual(control.asData(), [64, 64, 64, 64])
    }
    
    func testVelocityControl_asData() {
        let control = Amplifier.Modulation.VelocityControl()
        XCTAssertEqual(control.asData(), [0, 64, 64, 64])
    }
    
    func test_asData() {
        var amp = Amplifier()
        amp.velocityCurve = VelocityCurve(5)
        XCTAssertEqual(amp.asData()[0], 4)
    }
}
