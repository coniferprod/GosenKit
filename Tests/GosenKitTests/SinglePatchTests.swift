import XCTest
@testable import GosenKit

final class SinglePatchTests: XCTestCase {
    func testName() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.name.name, "NewSound")
    }

    func testDefaultSourceCount() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.sourceCount, single.sources.count)
    }
    
    // This test depends on a System Exclusive file found in the Resources directory of the test module.
    func testSinglePatch_fromData() {
        if let patchURL = Bundle.module.url(forResource: "PowerK5K", withExtension: "syx") {
            if let patchData = try? Data(contentsOf: patchURL) {
                let patch = SinglePatch(data: patchData.bytes)
                XCTAssert(patch.common.name.name == "PowerK5K")
            }
        }
    }
        
    func testPatchName_truncated() {
        let longName = PatchName("MoreThan8Chars")
        XCTAssert(longName.name.count == PatchName.length)
    }
    
    func testPatchName_padded() {
        let shortName = PatchName("Name")
        XCTAssert(shortName.name.count == PatchName.length)
        XCTAssert(shortName.name.last! == " ")
    }
}
