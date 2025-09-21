import XCTest
@testable import GosenKit
import SyxPack
import ByteKit

final class RangedIntTests: XCTestCase {
    func test_sameValuesAreEqual() {
        XCTAssert(Volume(1) == Volume(1))
    }
    
    func test_differentValuesAreNotEqual() {
        XCTAssert(Volume(1) != Volume(2))
    }
    
    func test_invalidValueIsClamped() {
        let v = Volume(Volume.range.upperBound + 1)
        XCTAssert(v.value == Volume.range.upperBound)
    }
}

