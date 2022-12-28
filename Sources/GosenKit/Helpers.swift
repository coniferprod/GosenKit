import Foundation

import SyxPack


extension CaseIterable where Self: Equatable {
    public var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

public enum PadFrom {
    case left
    case right
}

extension String {
    public func pad(with character: String, toLength length: Int, from: PadFrom = .right) -> String {
        let padCount = length - self.count
        guard padCount > 0 else {
            return self
        }

        if from == .left {
            return String(repeating: character, count: padCount) + self
        }
        else {
            return self + String(repeating: character, count: padCount)
        }
    }
    
    public func adjusted(length: Int, pad: String = " ") -> String {
        // If longer, truncate to `length`.
        // If shorter, pad from right with `pad` to the length `length`.
        if self.count > length {
            return String(self.prefix(length))
        }
        else {
            return self.pad(with: " ", toLength: length, from: .right)
            //return self.padding(toLength: length, withPad: " ", startingAt: self.count - 1)
        }
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

/// Key with note number and name.
public struct Key: Codable {
    private var noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    public var note: Int
    
    public var name: String {
        let octave = self.note / 12 - 1
        let name = self.noteNames[self.note % 12]
        return "\(name)\(octave)"
    }
    
    public init(note: Int) {
        self.note = note
    }
    
    public init(name: String) {
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

        if let octave = Int(octavePart), let noteIndex = self.noteNames.firstIndex(where: { $0 == notePart }) {
            self.note = (octave + 1) * 12 + noteIndex
        }
        else {
            self.note = 0
        }
    }
}

/// Keyboard zone with low and high keys.
public struct Zone: Codable {
    public var high: Key
    public var low: Key
    
    public init(high: Key, low: Key) {
        self.high = high
        self.low = low
    }
}
