import XCTest
import SyxPack
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
        if let url = Bundle.module.url(forResource: "PowerK5K", withExtension: "syx") {
            if let data = try? Data(contentsOf: url) {
                if case let .manufacturerSpecific(_, payload) = Message(data: data.bytes) {
                    if let dumpCommand = DumpCommand(data: payload) {
                        let patchData = ByteArray(payload[dumpCommand.dataLength...])
                        
                        switch SinglePatch.parse(from: patchData) {
                        case .success(let patch):
                            XCTAssert(patch.common.name.value == "PowerK5K")
                        case .failure(let error):
                            XCTFail("\(error)")
                        }
                    }
                }
            }
        }
        else {
            XCTFail("Unable to read patch data from resources")
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
