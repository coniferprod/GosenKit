import Foundation

public struct Bank {
    public var singles: [SinglePatch]
    public var multis: [MultiPatch]
    
    
}

public enum BankIdentifier: Byte, CustomStringConvertible {
    case a = 0x00
    case b = 0x01
    case d = 0x02
    case e = 0x03
    case f = 0x04
    case none = 0xff

    public var description: String {
        switch self {
        case .a:
            return "A"
        case .b:
            return "B"
        case .d:
            return "D"
        case .e:
            return "E"
        case .f:
            return "F"
        case .none:
            return "N/A"
        }
    }
}
