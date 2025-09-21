import XCTest
import SyxPack
import ByteKit
@testable import GosenKit

final class BankTests: XCTestCase {
    func test_SingleBank_fromData() {
        let filename = "K5000S-V404-SingleAAll.syx"
        guard let data = loadResource(filename: filename) else {
            XCTFail("Failed to load MIDI System Exclusive file '\(filename)'")
            return
        }
        XCTAssertFalse(data.isEmpty)
        
        var payload: Payload
        switch Message.parse(from: data.bytes) {
        case .success(let message):
            payload = message.payload
            let headerData = payload[..<32]  // should be enough for a dump header
            var dumpCommand = DumpCommand()
            switch DumpCommand.parse(from: ByteArray(headerData)) {
            case .success(let dump):
                dumpCommand = dump
                print("Dump command: \(dumpCommand)")
                
                print("Block of single patches")
                print("Header data length = \(dumpCommand.dataLength) bytes")
                let dumpData = dumpCommand.asData()
                let dumpDump = dumpData.hexDump(configuration: .simple)
                print("Header data = \(dumpDump)")
                
                // Everything in the message payload after the header data
                // is the actual patch data
                let patchPayload = ByteArray(payload[dumpCommand.dataLength...])
                print("Actual patch payload = \(patchPayload.count) bytes")
                
                let patchPayloadDump = ByteArray(patchPayload[..<32]).hexDump(configuration: .simple)
                print("Partial dump of patch payload:\n\(patchPayloadDump)")
                
                switch ToneMap.parse(from: dumpCommand.subBytes) {
                case .success(let toneMap):
                    switch SingleBank.parse(from: patchPayload, toneMap: toneMap) {
                    case .success(let bank):
                        XCTAssert(bank.patches.count == toneMap.includedCount)
                        /*
                        for tone in bank.patches.keys.sorted() {
                            print("\(tone): \(String(describing: bank.patches[tone]?.common.name))")
                        }
                         */
                    case .failure(let error):
                        XCTFail("Error parsing single bank: \(error)")
                    }
                case .failure(let error):
                    XCTFail("Error parsing tone map: \(error)")
                }
            case .failure(let error):
                XCTFail("Error parsing dump header: \(error)")
            }
        case .failure(let error):
            XCTFail("Unable to parse MIDI System Exclusive message")
        }
    }

    let rootFilename = "Package.swift"
    let resourcesDir = "Resources"
    
    func loadResource(filename: String) -> Data? {
        guard let resourceURL = findResource(filename: filename) else {
            return nil
        }
        let data = try? Data(contentsOf: resourceURL)
        return data
    }

    func findResource(filename: String) -> URL? {
        guard let resourcesURL = resourcesURL else {
            return nil
        }
        let fileURL = resourcesURL.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }
    
    lazy var resourcesURL: URL? = {
        guard let rootURL = findUp(filename: rootFilename) else {
            return nil
        }
        return rootURL.appendingPathComponent(resourcesDir)
    }()

    
    func findUp(filename: String, baseURL: URL = URL(fileURLWithPath: #file).deletingLastPathComponent()) -> URL? {
        let fileURL = baseURL.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return baseURL
        } else {
            return baseURL.pathComponents.count > 1
            ? findUp(filename: filename, baseURL: baseURL.deletingLastPathComponent())
            : nil
        }
    }
    
    
    func test_MultiBank_fromData() {
        let filename = "K5000S-V404-Multi.syx"
        guard let data = loadResource(filename: filename) else {
            XCTFail("Failed to load MIDI System Exclusive file '\(filename)'")
            return
        }
        XCTAssertFalse(data.isEmpty)
        
        var payload: Payload
        switch Message.parse(from: data.bytes) {
        case .success(let message):
            payload = message.payload
            let headerData = payload[..<32]  // should be enough for a dump header
            var dumpCommand = DumpCommand()
            switch DumpCommand.parse(from: ByteArray(headerData)) {
            case .success(let dump):
                dumpCommand = dump
                print("Dump command: \(dumpCommand)")
                
                print("Block of multi patches")
                print("Header data length = \(dumpCommand.dataLength) bytes")
                let dumpData = dumpCommand.asData()
                let dumpDump = dumpData.hexDump(configuration: .simple)
                print("Header data = \(dumpDump)")
                
                // Everything in the message payload after the header data
                // is the actual patch data
                let patchPayload = ByteArray(payload[dumpCommand.dataLength...])
                print("Actual patch payload = \(patchPayload.count) bytes")
                
                let patchPayloadDump = ByteArray(patchPayload[..<32]).hexDump(configuration: .simple)
                print("Partial dump of patch payload:\n\(patchPayloadDump)")

                switch MultiBank.parse(from: patchPayload) {
                case .success(let bank):
                    XCTAssertEqual(bank.patches.count, MultiBank.patchCount)
                case .failure(let error):
                    XCTFail("\(error)")
                }

            case .failure(let error):
                XCTFail("Error parsing dump header: \(error)")
            }
        case .failure(let error):
            XCTFail("Unable to parse MIDI System Exclusive message")
        }

        
    }
}
