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
import ByteKit

final class SystemExclusiveTests: XCTestCase {
    func testSystemExclusive_header() {
        let header = SystemExclusive.Header(
            channel: MIDIChannel(1),
            function: SystemExclusive.Function.oneBlockDump,
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

    // The test dump commands are organized like section 3.1.1
    // in the K5000 MIDI implementation document (p. 9).
    
    // NOTE: There is always are least 8 bytes of data, because the header will be
    // followed by the actual patch data. Depending on the dump command, some of
    // the data at the end will be ignored.
    
    // The prelude F0 40 is not included. All samples are on MIDI channel 1.

    // a:BLOCK SINGLE DUMP (ADD, All of enable patch in A1 - 128)
    let blockSingleA: ByteArray = [
        0x00,  // MIDI channel 1
        0x21, 0x00, 0x0A, 0x00, 0x00,
        
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    // b:ONE SINGLE DUMP (ADD, A1 - 128)
    let oneSingleA: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x00, 0x00,
        
        0x00,  // sub1 = Tone No. (00~7F)
    ]
    
    // c:BLOCK SINGLE DUMP (PCM, all of B70 - B116)  (only for K5000W)
    let blockSingleB: ByteArray = [
        0x00,  // MIDI channel 1

        0x21, 0x00, 0x0A, 0x00, 0x01,
    ]
    
    // d:ONE SINGLE DUMP (PCM, B70 - B116) (only for K5000W)
    let oneSingleB: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x00, 0x01,
        
        0x00,  // sub1 = Tone No. (45~73)
    ]
    
    // e:DRUM KIT DUMP (B117) (only for K5000W)
    let drumKitB: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x10,
    ]
    
    // f:BLOCK DRUM INST DUMP (All of Inst User1~32) (only for K5000W)
    let blockDrumInst: ByteArray = [
        0x00,  // MIDI channel 1

        0x21, 0x00, 0x0A, 0x11,
    ]
    
    // g:ONE DRUM INST DUMP (User Inst U1 - 32) (only for K5000W)
    let oneDrumInst: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x11,
        
