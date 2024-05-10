import Foundation

import SyxPack
import ByteKit


// Kawai K5000 banks contain either single patches (up to 128 of them)
// or exactly 64 multi patches (called combi on K5000W).

// key = file size, value = tuple of (PCM count, ADD count)
// This is based on the table by Jens Groh.
let singlePatchSizes = [
    254: (2, 0),
    340: (3, 0),
    426: (4, 0),
    512: (5, 0),
    598: (6, 0),
    1060: (1, 1),
    1146: (2, 1),
    1232: (3, 1),
    1318: (4, 1),
    1404: (5, 1),
    1866: (0, 2),
    1952: (1, 2),
    2038: (2, 2),
    2124: (3, 2),
    2210: (4, 2),
    2758: (0, 3),
    2844: (1, 3),
    2930: (2, 3),
    3016: (3, 3),
    3650: (0, 4),
    3736: (1, 4),
    3822: (2, 4),
    4542: (0, 5),
    4628: (1, 5),
    5434: (0, 6),
]

/// Bank of single patches.
public struct SingleBank {
    /// Patches in a bank of singles keyed by tone number.
    public var patches: [Int: SinglePatch]

    /// Initialize the singles bank with an empty patch list.
    public init() {
        self.patches = [Int: SinglePatch]()
    }
    
    /// Parse a bank of single patches from MIDI System Exclusive data.
    public static func parse(from data: ByteArray, toneMap: ToneMap) -> Result<SingleBank, ParseError> {
        print("Parsing single bank, with \(data.count) bytes of data. Tone map = \(toneMap)")
        var offset = 0
        
        var temp = SingleBank()
        var singlePatchSize = singlePatchSizes.keys.sorted().first!  // smallest
        
        for tone in toneMap.allIncludedTones {
            // Read the common data of the single patch.
            // Note that we skip the checksum!
            let commonData = data.slice(from: offset + 1, length: SinglePatch.Common.dataSize)
            
            // Parse the single patch common data to get the actual number of sources
            // and then determine their sizes.
            switch SinglePatch.Common.parse(from: commonData) {
            case .success(let common):
                print("Common data = \(common)")
            case .failure(let error):
                return .failure(error)
            }

            break
        }
        
        return .success(temp)
    }
}

/// Bank identifier.
public enum BankIdentifier: Byte, CaseIterable, CustomStringConvertible {
    case a = 0x00
    case b = 0x01
    case d = 0x02  // this only on K5000S/R
    case e = 0x03
    case f = 0x04
    case multi = 0x66  // the multi/combi bank has no ID
    case none = 0x99  // use for drum

    /// Initialize the bank identifier from a byte value.
    /// Note that the multi/combi and the none variants
    /// don't have a byte value in System Exclusive data,
    /// so you can't get them using this initializer.
    public init?(index: Byte) {
        switch index {
        case 0x00: self = .a
        case 0x01: self = .b
        case 0x02: self = .d
        case 0x03: self = .e
        case 0x04: self = .f
        default: return nil
        }
    }

    /// Gets a printable representation of this bank identifier.
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
    
    /// Checks the validity of a bank identifier byte
    /// based on the corresponding raw value.
    /// Returns `true` if the byte represents a valid bank identifier,
    /// `false` if not.
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
        print("Parsing multi bank, \(data.count) bytes")
        var offset = 0
        
        var temp = MultiBank()
        
        let size = MultiPatch.dataSize
        var patches = [MultiPatch]()
        for _ in 0..<MultiBank.patchCount {
            let patchData = data.slice(from: offset, length: size)
            print("patchData: from: \(offset) length: \(patchData.count)")
            switch MultiPatch.parse(from: patchData) {
            case .success(let multiPatch):
                patches.append(multiPatch)
                print(multiPatch.common.name.value)
            case .failure(let error):
                return .failure(error)
            }
            offset += size
        }
        
        temp.patches = patches
        return .success(temp)
    }
}
