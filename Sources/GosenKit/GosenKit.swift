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

// Parameters that are expressed with one byte in the SysEx data.
public enum ParameterKind {
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
    var minimumValue: Int
    var maximumValue: Int
    var defaultValue: Int
    var incomingOffset: Int
    var outgoingOffset: Int
}

// The descriptors dictionary includes only those parameters
// that need an offset applied for incoming or outgoing bytes.
// When parsing a byte, add `incomingOffset` to get an `Int`.
// When emitting a byte, add `outgoingOffset` to get a `Byte` (`UInt8`).
let descriptors: [ParameterKind: ParameterDescriptor] = [
    .depth: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .midiChannel: ParameterDescriptor(minimumValue: 1, maximumValue: 16, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
    .velocityCurve: ParameterDescriptor(minimumValue: 1, maximumValue: 12, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
    .controlDepth: ParameterDescriptor(minimumValue: -31, maximumValue: 31, defaultValue: 0, incomingOffset: -31, outgoingOffset: 31),
    .coarse: ParameterDescriptor(minimumValue: -24, maximumValue: 24, defaultValue: 0, incomingOffset: -24, outgoingOffset: 24),
    .fine: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .effectPath: ParameterDescriptor(minimumValue: 1, maximumValue: 4, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
    .gain: ParameterDescriptor(minimumValue: 1, maximumValue: 63, defaultValue: 1, incomingOffset: -1, outgoingOffset: 1),
    .benderPitch: ParameterDescriptor(minimumValue: -12, maximumValue: 12, defaultValue: 0, incomingOffset: -12, outgoingOffset: 12),
    .transpose: ParameterDescriptor(minimumValue: -24, maximumValue: 24, defaultValue: 0, incomingOffset: -24, outgoingOffset: 24),
    .keyScalingControl: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .velocityControlTime: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .filterEnvelopeLevel: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .formantFilterEnvelopeDepth: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .geqLevel: ParameterDescriptor(minimumValue: -6, maximumValue: 6, defaultValue: 0, incomingOffset: -58, outgoingOffset: 58), // 58(-6) ~ 70(+6), so 64 is zero
    .multiPatchTune: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -63, outgoingOffset: 63),
    .pitchEnvelopeLevel: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .pan: ParameterDescriptor(minimumValue: -63, maximumValue: 63, defaultValue: 0, incomingOffset: -64, outgoingOffset: 64),
    .effectAlgorithm: ParameterDescriptor(minimumValue: 1, maximumValue: 4, defaultValue: 1, incomingOffset: 1, outgoingOffset: -1),
]

/// Fixed key setting.
public enum FixedKey {
    case off
    case on(Key)
}

protocol XMLRepresentable {
    var xml: String { get }
}
