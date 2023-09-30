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
import SyxPack

final class SystemExclusiveTests: XCTestCase {
    func testSystemExclusive_header() {
        let header = SystemExclusive.Header(
            channel: MIDIChannel(1),
            function: SystemExclusive.Function.oneBlockDump,
            group: 0x00,
            machineIdentifier: 0x0a,
            substatus1: 0x00,
            substatus2: BankIdentifier.a.rawValue)
        
        XCTAssertEqual(header.asData(), [0x00, 0x20, 0x00, 0x0a, 0x00, 0x00])
    }
    
    func testSinglePatch_asSystemExclusiveMessage() {
        let single = SinglePatch()
        let data = single.asSystemExclusiveMessage(channel: MIDIChannel(1), bank: .a)
        
        XCTAssertEqual(data.count, 254 + 6)
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

    // The test dump commands are organized like section 5.3 "Dump command table"
    // in the K5000 MIDI implementation document (p. 43).
    
    // K5000W
    // One
    let oneADDBankA: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x00, 0x00 ] // One ADD Bank A (see 3.1.1b)
    let onePCMBankB: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x01, 0x00 ] // One PCM Bank B (see 3.1.1d)
    let oneExpBankE: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x03, 0x00 ] // One Exp Bank E ((see 3.1.1m)
    let oneExpBankF: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x04, 0x00 ] // One Exp Bank F (see 3.1.1o)
    let oneDrumKit: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x10 ]
    let oneDrumInstrument: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x11, 0x00 ]
    let oneCombi: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x20, 0x00 ] // One Multi/Combi (see 3.1.1i)

    // Block
    let blockADDBankA: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x00, 0x00,
                                     /* tone map of 19 bytes follows */
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
    let blockPCMBankB: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x00, 0x01 ]
    let blockExpBankE: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x00, 0x03,
                                     /* tone map of 19 bytes follows */
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
    let blockExpBankF: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x00, 0x04,
                                     /* tone map of 19 bytes follows */
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
    let blockDrumInstrument: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x11 ]
    let blockCombi: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x20 ]

    // K5000S/R
    // One
    // oneADDBankA is the same as on the K5000W
    let oneADDBankD: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x02, 0x00 ] // One ADD Bank D (see 3.1.1k)
    // oneExpBankE and oneExpBankF are the same as on the K5000W
    // oneMulti is the same as oneCombi on the K5000W
    
    // Block
    // blockADDBankA is the same as on the K5000W
    let blockADDBankD: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x00, 0x02,
                                     /* tone map of 19 bytes follows */
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
    // blockExpBankE and blockExpBankF are the same as on the K5000W
    // blockMulti is the same as blockCombi on the K5000W
    
    func testDumpCommand_oneADDBankA() {
        let actual = DumpCommand(data: oneADDBankA)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .a, kind: .single, subBytes: [0x00])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_onePCMBankB() {
        let actual = DumpCommand(data: onePCMBankB)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .b, kind: .single, subBytes: [0x00])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_oneExpBankE() {
        let actual = DumpCommand(data: oneExpBankE)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .e, kind: .single, subBytes: [0x00])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_oneExpBankF() {
        let actual = DumpCommand(data: oneExpBankF)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .f, kind: .single, subBytes: [0x00])
        XCTAssertEqual(actual, expected)
    }

    func testDumpCommand_oneDrumKit() {
        let actual = DumpCommand(data: oneDrumKit)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .none, kind: .drumKit, subBytes: [])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_oneDrumInstrument() {
        let actual = DumpCommand(data: oneDrumInstrument)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .none, kind: .drumInstrument, subBytes: [])
        XCTAssertEqual(actual, expected)
    }
        
    func testDumpCommand_oneCombi() {
        let actual = DumpCommand(data: oneCombi)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .none, kind: .multi, subBytes: [0x00])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_blockADDBankA() {
        let actual = DumpCommand(data: blockADDBankA)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .a, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_blockPCMBankB() {
        let actual = DumpCommand(data: blockPCMBankB)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .b, kind: .single, subBytes: [])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_blockExpBankE() {
        let actual = DumpCommand(data: blockExpBankE)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .e, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_blockExpBankF() {
        let actual = DumpCommand(data: blockExpBankF)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .f, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_blockDrumInstrument() {
        let actual = DumpCommand(data: blockDrumInstrument)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .none, kind: .drumInstrument, subBytes: [])
        XCTAssertEqual(actual, expected)
    }

    func testDumpCommand_blockCombi() {
        let actual = DumpCommand(data: blockCombi)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .none, kind: .multi, subBytes: [])
        XCTAssertEqual(actual, expected)
    }

    func testDumpCommand_oneADDBankD() {
        let actual = DumpCommand(data: oneADDBankD)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .d, kind: .single, subBytes: [0x00])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_blockADDBankD() {
        let actual = DumpCommand(data: blockADDBankD)
        XCTAssertTrue(actual != nil)
        let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .d, kind: .single, subBytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        XCTAssertEqual(actual, expected)
    }
    
    func testDumpCommand_asData() {
        let dump = DumpCommand(data: oneADDBankA)
        XCTAssertTrue(dump != nil)
        let dumpData = dump?.asData()
        XCTAssertEqual(dumpData, ByteArray([0x00, 0x20, 0x00, 0x0A, 0x00, 0x00, 0x00]))
    }
}
