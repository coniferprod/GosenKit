import Foundation
import ByteKit
import SyxPack

/// Graphic equalizer settings.
public struct GEQ {
    public static let bandCount = 7

    public struct Level {
        private var _value: Int
    }

    public var levels: [Level]  // 58(-6) ~ 70(+6), so 64 is zero
    
    /// Initialize this GEQ with default values.
    public init() {
        self.levels = [Level](repeating: Level(0), count: GEQ.bandCount)
    }
    
    /// Initialize this GEQ with integer values.
    public init(levels: [Int]) {
        self.levels = [Level]()
        levels.forEach {
            self.levels.append(GEQ.Level($0))
        }
    }
    
    /// Parse the GEQ from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<GEQ, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        var temp = GEQ()
        var levels = [Level]()
        for _ in 0..<GEQ.bandCount {
            b = data.next(&offset)
            let v = Level(Int(b) - 64)  // 58(-6) ~ 70(+6), so 64 is zero
            //print("GEQ band \(i + 1): \(b) --> \(v)")
            levels.append(v)
        }
        temp.levels = levels
        return .success(temp)
    }
}

// MARK: - RangedInt protocol conformance

extension GEQ.Level: RangedInt {
    public static let range: ClosedRange<Int> = -6...6

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension GEQ.Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

// MARK: - SystemExclusiveData protocol conformance

extension GEQ: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this GEQ.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        self.levels.forEach {
            data.append(Byte($0.value + 64)) // 58(-6)~70(+6)
        }
        
        return data
    }
    
    public var dataLength: Int { GEQ.dataSize }
    
    public static let dataSize = GEQ.bandCount
}
