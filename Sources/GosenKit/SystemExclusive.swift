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

// MARK: - SystemExclusiveData

public protocol SystemExclusiveData {
    func asData() -> ByteArray
    
    static var dataLength: Int { get }
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
    
    public static var dataLength: Int {
        return 6
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
