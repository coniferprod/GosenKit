import Foundation

import SyxPack
import ByteKit

struct StandardError: TextOutputStream, Sendable {
    private static let handle = FileHandle.standardError

    public func write(_ string: String) {
        Self.handle.write(Data(string.utf8))
    }
}

var standardError = StandardError()

/*
public struct GosenKit {
    public private(set) var text = "GosenKit"
    
    public init() { }
}
*/

/// Error type for parsing data from MIDI System Exclusive bytes.
public enum ParseError: Error {
    case invalidLength(Int, Int)  // actual, expected
    case invalidChecksum(Byte, Byte)  // actual, expected
    case invalidData(Int, String)  // offset in data, with additional information
}

extension ParseError: CustomStringConvertible {
    /// Gets a printable representation of this parse error.
    public var description: String {
        switch self {
        case .invalidLength(let actual, let expected):
            return "Got \(actual) bytes of data, expected \(expected) bytes."
        case .invalidChecksum(let actual, let expected):
            return "Computed checksum was \(actual.toHexString())H, expected \(expected.toHexString())H."
        case .invalidData(let offset, let info):
            return "Invalid data at offset \(offset). \(info)."
        }
    }
}

/// Wraps an immutable `Int`, retrievable with `value`.
/// Specifies minimum, maximum, and default values.
/// When an instance is constructed, the new value is
/// checked by asserting it is within the min / max limits.
/// The no-argument initializer uses the default value.
public class Integer: ExpressibleByIntegerLiteral, CustomStringConvertible {
    class var minimumValue: Int { Int.min }
    class var maximumValue: Int { Int.max }
    class var defaultValue: Int { 0 }
    
    public private(set) var value: Int
    
    public init(_ value: Int) {
        assert(Self.isValid(value))
        self.value = value
    }
    
    public static func isValid(_ value: Int) -> Bool {
        return (Self.minimumValue ... Self.maximumValue).contains(value)
    }

    required public convenience init(integerLiteral value: Int) {
        self.init(value)
    }
    
    public convenience init() {
        self.init(Self.defaultValue)
    }
    
    /// Gets a random value within min and max (inclusive).
    public static var randomValue: Int {
        let range: ClosedRange<Int> = Self.minimumValue ... Self.maximumValue
        return Int.random(in: range)
    }
    
    public var description: String {
        return "\(value)"
    }
    
    /*
    convenience init(_ b: UInt8) {
        self.init(Self.valueFromByte(b))
    }
    */
    
    public static func valueFromByte(byte: UInt8, adjuster: (UInt8) -> Int) -> Int {
        adjuster(byte)
    }
}

func == (lhs: Integer, rhs: Integer) -> Bool {
    return lhs.value == rhs.value
}

/// Volume level (0...127, default 0)
public class Volume: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 127 }
    override class var defaultValue: Int { 0 }
    
/*
    convenience init(_ b: UInt8) {
        self.init(Volume.valueFromByte(b))
    }
*/
    public static func incoming(byte: UInt8) -> Int {
        Int(byte) + 1
    }
}

/// Level (0...127, default 0)
public class Level: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 127 }
    override class var defaultValue: Int { 0 }
}

/// Time (0...127, default 0)
public class Time: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 127 }
    override class var defaultValue: Int { 0 }
}

/// Depth (-63...63, default 0)
public class Depth: Integer {
    override class var minimumValue: Int { -63 }
    override class var maximumValue: Int { 63 }
    override class var defaultValue: Int { 0 }
}

/// Pan (-63...63, default 0)
public class Pan: Integer {
    override class var minimumValue: Int { -63 }
    override class var maximumValue: Int { 63 }
    override class var defaultValue: Int { 0 }
}

/// MIDI channel (1...16, default 1)
public class MIDIChannel: Integer {
    override class var minimumValue: Int { 1 }
    override class var maximumValue: Int { 16 }
    override class var defaultValue: Int { 1 }
}

/// Velocity curve (1...12, default 1)
public class VelocityCurve: Integer {
    override class var minimumValue: Int { 1 }
    override class var maximumValue: Int { 12 }
    override class var defaultValue: Int { 1 }
}

/// Control depth (-31...31, default 0)
public class ControlDepth: Integer {
    override class var minimumValue: Int { -31 }
    override class var maximumValue: Int { 31 }
    override class var defaultValue: Int { 0 }
    
    public static func incoming(byte: UInt8) -> Int {
        Int(byte) - 31
    }
}

/// Control level (0...63, default 0)
public class ControlLevel: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 63 }
    override class var defaultValue: Int { 0 }
}

/// Coarse tuning (-24...24, default 0)
public class Coarse: Integer {
    override class var minimumValue: Int { -24 }
    override class var maximumValue: Int { 24 }
    override class var defaultValue: Int { 0 }
}

/// Fine tuning (-63...63, default 0)
public class Fine: Integer {
    override class var minimumValue: Int { -63 }
    override class var maximumValue: Int { 63 }
    override class var defaultValue: Int { 0 }
}

/// Effect depth (0...100, default 0)
public class EffectDepth: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 100 }
    override class var defaultValue: Int { 0 }
}

/// Effect path (1...4, default 1)
public class EffectPath: Integer {
    override class var minimumValue: Int { 1 }
    override class var maximumValue: Int { 4 }
    override class var defaultValue: Int { 1 }
    
    public static func incoming(byte: UInt8) -> Int {
        Int(byte) + 1  // 0...3 to 1...4
    }
    
    public static func outgoing(byte: UInt8) -> Int {
        Int(byte) - 1
    }
}

/// Resonance (0...31, default 0)
public class Resonance: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 31 }
    override class var defaultValue: Int { 0 }
}

/// Gain (1...63, default 1)
public class Gain: Integer {
    override class var minimumValue: Int { 1 }
    override class var maximumValue: Int { 63 }
    override class var defaultValue: Int { 1 }
}

/// Bender pitch (-12...12, default 0)
public class BenderPitch: Integer {
    override class var minimumValue: Int { -12 }
    override class var maximumValue: Int { 12 }
    override class var defaultValue: Int { 0 }

    /*
    convenience init(_ b: UInt8) {
        self.init(BenderPitch.valueFromByte(b))
    }
     */
    
    public static func incoming(byte: UInt8) -> Int {
        Int(byte) - 12
    }
    
    public static func outgoing(byte: UInt8) -> Int {
        Int(byte) + 12
    }
}

/// Bender cutoff (0...31, default 0)
public class BenderCutoff: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 31 }
    override class var defaultValue: Int { 0 }
}

/// MIDI note (0...127, default 60)
public class MIDINote: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 127 }
    override class var defaultValue: Int { 60 }
}

/// Patch number (0...127, default 0)
public class PatchNumber: Integer {
    override class var minimumValue: Int { 0 }
    override class var maximumValue: Int { 127 }
    override class var defaultValue: Int { 0 }
}

/// Transpose (-24...24, default 0)
public class Transpose: Integer {
    override class var minimumValue: Int { -24 }
    override class var maximumValue: Int { 24 }
    override class var defaultValue: Int { 0 }
}

/// Wave number for DCO (1...464, default 1).
public class WaveNumber: Integer {
    override class var minimumValue: Int { 1 }
    override class var maximumValue: Int { 464 }
    override class var defaultValue: Int { 1 }
}

/// Fixed key setting.
public enum FixedKey {
    case off
    case on(Key)
}
