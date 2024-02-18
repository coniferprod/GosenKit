import SyxPack

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

public enum Cardinality: Byte, CustomStringConvertible {
    case one = 0x20
    case block = 0x21
    
    public var description: String {
        switch self {
        case .one:
            return "One"
        case .block:
            return "Block"
        }
    }
    
    public static func isValid(value: Byte) -> Bool {
        return value == Cardinality.one.rawValue || value == Cardinality.block.rawValue
    }
}

public enum PatchKind: Byte, CaseIterable, CustomStringConvertible {
    case single = 0x00
    case multi = 0x20
    case drumKit = 0x10  // only on K5000W
    case drumInstrument = 0x11  // only on K5000W

    public var description: String {
        switch self {
        case .single:
            return "Single"
        case .multi:
            return "Multi"
        case .drumKit:
            return "Drum Kit"
        case .drumInstrument:
            return "Drum Instrument"
        }
    }
    
    public static func isValid(value: Byte) -> Bool {
        return PatchKind.allCases.contains(where: { $0.rawValue == value })
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
    
    /// Initialize a dump command with all values. The sub-bytes array can be, and defaults to, empty.
    public init(channel: MIDIChannel, cardinality: Cardinality, bank: BankIdentifier, kind: PatchKind, subBytes: ByteArray = []) {
        self.channel = channel
        self.cardinality = cardinality
        self.bank = bank
        self.kind = kind
        self.subBytes = subBytes
    }
    
    public init?(data: ByteArray) {
        let result = DumpCommand.parse(from: data)
        switch result {
        case .success(let command):
            self = command
        case .failure:
            return nil
        }
    }
    
    public static func parse(from data: ByteArray) -> Result<DumpCommand, ParseError> {
        guard
            MIDIChannel.range.contains(Int(data[0] + 1))
        else {
            return .failure(.invalidData(0))
        }
        
        guard 
            Cardinality.isValid(value: data[1])
        else {
            return .failure(.invalidData(1))
        }
        
        // "5th" in spec (section 5.3, "Dump command table"), always 0x00
        guard 
            data[2] == SystemExclusive.groupIdentifier 
        else {
            return .failure(.invalidData(2))
        }
        
        // "6th" in spec, always 0x0A
        guard 
            data[3] == SystemExclusive.machineIdentifier
        else {
            return .failure(.invalidData(3))
        }

        // patch kind ("7th" in spec): 0x00, 0x10, 0x11 or 0x20
        guard 
            PatchKind.isValid(value: data[4])
        else {
            return .failure(.invalidData(4))
        }
        
        // Match the patterns from the "Dump command table".
        // Leave out bytes "5th" and "6th" (data[2] and data[3]) because they are always the same.
        // We already have guard statements for them (see above).
        switch (data[0], data[1], data[4], data[5], data[6], data[7]) {
            
        //
        // K50000W
        //

        // One Add Bank A
        case (let channel, Cardinality.one.rawValue, PatchKind.single.rawValue, BankIdentifier.a.rawValue, let sub1, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .a,
                kind: .single,
                subBytes: [sub1])
            return .success(temp)
            
        // One PCM Bank B
        case (let channel, Cardinality.one.rawValue, PatchKind.single.rawValue, BankIdentifier.b.rawValue, let sub1, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .b,
                kind: .single,
                subBytes: [sub1])
            return .success(temp)
            
        // One Exp Bank E
        case (let channel, Cardinality.one.rawValue, PatchKind.single.rawValue, BankIdentifier.e.rawValue, let sub1, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .e,
                kind: .single,
                subBytes: [sub1])
            return .success(temp)
            
        // One Exp Bank F
        case (let channel, Cardinality.one.rawValue, PatchKind.single.rawValue, BankIdentifier.f.rawValue, let sub1, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .f,
                kind: .single,
                subBytes: [sub1])
            return .success(temp)
            
        // One dr kit
        case (let channel, Cardinality.one.rawValue, PatchKind.drumKit.rawValue, _, _, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .none,
                kind: .drumKit)
            return .success(temp)
            
        // One dr inst
        case (let channel, Cardinality.one.rawValue, PatchKind.drumInstrument.rawValue, _, _, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .none,
                kind: .drumInstrument)
            return .success(temp)
            
        // One combi
        case (let channel, Cardinality.one.rawValue, PatchKind.multi.rawValue, _, let sub1, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .multi,
                kind: .multi,
                subBytes: [sub1])
            return .success(temp)

        // Block ADD Bank A
        case (let channel, Cardinality.block.rawValue, PatchKind.single.rawValue, BankIdentifier.a.rawValue, let sub1, let sub2):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .a,
                kind: .single,
                subBytes: [sub1, sub2])
            return .success(temp)
            
        // Block PCM Bank B
        case (let channel, Cardinality.block.rawValue, PatchKind.single.rawValue, BankIdentifier.b.rawValue, _, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .b,
                kind: .single)
            return .success(temp)
            
        // Block Exp Bank E
        case (let channel, Cardinality.block.rawValue, PatchKind.single.rawValue, BankIdentifier.e.rawValue, let sub1, let sub2):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .e,
                kind: .single,
                subBytes: [sub1, sub2])
            return .success(temp)
            
        // Block Exp Bank F
        case (let channel, Cardinality.block.rawValue, PatchKind.single.rawValue, BankIdentifier.f.rawValue, let sub1, let sub2):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .f,
                kind: .single,
                subBytes: [sub1, sub2])
            return .success(temp)
            
