import SyxPack

public struct GosenKit {
    public private(set) var text = "GosenKit"
    
    public init() { }
}

/// Error type for parsing data from MIDI System Exclusive bytes.
public enum ParseError: Error {
    case notEnoughData(Int, Int)  // actual, expected
    case badChecksum(Byte, Byte)  // actual, expected
    case invalidData(Int)  // offset in data
}

extension ParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notEnoughData(let actual, let expected):
            return "Got \(actual) bytes of data, expected \(expected) bytes."
        case .badChecksum(let actual, let expected):
            return "Computed checksum was \(actual.toHex())H, expected \(expected.toHex())H."
        case .invalidData(let offset):
            return "Invalid data at offset \(offset)."
        }
    }
}
