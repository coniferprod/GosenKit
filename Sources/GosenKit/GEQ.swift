import Foundation

/// Graphic equalizer settings.
public struct GEQ {
    public static let bandCount = 7

    public struct Level {
        private var _value: Int
    }

    public var levels: [Level]  // 58(-6) ~ 70(+6), so 64 is zero
    
    public init(levels: [Int]) {
        self.levels = [Level]()
        levels.forEach {
            self.levels.append(GEQ.Level($0))
        }
    }
}

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
