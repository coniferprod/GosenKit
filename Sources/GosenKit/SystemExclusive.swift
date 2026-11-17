import SyxPack
import ByteKit

public protocol SystemExclusiveEncoding: IntegerDomain {
    static func decode(from bytes: ArraySlice<Byte>) -> Integer<Self>?
    static func encode(_ value: Integer<Self>) -> ByteArray
}

//public typealias MIDIChannel = Integer<1, 16, 1>
public enum MIDIChannelDomain: IntegerDomain {
    public static let first = 1
    public static let last = 16
    public static let defaultValue = 1
}

public typealias MIDIChannel = Integer<MIDIChannelDomain>

extension MIDIChannelDomain: SystemExclusiveEncoding {
    public static func decode(
        from bytes: ArraySlice<UInt8>
    ) -> Integer<MIDIChannelDomain>? {
        guard let byte = bytes.first, byte <= 15 else {
            return nil
        }

        return Integer<MIDIChannelDomain>(Int(byte) + 1)
    }
    
    public static func encode(
        _ value: Integer<MIDIChannelDomain>
    ) -> ByteArray {
        [UInt8(value.value - 1)]  // bring to 0...15
    }
}


/*
public final class MIDIChannel: Integer {
    override public class var bounds: ClosedRange<Int> { 1...16 }
    override public class var defaultValue: MIDIChannel { MIDIChannel(1) }
    
    public static func decode(from bytes: ArraySlice<Byte>) throws(ParseError) -> MIDIChannel {
        guard
            bytes.count >= 1
        else {
            throw ParseError.invalidLength(bytes.count, 1)
        }
        
        let value = Int(bytes.first!) + 1  // bring to 1...16
        if MIDIChannel.isValid(value) {
            return MIDIChannel(value)
        } else {
            throw ParseError.invalidData(0, "value \(value) for MIDI channel out of range, should be \(Volume.bounds)")
        }
    }

    public static func encode(_ value: MIDIChannel) -> ByteArray {
        [Byte(value.value - 1)]  // bring to 0...15
    }
}
*/

/// K5000S/R/W MIDI System Exclusive message.
public enum SystemExclusive {
    public static let groupIdentifier: Byte = 0x00    // synth group ID
    public static let machineIdentifier: Byte = 0x0A  // K5000S/R/W machine ID
    
    /// System Exclusive header.
    public struct Header {
        public var channel: MIDIChannel
        public var function: Function
        public var substatus1: Byte
        public var substatus2: Byte
        
        public var length: Int {
            var result = 0
            switch self.function {
            case .oneBlockDump:
                result = 9
            default:
                result = 0
            }
            return result
        }
    }
    
    /// System Exclusive function.
    public enum Function: Byte {
        case oneBlockDumpRequest = 0x00
        case allBlockDumpRequest = 0x01
        case parameterSend = 0x10
        case trackControl = 0x11
        case oneBlockDump = 0x20
        case allBlockDump = 0x21
        case modeChange = 0x31
        case remote = 0x32
        case writeComplete = 0x40
        case writeError = 0x41
        case writeErrorByProtect = 0x42
        case writeErrorByMemoryFull = 0x44
        case writeErrorByNoExpandMemory = 0x45
        case identityRequest = 0x60
        case identityAcknowledge = 0x61
        case unknown = 0x99
        
        // Identify the System Exclusive function from the data bytes.
        // The data must be the raw payload (not including SysEx initiator
        // or manufacturer byte).
        public static func identify(data: ByteArray) -> SystemExclusive.Function {
            // data[0] is the MIDI channel
            if data[1] == SystemExclusive.Function.allBlockDump.rawValue && data[2] == 0x00 && data[3] == 0x0A && data[4] == 0x00 {
                return .allBlockDump
            }
            
            if data[1] == SystemExclusive.Function.oneBlockDump.rawValue && data[2] == 0x00 && data[3] == 0x0A && data[4] == 0x00 {
                return .oneBlockDump
            }

            if data[1] == SystemExclusive.Function.parameterSend.rawValue && data[2] == 0x00 && data[3] == 0x0A {
                return .parameterSend
            }
            
            if data[3] == SystemExclusive.Function.identityRequest.rawValue && data[4] == 0x00 && data[5] == 0x0A {
                return .identityRequest
            }

            if data[3] == SystemExclusive.Function.writeComplete.rawValue && data[4] == 0x00 && data[5] == 0x0A {
                return .writeComplete
            }
            
            if data[3] == SystemExclusive.Function.writeError.rawValue && data[4] == 0x00 && data[5] == 0x0A {
                return .writeError
            }
            
            return .unknown
        }
    }
    
