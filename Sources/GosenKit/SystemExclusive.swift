import SyxPack

public enum SystemExclusive {
    public struct Header {
        public var channel: Byte
        public var function: Function
        public var group: Byte
        public var machineIdentifier: Byte
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
        
        public static func identify(data: ByteArray) -> SystemExclusive.Function {
            if data[3] == 0x20 && data[4] == 0x00 && data[5] == 0x0A && data[6] == 0x00 {
                return .oneBlockDump
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
}

public enum PatchKind: Byte, CaseIterable, CustomStringConvertible {
    case single = 0x00
    case multi = 0x20
    case drumKit = 0x10
    case drumInstrument = 0x11

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
}

/// Dump command header for various patch types.
public struct DumpCommand {
    /// MIDI channel (1...16)
    public var channel: Byte
    
    /// Cardinality of the patch
    public var cardinality: Cardinality
    
    /// Bank identifier for the patch, if applicable
    public var bank: BankIdentifier
    
    /// Patch kind
    public var kind: PatchKind
    
    /// Sub-bytes, like instrument number or tone map
    public var subBytes: ByteArray
    
    /// Initialze a default dump command
    public init() {
        self.init(channel: 1, cardinality: .one, bank: .a, kind: .single)
    }
    
    /// Initialize a dump command with all values. The sub-bytes array can be, and defaults to, empty.
    public init(channel: Byte, cardinality: Cardinality, bank: BankIdentifier, kind: PatchKind, subBytes: ByteArray = []) {
        self.channel = 0
        self.cardinality = cardinality
        self.bank = bank
        self.kind = kind
        self.subBytes = subBytes
    }
    
    /// Initializes a dump command from MIDI System Exclusive data. Returns `nil` if the data is invalid.
    public init?(data: ByteArray) {
        var maybeChannel: Byte = 1
        var maybeCardinality: Cardinality = .one
        var maybeBank: BankIdentifier = .none
        var maybeKind: PatchKind = .single
        
        print("\(#file):\(#line) data.count = \(data.count)")
        
        // Iterate through all the bytes and pick up information
        for (index, b) in data.enumerated() {
            switch index {
            case 0: // channel byte
                maybeChannel = b + 1  // adjust channel from 0~15 to 1~16
            case 1:
                maybeCardinality = Cardinality(rawValue: b)!
            case 2:  // // "5th" in spec, always 0x00
                if b != 0x00 {
                    return nil
                }
            case 3: // "6th" in spec, always 0x0A
                if b != 0x0A {
                    return nil
                }
            case 4: // patch kind ("7th" in spec): 0x00, 0x10, 0x11 or 0x20
                maybeKind = PatchKind(rawValue: b)!
            case 5:  // bank ID ("8th" in spec)
                switch maybeKind {
                case .drumKit, .drumInstrument, .multi:
                    maybeBank = .none
                default:
                    maybeBank = BankIdentifier(rawValue: b)!  // 0x0 ... 0x04
                }
            default:
                break
            }
        }

        var sub = ByteArray()
        
        if maybeCardinality == .one {
            switch maybeKind {
            case .single:
                sub.append(data[6])  // sub1 of single for all banks ("9th" in spec)
            case .multi:
                maybeBank = .none
                sub.append(data[5])  // sub1 of combi/multi ("8th" in spec)
            case .drumKit, .drumInstrument:  // no sub-bytes
                maybeBank = .none
            }
        }
        else {  // must be .block
            if maybeKind == .single {  // "block single" is the only one with a tone map
                if maybeBank != .b {   // but not for PCM bank
                    // Get the tone map
                    sub.append(contentsOf: data.slice(from: 6, length: ToneMap.dataSize))
                }
            }
            // No sub-bytes for block combi/multi or drum instrument
            else {
                maybeBank = .none
            }
        }
        
        self.init(channel: maybeChannel, cardinality: maybeCardinality, bank: maybeBank, kind: maybeKind, subBytes: sub)
    }
}

extension DumpCommand: CustomStringConvertible {
    /// Returns a string representation of the dump command.
    public var description: String {
        var s = "Channel: \(self.channel)  \(self.cardinality)  \(self.kind)  Bank \(self.bank) "
        s += "Sub-bytes: \(self.subBytes.hexDump(config: .plainConfig))"
        return s
    }
}

extension DumpCommand: Equatable { }


extension SystemExclusive.Header: SystemExclusiveData {
    public func asData() -> ByteArray {
        return [
            channel,
            function.rawValue,
            group,
            machineIdentifier,
            substatus1,
            substatus2,
        ]
    }
    
    public var dataLength: Int {
        return 6
    }
}

extension DumpCommand: SystemExclusiveData {
    private func collectData() -> ByteArray {
        var result: ByteArray = [
            self.channel - 1,   // adjust 1~16 to 0~15
            self.cardinality.rawValue,  // either 0x20 or 0x21
            0x00,  // always
            0x0A,  // always
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

// MARK: - CustomStringConvertible

extension SystemExclusive.Header: CustomStringConvertible {
    /// Provides a printable description for this header.
    public var description: String {
        var s = ""
        s += "Channel = \(self.channel + 1), function = \(self.function) etc."
        return s
    }
}
