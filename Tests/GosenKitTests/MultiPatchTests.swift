import XCTest
@testable import GosenKit
import SyxPack

final class MultiPatchTests: XCTestCase {
    func testName() {
        let multi = MultiPatch()
        XCTAssertEqual(multi.common.name.value, "NewMulti")
    }

    func testSectionCount() {
        let multi = MultiPatch()
        XCTAssertEqual(multi.sections.count, MultiPatch.sectionCount)
    }
    
    // This test depends on a System Exclusive file found in the Resources directory of the test module.
    func testMultiPatch_fromData() {
        if let url = Bundle.module.url(forResource: "Evening3", withExtension: "syx") {
            if let data = try? Data(contentsOf: url) {
                if case let .manufacturerSpecific(_, payload) = Message(data: data.bytes) {
                    if let dumpCommand = DumpCommand(data: payload) {
                        let patchData = ByteArray(payload[dumpCommand.dataLength...])
                        
                        switch MultiPatch.parse(from: patchData) {
                        case .success(let patch):
                            XCTAssert(patch.common.name.value == "Evening3")
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
}
