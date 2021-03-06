import Foundation

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
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        data.append(SystemExclusiveHeader.initiator)
        data.append(manufacturerIdentifier)
        data.append(channel)
        data.append(function)
        data.append(group)
        data.append(machineIdentifier)
        data.append(substatus1)
        data.append(substatus2)
        return data
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
}
