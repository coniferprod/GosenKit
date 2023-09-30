import Foundation

/// Graphic equalizer settings.
public struct GEQ {
    public static let bandCount = 7

    public struct Level {
        private var _value: Int
    }

    var levels: [Level]  // 58(-6) ~ 70(+6), so 64 is zero
    
    init(levels: [Int]) {
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
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}
