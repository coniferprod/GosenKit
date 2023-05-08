import XCTest
@testable import GosenKit

final class MultiPatchTests: XCTestCase {
    func testName() {
        let multi = MultiPatch()
        XCTAssertEqual(multi.common.name.value, "NewMulti")
    }

    func testSectionCount() {
        let multi = MultiPatch()
        XCTAssertEqual(multi.sections.count, MultiPatch.sectionCount)
    }
}
