import Foundation

extension CaseIterable where Self: Equatable {
    public var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

extension String {
    public func pad(with character: String, toLength length: Int) -> String {
        let padCount = length - self.count
        guard padCount > 0 else {
            return self
        }

        return String(repeating: character, count: padCount) + self
    }
}

extension Byte {
    public mutating func setBit(_ position: Int) {
        self |= 1 << position;
    }
    
    public mutating func unsetBit(_ position: Int) {
        self &= ~(1 << position);
    }
    
    public func isBitSet(_ position: Int) -> Bool {
        return (self & (1 << position)) != 0
    }
}

extension Byte {
    public func toBinary() -> String {
        return String(self, radix: 2)
    }
    
    public func toHex(digits: Int = 2) -> String {
        return String(format: "%0\(digits)x", self)
    }
}

extension ByteArray {
    public var hexDump: String {
        var s = ""
        for d in self {
            s += d.toHex(digits: 2)
            s += " "
        }
        return s
    }
    
    /// Returns the byte at the given offset, then increases the offset by one.
    public func next(_ offset: inout Int) -> Byte {
        let b = self[offset]
        offset += 1
        return b
    }
    
    /// Returns a new byte array with `length` bytes starting from `offset`.
    public func slice(from offset: Int, length: Int) -> ByteArray {
        return ByteArray(self[offset ..< offset + length])
    }
}

extension Data {
    public var bytes: ByteArray {
        var byteArray = ByteArray(repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
    
    public var hexDump: String {
        var s = ""
        for d in self {
            s += d.toHex(digits: 2)
            s += " "
        }
        return s
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension String {
    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

public func noteName(for key: Int) -> String {
    let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let octave = key / 12 - 1
    let name = noteNames[key % 12];
    return "\(name)\(octave)"
}

public func keyNumber(for name: String) -> Int {
    let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    let notes = CharacterSet(charactersIn: "CDEFGAB")
    
    var i = 0
    var notePart = ""
    var octavePart = ""
    while i < name.count {
        let c = name[i ..< i + 1]
        
        let isNote = c.unicodeScalars.allSatisfy { notes.contains($0) }
        if isNote {
            notePart += c
        }
 
        if c == "#" {
            notePart += c
        }
        if c == "-" {
            octavePart += c
        }
        
        let isDigit = c.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
        if isDigit {
            octavePart += c
        }

        i += 1
    }

    if let octave = Int(octavePart), let noteIndex = names.firstIndex(where: { $0 == notePart }) {
        return (octave + 1) * 12 + noteIndex
    }

    return 0
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// Property wrapper to clamp the value of a Comparable.
// https://www.swiftbysundell.com/articles/property-wrappers-in-swift/
// This reallyt seems to be more trouble than it's worth,
// or I can't make this pattern fit my brain.
@propertyWrapper
public struct Clamping<Value: Comparable> {
    public let range: ClosedRange<Value>
    private let defaultValue: Value
    private var value: Value
    
    public var wrappedValue: Value {
        get {
            self.value
        }
        
        set {
            self.value = min(max(range.lowerBound, newValue), range.upperBound)
        }
    }
     
    init(defaultValue: Value, range: ClosedRange<Value>) {
        precondition(range.contains(defaultValue))
        self.defaultValue = defaultValue
        self.value = defaultValue
        self.range = range
    }
}
