import SyxPack
import ByteKit

public struct GosenKit {
    public private(set) var text = "GosenKit"
    
    public init() { }
}

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

/// Protocol to wrap an Int guaranteed to be contained
/// in the given closed range.
protocol RangedInt: CustomStringConvertible, ExpressibleByIntegerLiteral {
    /// The current value of the wrapped `Int`.
    var value: Int { get }
    
    /// The range where the `Int` must be in.
    static var range: ClosedRange<Int> { get }
    
    /// The default value for the `Int`.
    static var defaultValue: Int { get }

    /// Initialization with the default value.
    init()
    
    /// Initialization with a value (will be clamped).
    init(_ value: Int)
    
    /// Initialize with an integer literal.
    init(integerLiteral value: Int)
}

extension RangedInt {
    /// Gets a random Int value that is inside the range.
    /// This is a default implementation.
    static var randomValue: Int {
        return Int.random(in: Self.range)
    }
    
    /// Predicate for checking if a potential value would
    /// be inside the range. This is a default implementation.
    static func isValid(value: Int) -> Bool {
        return Self.range.contains(value)
    }

    /// Generates a string representation of the value.
    /// Satisfies CustomStringConvertible conformance.
    public var description: String {
        String(self.value)
    }
    
    /// Initialize with an integer literal.
    /// Satisfies ExpressibleByIntegerLiteral conformance.
    public init(integerLiteral value: Int) {
        self.init(value)
    }
    
    public init() {
        assert(Self.range.contains(Self.defaultValue),
               "Default value must be in range \(Self.range)")
        self.init(Self.defaultValue)
    }
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

/// Volume (0...127).
public struct Volume: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...127
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Level (0...127)
public struct Level: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...127
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Time (0...127)
public struct Time: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...127
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Depth (-63...+63).
public struct Depth: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Pan (-63...+63).
public struct Pan: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// MIDI channel (1...16).
public struct MIDIChannel: RangedInt, Equatable {
    public var value: Int
    public static let range: ClosedRange<Int> = 1...16
    public static let defaultValue = 1
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Velocity curve (1...12).
public struct VelocityCurve: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 1...12
    public static let defaultValue = 1
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Control depth (-63...+63).
public struct ControlDepth: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Coarse tuning (-24...+24).
public struct Coarse: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Fine tuning (-63...63).
public struct Fine: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Effect depth (0...100).
public struct EffectDepth: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...100
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Effect path (1...4).
public struct EffectPath: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 1...4
    public static let defaultValue = 1

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Resonance (0...31).
public struct Resonance: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...31
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Gain (1...63).
public struct Gain: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 1...63
    public static let defaultValue = 1

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Bender pitch (-12...12).
public struct BenderPitch: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -12...12
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Bender cutoff (0...31).
public struct BenderCutoff: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...31
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// MIDI note (0...127).
public struct MIDINote: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...127
    public static let defaultValue = 60

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Patch number (0...127).
public struct PatchNumber: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...127
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Transpose (-24...24).
public struct Transpose: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 0

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Fixed key setting.
public enum FixedKey {
    case off
    case on(Key)
}
