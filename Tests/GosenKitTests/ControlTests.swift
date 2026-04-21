import XCTest
@testable import GosenKit

final class ControlTests: XCTestCase {
    func testMacroController() {
        var mc = MacroController()
        
        mc.destination1 = .pitchOffset
        mc.depth1 = ControlDepth(0)
        mc.destination2 = .pitchOffset
        mc.depth2 = ControlDepth(0)

    }

}
