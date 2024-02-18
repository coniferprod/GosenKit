import Foundation

import SyxPack


// Kawai K5000 banks contain either single patches (up to 128 of them)
// or exactly 64 multi patches (called combi on K5000W).

/// Bank of single patches.
public struct SingleBank {
    /// Patches in a bank of singles keyed by tone number.
    public var patches: [Int: SinglePatch]
}

/// Bank identifier.
public enum BankIdentifier: Byte, CaseIterable, CustomStringConvertible {
    case a = 0x00
    case b = 0x01
    case d = 0x02  // this only on K5000S/R
    case e = 0x03
    case f = 0x04
    case multi = 0x66  // the multi/combi bank has no ID
    case none = 0x99

    public var description: String {
        switch self {
        case .a:
            return "A"
        case .b:
            return "B"
        case .d:
            return "D"
        case .e:
            return "E"
        case .f:
            return "F"
        case .multi:
            return "C"  // multi/combi is referred to as C1-C64 in the MIDI spec
        case .none:
            return "N/A"
        }
    }
    
    public static func isValid(value: Byte) -> Bool {
        return BankIdentifier.allCases.contains(where: { $0.rawValue == value })
    }
}

/// Bank of combi/multi patches.
public struct MultiBank {
    public static let patchCount = 64
    
    public var patches: [MultiPatch]

    /// Initialize the multi bank with default multis.
    public init() {
        self.patches = Array(repeating: MultiPatch(), count: MultiBank.patchCount)
    }
    
    /// Parse a bank of multi patches from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<MultiBank, ParseError> {
        //print("Parsing multi bank, \(data.count) bytes")
        var offset = 0
        
        var temp = MultiBank()
        
        let size = MultiPatch.dataSize
        var patches = [MultiPatch]()
        for _ in 0..<MultiBank.patchCount {
            let patchData = data.slice(from: offset, length: size)
            //print("patchData: from: \(offset) length: \(patchData.count)")
            switch MultiPatch.parse(from: patchData) {
            case .success(let multiPatch):
                patches.append(multiPatch)
                //print(multiPatch.common.name.value)
            case .failure(let error):
                return .failure(error)
            }
            offset += size
        }
        
        temp.patches = patches
        return .success(temp)
    }
}
