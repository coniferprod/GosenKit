/*
 From http://www.optimolch.de/jens.groh/K5000/
 
 File Size    Number Of Sources
  254 bytes    2 PCM
  340 bytes    3 PCM
  426 bytes    4 PCM
  512 bytes    5 PCM
  598 bytes    6 PCM
 1060 bytes    1 PCM + 1 ADD
 1146 bytes    2 PCM + 1 ADD
 1232 bytes    3 PCM + 1 ADD
 1318 bytes    4 PCM + 1 ADD
 1404 bytes    5 PCM + 1 ADD
 1866 bytes            2 ADD
 1952 bytes    1 PCM + 2 ADD
 2038 bytes    2 PCM + 2 ADD
 2124 bytes    3 PCM + 2 ADD
 2210 bytes    4 PCM + 2 ADD
 2758 bytes            3 ADD
 2844 bytes    1 PCM + 3 ADD
 2930 bytes    2 PCM + 3 ADD
 3016 bytes    3 PCM + 3 ADD
 3650 bytes            4 ADD
 3736 bytes    1 PCM + 4 ADD
 3822 bytes    2 PCM + 4 ADD
 4542 bytes            5 ADD
 4628 bytes    1 PCM + 5 ADD
 5434 bytes            6 ADD
 */

import XCTest
@testable import GosenKit

final class SystemExclusiveTests: XCTestCase {
    func testSystemExclusiveHeader() {
        let header = SystemExclusiveHeader(manufacturerIdentifier: 0x40, channel: 0, function: SystemExclusiveFunction.oneBlockDump.rawValue, group: 0x00, machineIdentifier: 0x0a, substatus1: 0x00, substatus2: 0x00)
    
        XCTAssertEqual(header.asData(), [0xf0, 0x40, 0x00, 0x20, 0x00, 0x0a, 0x00, 0x00])
    }
    
    func testSinglePatch_asSystemExclusiveMessage() {
        let single = SinglePatch()
        let data = single.asSystemExclusiveMessage(channel: 0, bank: "a")
        
        XCTAssertEqual(data.count, 254 + 8 + 1)
    }
    
    func testSinglePatch_2PCM() {
        let single = SinglePatch()        
        let data = single.asData()
        XCTAssertEqual(data.count, 254)
    }
    
    func testSinglePatch_3PCM() {
        var single = SinglePatch()
        single.common.sourceCount = 3
        single.sources.append(Source())
        let data = single.asData()
        XCTAssertEqual(data.count, 340)
    }
    
    func testSinglePatch_4PCM() {
        var single = SinglePatch()
        single.common.sourceCount = 4
        single.sources.append(Source())
        single.sources.append(Source())
        let data = single.asData()
        XCTAssertEqual(data.count, 426)
    }

    func testSinglePatch_5PCM() {
        var single = SinglePatch()
        single.common.sourceCount = 5
        single.sources.append(Source())
        single.sources.append(Source())
        single.sources.append(Source())
        let data = single.asData()
        XCTAssertEqual(data.count, 512)
    }

    func testSinglePatch_6PCM() {
        var single = SinglePatch()
        single.common.sourceCount = 6
        single.sources.append(Source())
        single.sources.append(Source())
        single.sources.append(Source())
        single.sources.append(Source())
        let data = single.asData()
        XCTAssertEqual(data.count, 598)
    }
    
    func testSinglePatch_1PCM_1ADD() {
        var single = SinglePatch()
        var addSource = Source()
        addSource.oscillator.wave = Wave.additive
        single.additiveKits["s2"] = AdditiveKit()
        single.sources[1] = addSource
        let data = single.asData()
        XCTAssertEqual(data.count, 1060)
    }
    
    func testSinglePatch_2PCM_1ADD() {
        var single = SinglePatch()
        single.common.sourceCount = 3
        var addSource = Source()
        addSource.oscillator.wave = Wave.additive
        single.additiveKits["s3"] = AdditiveKit()
        single.sources.append(addSource)
        let data = single.asData()
        XCTAssertEqual(data.count, 1146)
    }
    
    func testSinglePatch_6ADD() {
        var single = SinglePatch()
        single.common.sourceCount = 6
        
        var source1 = Source()
        source1.oscillator.wave = Wave.additive
        single.additiveKits["s1"] = AdditiveKit()
        single.sources[0] = source1
        
        var source2 = Source()
        source2.oscillator.wave = Wave.additive
        single.additiveKits["s2"] = AdditiveKit()
        single.sources[1] = source2
        
        var source3 = Source()
        source3.oscillator.wave = Wave.additive
        single.additiveKits["s3"] = AdditiveKit()
        single.sources.append(source3)
        
        var source4 = Source()
        source4.oscillator.wave = Wave.additive
        single.additiveKits["s4"] = AdditiveKit()
        single.sources.append(source4)
        
        var source5 = Source()
        source5.oscillator.wave = Wave.additive
        single.additiveKits["s5"] = AdditiveKit()
        single.sources.append(source5)
        
        var source6 = Source()
        source6.oscillator.wave = Wave.additive
        single.additiveKits["s6"] = AdditiveKit()
        single.sources.append(source6)
        
        let data = single.asData()
        XCTAssertEqual(data.count, 5434)
    }

}
