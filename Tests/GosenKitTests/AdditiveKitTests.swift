import XCTest
@testable import GosenKit

final class AdditiveKitTests: XCTestCase {
    func testAsData() {
        let add = AdditiveKit()  // use default settings
        
        let data = add.asData()
        
        XCTAssertEqual(data.count, AdditiveKit.dataSize)
    }
}
