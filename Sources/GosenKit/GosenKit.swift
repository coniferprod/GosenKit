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

// Protocol to wrap an Int guaranteed to be contained in the given closed range.
protocol RangedInt {
    // The current value of the wrapped Int
    var value: Int { get }
    
    // The range where the Int must be in.
    static var range: ClosedRange<Int> { get }
    
    // The default value for the Int.
    static var defaultValue: Int { get }

    init()  // initialization with the default value
    init(_ value: Int)  // initialization with a value (will be clamped)
}

extension RangedInt {
    // Gets a random Int value that is inside the range.
    // This is a default implementation.
    static var randomValue: Int {
        return Int.random(in: Self.range)
    }
    
    // Predicate for checking if a potential value would be inside the range.
    // This is a default implementation.
    static func isValid(value: Int) -> Bool {
        return Self.range.contains(value)
    }

    // Satisfies Equatable conformance.
    // This is a default implementation.
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

public struct Volume {
    private var _value: Int
}

extension Volume: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct Level {
    private var _value: Int
}

extension Level: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct Depth {
    private var _value: Int
}

extension Depth: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct Pan {
    private var _value: Int
}

extension Pan: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct MIDIChannel: Equatable {
    private var _value: Int
}

extension MIDIChannel: RangedInt {
    public static let range: ClosedRange<Int> = 1...16
    public static let defaultValue = 1
    
    public init() {
        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct VelocityCurve {
    private var _value: Int
}

extension VelocityCurve: RangedInt {
    public static let range: ClosedRange<Int> = 1...12
    public static let defaultValue = 1
    
    public init() {
        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct ControlDepth {
    private var _value: Int
}

extension ControlDepth: RangedInt {
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 1
    
    public init() {
        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Coarse {
    private var _value: Int
}

extension Coarse: RangedInt {
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 1
    
    public init() {
        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct Fine {
    private var _value: Int
}

extension Fine: RangedInt {
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 1
    
    public init() {
        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

public struct EffectDepth {
    private var _value: Int
}

extension EffectDepth: RangedInt {
    public static let range: ClosedRange<Int> = 0...100

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct Resonance {
    private var _value: Int
}

extension Resonance: RangedInt {
    public static let range: ClosedRange<Int> = 0...31

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

public struct Gain {
    private var _value: Int
}

extension Gain: RangedInt {
    public static let range: ClosedRange<Int> = 1...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