    public struct Message {
        public var header: Header
        public var payload: ByteArray
    }
}

/// Represents the cardinality of the dump: one or block.
public enum Cardinality: Byte, CustomStringConvertible {
    case one = 0x20
    case block = 0x21
    
    /// Initialize the cardinality from a byte value.
    public init?(index: Byte) {
        switch index {
        case 0x20: self = .one
        case 0x21: self = .block
        default: return nil
        }
    }

    /// Gets a printable representation of the cardinality.
    public var description: String {
        switch self {
        case .one:
            return "One"
        case .block:
            return "Block"
        }
    }

    /// Checks the validity of the cardinality byte.
    /// Returns `true` if the byte represents a valid cardinality value,
    /// `false` otherwise.
    public static func isValid(value: Byte) -> Bool {
        return 
            value == Cardinality.one.rawValue
            || value == Cardinality.block.rawValue
    }
}

/// Represents the kind of a patch.
public enum PatchKind: Byte, CaseIterable, CustomStringConvertible {
    case single = 0x00
    case drumKit = 0x10  // only on K5000W
    case drumInstrument = 0x11  // only on K5000W
    case multi = 0x20

    /// Initialize the patch kind from a byte value.
    public init?(index: Byte) {
        switch index {
        case 0x00: self = .single
        case 0x10: self = .drumKit
        case 0x11: self = .drumInstrument
        case 0x20: self = .multi
        default: return nil
        }
    }

    /// Gets a printable representation of this patch kind.
    public var description: String {
        switch self {
        case .single:
            return "Single"
        case .drumKit:
            return "Drum Kit"
        case .drumInstrument:
            return "Drum Instrument"
        case .multi:
            return "Multi"
        }
    }
}

/// Dump command header for various patch types.
public struct DumpCommand {
    /// MIDI channel (1...16)
    public var channel: MIDIChannel
    
    /// Cardinality of the patch
    public var cardinality: Cardinality
    
    /// Bank identifier for the patch, if applicable
    public var bank: BankIdentifier
    
    /// Patch kind
    public var kind: PatchKind
    
    /// Sub-bytes, like instrument number or tone map
    public var subBytes: ByteArray
    
    /// Initialize a default dump command
    public init() {
        self.init(channel: MIDIChannel(1), cardinality: .one, bank: .a, kind: .single)
    }
    
    /// Initialize a dump command with all values. 
    /// The sub-bytes array can be, and defaults to, empty.
    public init(channel: MIDIChannel, cardinality: Cardinality, bank: BankIdentifier, kind: PatchKind, subBytes: ByteArray = []) {
        self.channel = channel
        self.cardinality = cardinality
        self.bank = bank
        self.kind = kind
        self.subBytes = subBytes
    }
    
    /// Parse the dump command from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<DumpCommand, ParseError> {
        let channel: MIDIChannel
        do throws(ParseError) {
            try channel = MIDIChannelDomain.decode(from: data[0...0])
        } catch {
            switch error {
            default:
                return .failure(error)
            }
        }

        /*
        let channelValue = Int(data[0] + 1)
        guard
            MIDIChannel.bounds.contains(channelValue)
        else {
            return .failure(.invalidData(0, "Invalid MIDI channel: \(data[0].toHexString()) (expected \(MIDIChannel.bounds))"))
        }
        let channel = MIDIChannel(channelValue)
        */
        
        guard
            Cardinality.isValid(value: data[1])
        else {
            return .failure(.invalidData(1, "Invalid cardinality byte: \(data[1].toHexString())H"))
        }
        