        0x00, // sub1 = INST No. (00 ~ 1F)
    ]
    
    // h:BLOCK COMBI DUMP (All of C1 - 64) (Combi is changed to Multi on K5000S/R)
    let blockCombi: ByteArray = [
        0x00,  // MIDI channel 1

        0x21, 0x00, 0x0A, 0x20,
    ]
    
    // i:ONE COMBI DUMP (C1 - 64) (Combi is changed to Multi on K5000S/R)
    let oneCombi: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x20,
        
        0x00, // sub1 = INST No. (00 ~ 3F)
    ]
    
    // j:BLOCK SINGLE DUMP (ADD, All of enable patch in D1-128) (only for K5000S/R)
    let blockSingleD: ByteArray = [
        0x00,  // MIDI channel 1

        0x21, 0x00, 0x0A, 0x00, 0x02,
        
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    // k:ONE SINGLE DUMP (ADD, D1 - 128) (Only for K5000S/R)
    let oneSingleD: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x00, 0x02,
        
        0x00,  // sub1 = Tone No. (00 ~ 7F)
    ]
    
    // l:BLOCK SINGLE DUMP (ADD, All of enable patch in E1-128) (Only when ME-1 is installed)
    let blockSingleE: ByteArray = [
        0x00,  // MIDI channel 1
        
        0x21, 0x00, 0x0A, 0x00, 0x03,

        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    // m:ONE SINGLE DUMP (ADD, E1 - 128) (Only when ME-1 is installed)
    let oneSingleE: ByteArray = [
        0x00,  // MIDI channel 1
        
        0x20, 0x00, 0x0A, 0x00, 0x03,
        
        0x00, // sub1 = Tone No. (00 ~ 7F)
    ]
    
    // n:BLOCK SINGLE DUMP (ADD, all of enable patch in F1 - 128) (Only when ME-1 is installed)
    let blockSingleF: ByteArray = [
        0x00,  // MIDI channel 1
    
        0x21, 0x00, 0x0A, 0x00, 0x04,
        
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    // o:ONE SINGLE DUMP (ADD, F1 - 128) (Only when ME-1 is installed)
    let oneSingleF: ByteArray = [
        0x00,  // MIDI channel 1

        0x20, 0x00, 0x0A, 0x00, 0x04,
        
        0x00, // sub1: Tone No. (00 ~ 7F)
    ]
    
    // One ADD Bank A (see 3.1.1b)
    let oneADDBankA: ByteArray = [
        0x00, 0x20, 0x00, 0x0A, 0x00, 0x00,
        0x00, // Tone No. 00
    ]
    
    // One PCM Bank B (see 3.1.1d)
    let onePCMBankB: ByteArray = [
        0x00, 0x20, 0x00, 0x0A, 0x00, 0x01,
        0x00, /* filler */ 0x00 ]
    
    let oneExpBankE: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x03, 0x00, /* filler */ 0x00 ] // One Exp Bank E ((see 3.1.1m)
    let oneExpBankF: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x04, 0x00, /* filler */ 0x00 ] // One Exp Bank F (see 3.1.1o)
    let oneDrumKit: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x10, /* filler */ 0x00, 0x00, 0x00 ]
    let oneDrumInstrument: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x11, 0x00, /* filler */ 0x00, 0x00 ]
    //let oneCombi: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x20, 0x00, /* filler */ 0x00, 0x00 ] // One Multi/Combi (see 3.1.1i)

    // Block
    let blockADDBankA: ByteArray = [
        0x00, 0x21, 0x00, 0x0A, 0x00, 0x00,
                                     
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    let blockPCMBankB: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x00, 0x01, /* filler */ 0x00, 0x00 ]
    
    let blockExpBankE: ByteArray = [
        0x00, 0x21, 0x00, 0x0A, 0x00, 0x03,
        
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    let blockExpBankF: ByteArray = [
        0x00, 0x21, 0x00, 0x0A, 0x00, 0x04,
                                     
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    
    let blockDrumInstrument: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x11, /* filler */ 0x00, 0x00, 0x00 ]
    //let blockCombi: ByteArray = [ 0x00, 0x21, 0x00, 0x0A, 0x20, /* filler */ 0x00, 0x00, 0x00 ]

    // K5000S/R
    // One
    // oneADDBankA is the same as on the K5000W
    let oneADDBankD: ByteArray = [ 0x00, 0x20, 0x00, 0x0A, 0x00, 0x02, 0x00, /* filler */ 0x00 ] // One ADD Bank D (see 3.1.1k)
    // oneExpBankE and oneExpBankF are the same as on the K5000W
    // oneMulti is the same as oneCombi on the K5000W
    
    // Block
    // blockADDBankA is the same as on the K5000W
    let blockADDBankD: ByteArray = [ 
        0x00, 0x21, 0x00, 0x0A, 0x00, 0x02,
        
        /* tone map of 19 bytes */
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
    ]
    // blockExpBankE and blockExpBankF are the same as on the K5000W
    // blockMulti is the same as blockCombi on the K5000W
    
    // The following functions are named after the sub-sections of
    // section 3.1.1 in the K5000 MIDI manual.
    func testDump_a() {
        switch DumpCommand.parse(from: blockSingleA) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .a, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_b() {
        switch DumpCommand.parse(from: oneSingleA) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .a, kind: .single, subBytes: [0x00])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_c() {
        switch DumpCommand.parse(from: blockSingleB) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .b, kind: .single, subBytes: [])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_d() {
        switch DumpCommand.parse(from: oneSingleB) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .b, kind: .single, subBytes: [0x00])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_e() {
        switch DumpCommand.parse(from: drumKitB) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .none, kind: .drumKit, subBytes: [])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_f() {
        switch DumpCommand.parse(from: blockDrumInst) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .none, kind: .drumInstrument, subBytes: [])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_g() {
        switch DumpCommand.parse(from: oneDrumInst) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .none, kind: .drumInstrument, subBytes: [0x00])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_h() {
        switch DumpCommand.parse(from: blockCombi) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .multi, kind: .multi, subBytes: [])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_i() {
        switch DumpCommand.parse(from: blockCombi) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .multi, kind: .multi, subBytes: [])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_j() {
        switch DumpCommand.parse(from: blockSingleD) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .d, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_k() {
        switch DumpCommand.parse(from: oneSingleD) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .d, kind: .single, subBytes: [0x00])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_l() {
        switch DumpCommand.parse(from: blockSingleE) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .e, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_m() {
        switch DumpCommand.parse(from: oneSingleE) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .e, kind: .single, subBytes: [0x00])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_n() {
        switch DumpCommand.parse(from: blockSingleF) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .block, bank: .f, kind: .single, subBytes: ByteArray(repeating: 0x00, count: ToneMap.dataSize))
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
    
    func testDump_o() {
        switch DumpCommand.parse(from: oneSingleF) {
        case .success(let actual):
            let expected = DumpCommand(channel: MIDIChannel(1), cardinality: .one, bank: .f, kind: .single, subBytes: [0x00])
            XCTAssertEqual(actual, expected)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}
