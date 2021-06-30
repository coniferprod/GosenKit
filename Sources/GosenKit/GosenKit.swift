import func Darwin.fputs
import var Darwin.stderr

struct StandardErrorOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var standardError = StandardErrorOutputStream()

struct GosenKit {
    var text = "GosenKit"
}

public typealias Byte = UInt8
public typealias ByteArray = [Byte]
public typealias SByte = Int8

