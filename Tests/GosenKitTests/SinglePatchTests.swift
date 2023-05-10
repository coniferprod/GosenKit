import XCTest
@testable import GosenKit

final class SinglePatchTests: XCTestCase {
    func testName() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.name.value, "NewSound")
    }

    func testDefaultSourceCount() {
        let single = SinglePatch()
        XCTAssertEqual(single.common.sourceCount, single.sources.count)
    }
    
    // This test depends on a System Exclusive file found in the Resources directory of the test module.
    func testSinglePatch_fromData() {
        if let patchURL = Bundle.module.url(forResource: "PowerK5K", withExtension: "syx") {
            if let patchData = try? Data(contentsOf: patchURL) {
                switch SinglePatch.parse(from: patchData.bytes) {
                case .success(let patch):
                    XCTAssert(patch.common.name.value == "PowerK5K")
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        }
    }
        
    func testPatchName_truncated() {
        let longName = PatchName("MoreThan8Chars")
        XCTAssert(longName.value.count == PatchName.length)
    }
    
    func testPatchName_padded() {
        let shortName = PatchName("Name")
        XCTAssert(shortName.value.count == PatchName.length)
        XCTAssert(shortName.value.last! == " ")
    }
}
