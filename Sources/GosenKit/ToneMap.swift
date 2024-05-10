import SyxPack
import ByteKit

/// Represents the set of included patches in a bank.
public class ToneMap {
    public static let maxCount = 128
    private var included: [Bool]  // true if patch is included, false if not
    
    /// Initialize an empty tone map.
    public init() {
        self.included = [Bool](repeating: false, count: ToneMap.maxCount)
    }
    
    /// Parse tone map from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<ToneMap, ParseError> {
        guard
            data.count == ToneMap.dataSize
        else {
            return .failure(.invalidLength(data.count, ToneMap.dataSize))
        }

        let temp = ToneMap()  // initialize with defaults, then fill in

        temp.included = [Bool]()
        for (_, byte) in data.enumerated() {
            // Take the bottom seven bits of each byte
            for bit in 0..<7 {
                temp.included.append(byte.isBitSet(bit))
            }
        }

        return .success(temp)
    }
    
    /// Sets or resets the included status of the tone at `index`.
    public subscript(index: Int) -> Bool {
        get {
            return self.included[index]
        }
        set(newValue) {
            // Only set if the index is in valid range
            if (0..<ToneMap.maxCount).contains(index) {
                self.included[index] = newValue
            }
        }
    }
    
    /// The number of patches included.
    public var includedCount: Int {
        self.included.filter { $0 }.count
    }
    
    /// The set of all included tones.
    public var allIncludedTones: Array<Int> {
        var tones = [Int]()
        
        for tone in 1...ToneMap.maxCount {
            if self.includes(tone: tone) {
                tones.append(tone)
            }
        }

        return tones
    }
    
    /// Checks if the tone map includes `tone`.
    ///
    /// - Parameters:
    ///      - tone: The tone number from 1 to 128
    /// - Returns: `true` if the tone is included, `false` if not
    public func includes(tone: Int) -> Bool {
        guard
            (1...ToneMap.maxCount).contains(tone)
        else {
            return false
        }

        return self.included[tone - 1]  // adjusted to 0...127
    }
}

// MARK: - SystemExclusiveData

extension ToneMap: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for the tone map.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        // First, chunk the included bits into groups of seven.
        // This will result in 19 chunks, with two values in the last one.
        // Then distribute them evenly into bytes, six in each, starting
        // from the least significant bit. Start with a zero byte so that
        // the most significant bit is initialized to zero. For the last
        // byte, only the two least significant bits can ever be set.
        
        let chunks = self.included.chunked(into: 7)
        for chunk in chunks {
            var byte: Byte = 0x00  // all bits are initially zero
            for (n, bit) in chunk.enumerated() {
                if bit {
                    byte.setBit(n)
                }
            }
            data.append(byte)
        }
                
        return data
    }
    
    public var dataLength: Int { ToneMap.dataSize }
    
    public static let dataSize = 19
}

// MARK: - CustomStringConvertible

extension ToneMap: CustomStringConvertible {
    /// Printable description of this tone map.
    public var description: String {
        var s = ""
        for (index, item) in self.included.enumerated() {
            if item {
                s += "\(index + 1) "
            }
        }
        return s
    }
}
