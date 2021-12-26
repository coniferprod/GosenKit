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
        
        public static func identify(data: ByteArray) -> SystemExclusiveFunction {
            if data[3] == 0x20 && data[4] == 0x00 && data[5] == 0x0A && data[6] == 0x00 {
                return .oneBlockDump
            }
            
            if data[3] == SystemExclusiveFunction.identityRequest.rawValue && data[4] == 0x00 && data[5] == 0x0A {
                return .identityRequest
            }

            if data[3] == SystemExclusiveFunction.writeComplete.rawValue && data[4] == 0x00 && data[5] == 0x0A {
                return .writeComplete
            }
            
            if data[3] == SystemExclusiveFunction.writeError.rawValue && data[4] == 0x00 && data[5] == 0x0A {
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

public protocol SystemExclusiveData {
    func asData() -> ByteArray
}

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
}

extension SystemExclusive.Header: CustomStringConvertible {
    /// Provides a printable description for this header.
    public var description: String {
        var s = ""
        s += "Channel = \(self.channel + 1), function = \(self.function) etc."
        return s
    }
}


public struct SystemExclusiveHeader {
    public static let initiator: Byte = 0xf0
    public static let terminator: Byte = 0xf7
    
    public static let dataLength = 8

    public var manufacturerIdentifier: Byte
    public var channel: Byte
    public var function: Byte
    public var group: Byte
    public var machineIdentifier: Byte
    public var substatus1: Byte
    public var substatus2: Byte

    public init(manufacturerIdentifier: Byte, channel: Byte, function: Byte, group: Byte, machineIdentifier: Byte, substatus1: Byte, substatus2: Byte) {
        self.manufacturerIdentifier = manufacturerIdentifier
        self.channel = channel
        self.function = function
        self.group = group
        self.machineIdentifier = machineIdentifier
        self.substatus1 = substatus1
        self.substatus2 = substatus2
    }
}

// MARK: - SystemExclusiveData

extension SystemExclusiveHeader: SystemExclusiveData {
    public func asData() -> ByteArray {
        return [
            SystemExclusiveHeader.initiator,
            manufacturerIdentifier,
            channel,
            function,
            group,
            machineIdentifier,
            substatus1,
            substatus2,
        ]
    }
}

// MARK: - CustomStringConvertible

extension SystemExclusiveHeader: CustomStringConvertible {
    /// Provides a printable description for this header.
    public var description: String {
        var s = ""
        s += "Manufacturer ID: \(self.manufacturerIdentifier), channel = \(self.channel + 1), function = \(self.function) etc."
        return s
    }
}

public enum SystemExclusiveFunction: Byte {
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
    
    public static func identify(data: ByteArray) -> SystemExclusiveFunction {
        if data[3] == 0x20 && data[4] == 0x00 && data[5] == 0x0A && data[6] == 0x00 {
            return .oneBlockDump
        }
        
        if data[3] == SystemExclusiveFunction.identityRequest.rawValue && data[4] == 0x00 && data[5] == 0x0A {
            return .identityRequest
        }

        if data[3] == SystemExclusiveFunction.writeComplete.rawValue && data[4] == 0x00 && data[5] == 0x0A {
            return .writeComplete
        }
        
        if data[3] == SystemExclusiveFunction.writeError.rawValue && data[4] == 0x00 && data[5] == 0x0A {
            return .writeError
        }
        
        return .unknown
    }
    
    public var headerLength: Int {
        var result = 0
        switch self {
        case .oneBlockDump:
            result = 9
        default:
            result = 0
        }
        return result
    }
}