        // data[2] = "5th" in spec (section 5.3, "Dump command table"), always 0x00
        guard
            data[2] == SystemExclusive.groupIdentifier 
        else {
            return .failure(.invalidData(2, "Invalid group identifier byte: \(data[2].toHexString())H"))
        }
        
        // data[3] = "6th" in spec, always 0x0A
        guard
            data[3] == SystemExclusive.machineIdentifier
        else {
            return .failure(.invalidData(3, "Invalid machine identifier, expected \(SystemExclusive.machineIdentifier.toHexString())H, got \(data[3].toHexString())H"))
        }

        // data[4] = patch kind ("7th" in spec): 0x00, 0x10, 0x11 or 0x20
        // This is the last byte that appears in every dump command.
        guard
            let kind = PatchKind(index: data[4])
        else {
            return .failure(.invalidData(4, "Invalid patch kind byte: \(data[4].toHexString())"))
        }
        
        // data[5] = "8th" in spec, bank identifier. Not valid for dr kit, dr inst, combi.
        // (Except for dr inst see note below.)
        // data[6] = "9th" in spec, is sub bytes or actual data. Not in all dumps.
        
        print("Dump command data length = \(data.count)")
        print("Dump command bytes:\n\(data.hexDump())")

        var dumpCommand = DumpCommand()
        
        // We have already checked that the MIDI channel is good.
        dumpCommand.channel = channel
        
        // We have already checked that the cardinality byte is valid,
        // so we can instantiate the enum and force unwrap.
        dumpCommand.cardinality = Cardinality(index: data[1])!

        // We have already checked that the patch kind byte is valid with a guard above.
        dumpCommand.kind = kind

        switch dumpCommand.kind {
        case .multi:
            dumpCommand.bank = .multi
        case .drumInstrument, .drumKit:
            dumpCommand.bank = .none
        default:
            dumpCommand.bank = BankIdentifier(index: data[5])!
        }
        
        // Match the patterns in the order they appear in the
        // MIDI spec section 5.3, "Dump command table".
        // Leave out bytes "5th" and "6th" (data[2] and data[3]) because they are always the same.
        // We already have guard statements for them (see above).
        // We can't have sub1 and sub2 bytes here because they may be missing in some dumps.
        switch (dumpCommand.cardinality, dumpCommand.kind, dumpCommand.bank) {
            
        //
        // K50000W
        //

        // One Add Bank A, One PCM Bank B, One Exp Bank E, One Exp Bank F,
        // One Add Bank D
        case (.one, .single, _):
            dumpCommand.subBytes = [data[6]]
            return .success(dumpCommand)

        // One dr kit
        case (.one, .drumKit, _):
            // sub-bytes are left as empty
            return .success(dumpCommand)
            
        // One dr inst
        // NOTE: The dump command table does not agree with the
        // dump description in 3.1.1g. The dump command table says
        // there are no sub-bytes but the dump description says 
        // that there is an instrument number (00~1F) as the first sub-byte.
        case (.one, .drumInstrument, _):
            dumpCommand.subBytes = [data[5]]
            return .success(dumpCommand)
            
        // One combi
        case (.one, .multi, _):
            dumpCommand.subBytes = [data[6]]
            return .success(dumpCommand)

        // Block ADD Bank A
        case (.block, .single, .a):
            // sub-bytes has the tone map
            dumpCommand.subBytes = data.slice(from: 6, length: ToneMap.dataSize)
            return .success(dumpCommand)
            
        // Block PCM Bank B
        case (.block, .single, .b):
            // no sub-bytes
            return .success(dumpCommand)
            
        // Block Exp Bank E
        case (.block, .single, .e):
            dumpCommand.subBytes = data.slice(from: 6, length: ToneMap.dataSize)
            return .success(dumpCommand)
        
        // Block Exp Bank F
        case (.block, .single, .f):
            dumpCommand.subBytes = data.slice(from: 6, length: ToneMap.dataSize)
            return .success(dumpCommand)

        // Block dr inst
        case (.block, .drumInstrument, _):
            // empty sub-bytes
            return .success(dumpCommand)
            
        // Block combi / multi
        case (.block, .multi, _):
            // empty sub-bytes
            return .success(dumpCommand)

        //
        // K5000S/R
        //
            
        // One multi is the same as one combi
            
        // Block ADD Bank A is the same
            
        // Block ADD Bank D
        case (.block, .single, .d):
            dumpCommand.subBytes = data.slice(from: 6, length: ToneMap.dataSize)
            return .success(dumpCommand)

        // Block Exp Bank E is the same
        // Block Exp Bank F is the same
        // Block multi is the same as block combi
        
        default:
            return .failure(.invalidData(0, "Unspecified error in header"))
        }
    }
}

