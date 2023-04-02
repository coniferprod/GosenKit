import Foundation

import SyxPack


// Kawai K5000 banks contain either single patches (up to 128 of them)
// or exactly 64 multi patches (called combi on K5000W).

public struct SingleBank {
    public var patches: [SinglePatch]
}

public enum BankIdentifier: Byte, CustomStringConvertible {
    case a = 0x00
    case b = 0x01
    // there is no bank C, kind of
    case d = 0x02  // this only on K5000S/R
    case e = 0x03
    case f = 0x04
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
        case .none:
            return "N/A"
        }
    }
}


public struct MultiBank {
    public var patches: [MultiPatch]
}
