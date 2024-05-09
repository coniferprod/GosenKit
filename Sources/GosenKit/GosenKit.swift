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
protocol RangedInt {
    /// The current value of the wrapped Int
    var value: Int { get }
    
    /// The range where the Int must be in.
    static var range: ClosedRange<Int> { get }
    
    /// The default value for the Int.
    static var defaultValue: Int { get }

    /// Initialization with the default value.
    init()
    
    /// Initialization with a value (will be clamped).
    init(_ value: Int)
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

    /// Satisfies Equatable conformance.
    /// This is a default implementation.
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

/// Volume (0...127).
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
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Volume: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Volume: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Level (0...127)
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
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Level: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Depth (-63...+63).
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
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Depth: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Depth: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Pan (-63...+63).
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
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Pan: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Pan: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// MIDI channel (1...16).
public struct MIDIChannel: Equatable {
    private var _value: Int
}

extension MIDIChannel: RangedInt {
    public static let range: ClosedRange<Int> = 1...16
    public static let defaultValue = 1
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension MIDIChannel: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension MIDIChannel: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Velocity curve (1...12).
public struct VelocityCurve {
    private var _value: Int
}

extension VelocityCurve: RangedInt {
    public static let range: ClosedRange<Int> = 1...12
    public static let defaultValue = 1
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension VelocityCurve: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension VelocityCurve: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Control depth (-63...+63).
public struct ControlDepth {
    private var _value: Int
}

extension ControlDepth: RangedInt {
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension ControlDepth: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension ControlDepth: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Coarse tuning (-24...+24).
public struct Coarse {
    private var _value: Int
}

extension Coarse: RangedInt {
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension Coarse: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Coarse: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Fine tuning (-63...+63).
public struct Fine {
    private var _value: Int
}

extension Fine: RangedInt {
    public static let range: ClosedRange<Int> = -63...63
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension Fine: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Fine: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Effect depth (0...100).
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
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension EffectDepth: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Effect path (1...4).
public struct EffectPath {
    private var _value: Int
}

extension EffectPath: RangedInt {
    public static let range: ClosedRange<Int> = 1...4

    public static let defaultValue = 1

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension EffectPath: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension EffectPath: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Resonance (0...31).
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
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Resonance: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Resonance: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Gain setting (1...63).
public struct Gain {
    private var _value: Int
}

extension Gain: RangedInt {
    public static let range: ClosedRange<Int> = 1...63

    public static let defaultValue = 1

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")
        
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Gain: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Gain: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Bender pitch amount (-12...+12).
public struct BenderPitch {
    private var _value: Int
}

extension BenderPitch: RangedInt {
    public static let range: ClosedRange<Int> = -12...12

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension BenderPitch: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension BenderPitch: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Bender cutoff (0...31).
public struct BenderCutoff {
    private var _value: Int
}

extension BenderCutoff: RangedInt {
    public static let range: ClosedRange<Int> = 0...31

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension BenderCutoff: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension BenderCutoff: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// MIDI note number (0...127).
public struct MIDINote: Equatable {
    private var _value: Int
}

extension MIDINote: RangedInt {
    public static let range: ClosedRange<Int> = 0...127
    
    public static let defaultValue = 60  // Middle C

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension MIDINote: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension MIDINote: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F",
                         "F#", "G", "G#", "A", "A#", "B"]
        let octave = self.value / 12 - 2  // use Yamaha convention
        let name = noteNames[self.value % 12]
        return "\(name)\(octave)"
    }
}

/// Fixed key setting.
public enum FixedKey {
    case off
    case on(Key)
}

/// Patch number in a bank.
public struct PatchNumber {
    private var _value: Int
}

extension PatchNumber: RangedInt {
    public static let range: ClosedRange<Int> = 0...127
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension PatchNumber: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension PatchNumber: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

/// Transpose amount (-24...+24).
public struct Transpose {
    private var _value: Int
}

extension Transpose: RangedInt {
    public static let range: ClosedRange<Int> = -24...24
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension Transpose: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Transpose: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}