extension DumpCommand: CustomStringConvertible {
    /// Returns a string representation of the dump command.
    public var description: String {
        var s = "Channel=\(self.channel)  Cardinality=\(self.cardinality)  Kind=\(self.kind)  Bank=\(self.bank)"
        if self.subBytes.count != 0 {
            s += " Sub-bytes=\(self.subBytes.hexDump(configuration: .simple))"
        }
        return s
    }
}

extension DumpCommand: Equatable {
    public static func == (lhs: DumpCommand, rhs: DumpCommand) -> Bool {
        lhs.channel == rhs.channel &&
        lhs.cardinality == rhs.cardinality &&
        lhs.kind == rhs.kind &&
        lhs.bank == rhs.bank &&
        lhs.subBytes == rhs.subBytes
    }
}

public struct ParameterChange {
    /// MIDI channel (1...16)
    public var channel: MIDIChannel
    
    // Function is always 0x10 for parameter send
    
    public var sub1: Byte
    public var sub2: Byte
    public var sub3: Byte
    public var sub4: Byte
    public var sub5: Byte
    public var dataHigh: Byte
    public var dataLow: Byte
}

//extension ParameterChange: Equatable { }

extension SystemExclusive.Header: SystemExclusiveData {
    public func asData() -> ByteArray {
        var result = ByteArray()
        
        result.append(contentsOf: MIDIChannelDomain.encode(self.channel))
        
        result.append(contentsOf: [
            function.rawValue,
            SystemExclusive.groupIdentifier,
            SystemExclusive.machineIdentifier,
            substatus1,
            substatus2,
        ])
        
        return result
    }
    
    public var dataLength: Int { 6 }
}

extension DumpCommand: SystemExclusiveData {
    private func collectData() -> ByteArray {
        var result = ByteArray()
        
        result.append(contentsOf: MIDIChannelDomain.encode(self.channel))
        result.append(contentsOf: [
            self.cardinality.rawValue,  // either 0x20 or 0x21
            SystemExclusive.groupIdentifier,
            SystemExclusive.machineIdentifier,
            self.kind.rawValue,  // single, multi, drum kit, drum instrument
        ])
        
        // Only single patches need a bank
        if self.kind == .single {
            result.append(self.bank.rawValue)
        }
        
        // Add any sub-bytes (one or more).
        // For drum kit and drum instrument, and "Block PCM Bank B",
        // sub-bytes will be empty, so this append is a no-op for them.
        result.append(contentsOf: self.subBytes)

        return result
    }

    public func asData() -> ByteArray {
        return self.collectData()
    }

    public var dataLength: Int {
        let data = self.collectData()
        return data.count
    }
}

extension ParameterChange: SystemExclusiveData {
    public func asData() -> ByteArray {
        var result = ByteArray()
        
        result.append(contentsOf: MIDIChannelDomain.encode(self.channel))
        
        result.append(contentsOf: [
            SystemExclusive.Function.parameterSend.rawValue,
            SystemExclusive.groupIdentifier,
            SystemExclusive.machineIdentifier,
            sub1, sub2, sub3, sub4, sub5, dataHigh, dataLow,
        ])
        
        return result
    }
    
    public var dataLength: Int { 11 }
}

// MARK: - CustomStringConvertible

extension SystemExclusive.Header: CustomStringConvertible {
    /// Provides a printable description for this header.
    public var description: String {
        var s = ""
        s += "Channel = \(self.channel), function = \(self.function) etc."
        return s
    }
}
