import Foundation

import SyxPack
import ByteKit

struct StandardError: TextOutputStream, Sendable {
    private static let handle = FileHandle.standardError

    public func write(_ string: String) {
        Self.handle.write(Data(string.utf8))
    }
}

let standardError = StandardError()

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

/// Protocol to describe a subtype of Int with a range and a default value.
public protocol IntegerDomain {
    static var first: Int { get }
    static var last: Int { get }
    static var defaultValue: Int { get }
}

/// Wraps an `Int`  that is constrained to the values in the generic type `Domain`.
public struct Integer<Domain: IntegerDomain> {
    /// The wrapped `Int` value, read-only.
    public let value: Int

    /// Initializes with an `Int` value that fits in the constrained range,
    public init(_ value: Int) {
        precondition(Domain.first <= Domain.last)
        precondition((Domain.first...Domain.last).contains(value))
        precondition((Domain.first...Domain.last).contains(Domain.defaultValue))

        self.value = value
    }

    /// Initializes with the default value.
    public init() {
        self.init(Domain.defaultValue)
    }

    /// The first value in the range.
    public static var first: Int { Domain.first }
    
    /// The last value in the range.
    public static var last: Int { Domain.last }
    
    /// The default value.
    public static var defaultValue: Int { Domain.defaultValue }
    
    /// The range.
    public static var range: ClosedRange<Int> { Domain.first...Domain.last }

    /// Returns `true` if an `Int` value is contained in the domain, `false` otherwise.
    public static func contains(_ value: Int) -> Bool {
        Self.range.contains(value)
    }
}

extension Integer: ExpressibleByIntegerLiteral {
    /// Initializes with an integer literal.
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension Integer: CustomStringConvertible {
    /// Returns a `String` representation of the wrapped value.
    public var description: String {
        String(value)
    }
}

extension Integer: Equatable {
    /// Returns `true` if the two wrapped values are equal, `false` otherwise.
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.value == rhs.value
    }
}

public enum LevelDomain: IntegerDomain {
    public static let first = 0
    public static let last = 127
    public static let defaultValue = 0
}

public enum VolumeDomain: IntegerDomain {
    public static let first = 0
    public static let last = 99
    public static let defaultValue = 0
}

public enum SignedLevelDomain: IntegerDomain {
    public static let first = -63
    public static let last = 63
    public static let defaultValue = 0
}

public enum UnsignedLevelDomain: IntegerDomain {
    public static let first = 0
    public static let last = 63
    public static let defaultValue = 0
}

public typealias Level = Integer<LevelDomain>
public typealias Volume = Integer<VolumeDomain>
public typealias SignedLevel = Integer<SignedLevelDomain>
public typealias UnsignedLevel = Integer<UnsignedLevelDomain>

/*
public struct Integer<let minimumValue: Int, let maximumValue: Int, let defaultValue: Int>: Equatable, CustomStringConvertible {
    public let value: Int
        
    public init(_ value: Int = defaultValue) {
        assert((minimumValue...maximumValue).contains(value))
        self.value = value
    }
    
    public var description: String {
        "\(self.value)"
    }
    
    public static func contains(_ value: Int) -> Bool {
        (minimumValue...maximumValue).contains(value)
    }
    
    public var first: Int { minimumValue }
    public var last: Int { maximumValue }
    
    public static func == (lhs: Integer, rhs: Integer) -> Bool {
        type(of: lhs) == type(of: rhs) &&
        lhs.value == rhs.value
    }
}

public typealias Level = Integer<0, 127, 0>
public typealias SignedLevel = Integer<-63, 63, 0>
public typealias UnsignedLevel = Integer<0, 63, 0>
*/

// Parameters that are expressed with one byte in the SysEx data.
public enum ParameterKind {
    case volume
    case pan
    case coarse
    case fine
    case transpose
    case depth
    case midiChannel
    case velocityCurve
    case controlDepth
    case effectPath
    case gain
    case benderPitch
    case keyScalingControl
    case velocityControlTime
    case filterEnvelopeLevel
    case formantFilterEnvelopeDepth
    case geqLevel
    case multiPatchTune
    case pitchEnvelopeLevel
    case effectAlgorithm
}

public struct ParameterDescriptor {
    public let name: String
    public let bounds: ClosedRange<Int>
    public let defaultValue: Int
    public let incomingOffset: Int
    public let outgoingOffset: Int
    
    public init(name: String, bounds: ClosedRange<Int>, defaultValue: Int, incomingOffset: Int = 0, outgoingOffset: Int = 0) {
        precondition(bounds.contains(defaultValue), "Default value \(defaultValue) out of range \(bounds)")
        self.name = name
        self.bounds = bounds
        self.defaultValue = defaultValue
        self.incomingOffset = incomingOffset
        self.outgoingOffset = outgoingOffset
    }
    
    public func decode(_ byte: UInt8) -> Int {
        Int(byte) + self.incomingOffset
    }

    public func encode(_ value: Int) -> UInt8 {
        UInt8(value + self.outgoingOffset)
    }
}