        // Block dr inst
        case (let channel, Cardinality.block.rawValue, PatchKind.drumInstrument.rawValue, _, _, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .none,
                kind: .drumInstrument)
            return .success(temp)
            
        // Block combi / multi
        case (let channel, Cardinality.block.rawValue, PatchKind.multi.rawValue, _, _, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .multi,
                kind: .multi)
            return .success(temp)

        //
        // K5000S/R
        //
            
        // One ADD Bank A is the same
        
        // One Add Bank D
        case (let channel, Cardinality.one.rawValue, PatchKind.single.rawValue, BankIdentifier.d.rawValue, let sub1, _):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .one,
                bank: .d,
                kind: .single,
                subBytes: [sub1])
            return .success(temp)
                
        // One Exp Bank E and F are the same
            
        // One multi is the same as one combi
            
        // Block ADD Bank A is the same
            
        // Block ADD Bank D
        case (let channel, Cardinality.block.rawValue, PatchKind.single.rawValue, BankIdentifier.d.rawValue, let sub1, let sub2):
            let temp = DumpCommand(
                channel: MIDIChannel(Int(channel) + 1),
                cardinality: .block,
                bank: .d,
                kind: .single,
                subBytes: [sub1, sub2])
            return .success(temp)
            
        // Block Exp Bank E is the same
        // Block Exp Bank F is the same
        // Block multi is the same as block combi
        
        default:
            return .failure(.invalidData(0))
        }
    }
}

extension DumpCommand: CustomStringConvertible {
    /// Returns a string representation of the dump command.
    public var description: String {
        var s = "Channel: \(self.channel)  \(self.cardinality)  \(self.kind)  Bank: \(self.bank)"
        if self.subBytes.count != 0 {
            s += " Sub-bytes: \(self.subBytes.hexDump(config: .plainConfig))"
        }
        return s
    }
}

extension DumpCommand: Equatable { }

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

extension ParameterChange: Equatable { }

extension SystemExclusive.Header: SystemExclusiveData {
    public func asData() -> ByteArray {
        return [
            Byte(channel.value - 1),
            function.rawValue,
            SystemExclusive.groupIdentifier,
            SystemExclusive.machineIdentifier,
            substatus1,
            substatus2,
        ]
    }
    
    public var dataLength: Int { 6 }
}

extension DumpCommand: SystemExclusiveData {
    private func collectData() -> ByteArray {
        var result: ByteArray = [
            Byte(self.channel.value - 1),   // adjust 1~16 to 0~15
            self.cardinality.rawValue,  // either 0x20 or 0x21
            SystemExclusive.groupIdentifier,
            SystemExclusive.machineIdentifier,
            self.kind.rawValue,  // single, multi, drum kit, drum instrument
        ]
        
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
        return [
            Byte(self.channel.value - 1),   // adjust 1~16 to 0~15
            SystemExclusive.Function.parameterSend.rawValue,
            SystemExclusive.groupIdentifier,
            SystemExclusive.machineIdentifier,
            sub1, sub2, sub3, sub4, sub5, dataHigh, dataLow,
        ]
    }
    
    public var dataLength: Int { 11 }
}

// MARK: - CustomStringConvertible

extension SystemExclusive.Header: CustomStringConvertible {
    /// Provides a printable description for this header.
    public var description: String {
        var s = ""
        s += "Channel = \(self.channel.value), function = \(self.function) etc."
        return s
    }
}
