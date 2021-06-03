import Foundation

protocol Rangeable {
    var range: ClosedRange<Int> { get }
    var value: Int { get set }
    func isContained(value: Int) -> Bool
}

public class Ranged: Rangeable, Codable {
    var range: ClosedRange<Int> { 0...127 }
    
    var value: Int {
        get { self.storedValue }
        set { self.storedValue = min(max(self.range.lowerBound, newValue), self.range.upperBound) }
    }
    
    func isContained(value: Int) -> Bool {
        return self.range.contains(value)
    }
    
    var storedValue: Int
    
    init(_ initialValue: Int) {
        self.storedValue = initialValue
    }
}

extension Ranged {
    enum CodingKeys: String, CodingKey {
        case storedValue = "value"
    }
}

public class SignedLevel: Ranged {
    override var range: ClosedRange<Int> { -63...63 }
}

public class UnsignedLevel: Ranged {
    override var range: ClosedRange<Int> { 0...127 }
}

public class PositiveLevel: Ranged {
    // keep the original range, we just wanted the name
}