// The descriptors dictionary includes only those parameters
// that need an offset applied for incoming or outgoing bytes.
// When parsing a byte, add `incomingOffset` to get an `Int`.
// When emitting a byte, add `outgoingOffset` to get a `Byte` (`UInt8`).
/*
let descriptors: [ParameterKind: ParameterDescriptor] = [
    .volume: ParameterDescriptor(name: "volume", bounds: 0...99, defaultValue: 99,
                                incomingOffset: 0, outgoingOffset: 0),
    .depth: ParameterDescriptor(name: "depth", bounds: -63...63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .midiChannel: ParameterDescriptor(name: "channel", bounds: 1...16, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
    .velocityCurve: ParameterDescriptor(name: "velocity-curve", bounds: 1...12, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
    .controlDepth: ParameterDescriptor(name: "control-depth", bounds: -31...31, defaultValue: 0, incomingOffset: -31, outgoingOffset: 31),
    .coarse: ParameterDescriptor(name: "coarse", bounds: -24...24, defaultValue: 0, incomingOffset: -24, outgoingOffset: 24),
    .fine: ParameterDescriptor(name: "fine", bounds: -63...63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .effectPath: ParameterDescriptor(name: "effect-path", bounds: 1...4, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
    .gain: ParameterDescriptor(name: "gain", bounds: 1...63, defaultValue: 1, incomingOffset: -1, outgoingOffset: 1),
    .benderPitch: ParameterDescriptor(name: "bender-pitch", bounds: -12...12, defaultValue: 0, incomingOffset: -12, outgoingOffset: 12),
    .transpose: ParameterDescriptor(name: "transpose", bounds: -24...24, defaultValue: 0, incomingOffset: -24, outgoingOffset: 24),
    .keyScalingControl: ParameterDescriptor(name: "key-scaling-control", bounds: -63...63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .velocityControlTime: ParameterDescriptor(name: "velocity-control-time", bounds: -63...63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .filterEnvelopeLevel: ParameterDescriptor(name: "filter-envelope-level", bounds: -63...63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .formantFilterEnvelopeDepth: ParameterDescriptor(name: "formant-filter-envelope-depth", bounds: -63...63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .geqLevel: ParameterDescriptor(name: "geq-level", bounds: -6...6, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64), // 58(-6) ~ 70(+6), so 64 is zero
    .multiPatchTune: ParameterDescriptor(name: "multi-patch-tune", bounds: -63...63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .pitchEnvelopeLevel: ParameterDescriptor(name: "pitch-envelope-level", bounds: -63...63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .pan: ParameterDescriptor(name: "pan", bounds: -63...63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .effectAlgorithm: ParameterDescriptor(name: "effect-algorithm", bounds: 1...4, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
]
*/

/*
public struct Parameter: CustomStringConvertible {
    public let value: Int
    public let descriptor: ParameterDescriptor
    
    public init(value: Int, descriptor: ParameterDescriptor) {
        precondition(descriptor.bounds.contains(value), "Value \(value) not in range \(descriptor)")
        self.value = value
        self.descriptor = descriptor
    }
    
    /*
    public func decode(_ byte: UInt8) -> Int {
        Int(byte) + self.descriptor.incomingOffset
    }

    public func encode() -> UInt8 {
        UInt8(self.value + self.descriptor.outgoingOffset)
    }
    */
    
    public var description: String {
        "\(self.value)"
    }
    
    public func withValue(_ value: Int) -> Parameter {
        .init(value: value, descriptor: self.descriptor)
    }
}
*/

/*
public class Integer: CustomStringConvertible, ExpressibleByIntegerLiteral, Equatable {
    public let value: Int
    public class var bounds: ClosedRange<Int> { Int.min...Int.max }
    public class var first: Int { Self.bounds.first! }
    public class var last: Int { Self.bounds.last! }
    public class var defaultValue: Self { Self(0) }
    
    required public init(_ value: Int) {
        precondition(Self.bounds.contains(value))
        self.value = value
    }
    
    required public init(integerLiteral value: Int) {
        precondition(Self.bounds.contains(value))
        self.value = value
    }
    
    public class func isValid(_ v: Int) -> Bool {
        Self.bounds.contains(v)
    }
    
    public var description: String {
        "\(value)"
    }
    
    public static func == (lhs: Integer, rhs: Integer) -> Bool {
        type(of: lhs) == type(of: rhs) &&
        lhs.value == rhs.value
    }
}
*/

/*
public protocol Parameter {
    associatedtype Value: Integer

    init(_ value: Value)

    static var name: String { get }
    var value: Value { get }
    static func decode(from bytes: ArraySlice<Byte>) throws -> Value
    static func encode(_ value: Value) -> ByteArray
}
*/

/*
extension Encoding {
    static func parseOrDefault(_ byte: Byte) -> Self {
        if Self.bounds.contains(Int(byte)) {
            let value = self.decode(byte)
            return .init(value)
        } else {
            return .init(Self.defaultValue)
        }
    }
}
*/

/*
func parseOrDefault<T>(_ byte: Byte, bounds: ClosedRange<Int>) -> T where T: Encoding {
    if bounds.contains(Int(byte)) {
        let t = T(Int(byte))
        let value = t.decode(byte)
        return T.init(value)
    }
}
*/

/*
extension Integer : Encoding {
    func defaultValue() -> Int { 0 }
    
    func decode(_ byte: Byte) -> Int {
        Int(byte)
    }
    
    func encode() -> Byte {
        Byte(self.value)
    }
}
*/

/*
public final class UInt7: Integer {
    override public class var bounds: ClosedRange<Int> {
        0...127
    }
}
*/

/*
func parseOrDefault<T: Encoding>(_ byte: Byte) -> T {
    let t = T()
    let value = t.decode(byte)
    return T.bounds.contains(value) ? T(value) : t
}
*/

/// Fixed key setting.
public enum FixedKey {
    case off
    case on(Key)
}

protocol XMLRepresentable {
    var xml: String { get }
}
