import SyxPack

/// Represents the set of included patches in a bank.
public class ToneMap {
    private let maxCount = 128
    private var included: [Bool]  // true if patch is included, false if not
    
    /// Initializes an empty tone map.
    public init() {
        self.included = [Bool](repeating: false, count: maxCount)
    }
    
    /// Initializes a tone map from System Exclusive data.
    /// Assumes that `data` contains `maxCount` bytes,
    public init(data: ByteArray) {
        self.included = [Bool]()
        for (_, byte) in data.enumerated() {
            // Take the bottom seven bits of each byte
            for bit in 0..<7 {
                self.included.append(byte.isBitSet(bit))
            }
        }
    }
    
    /// Sets or resets the included status of the tone at `index`.
    subscript(index: Int) -> Bool {
        get {
            return self.included[index]
        }
        set(newValue) {
            // Only set if the index is in valid range
            if (0..<maxCount).contains(index) {
                self.included[index] = newValue
            }
        }
    }
    
    /// The number of patches included.
    public var includedCount: Int {
        self.included.filter { $0 }.count
    }
    
    /// Checks if the tone map includes `tone`.
    ///
    /// - Parameters:
    ///      - tone: The tone number from 1 to 128
    /// - Returns: `true` if the tone is included, `false` if not
    public func includes(tone: Int) -> Bool {
        guard (1...maxCount).contains(tone) else {
            return false
        }
        return self.included[tone - 1]  // adjusted to 0...127
    }
}

// MARK: - SystemExclusiveData

extension ToneMap: SystemExclusiveData {
    /// Byte array representation for SysEx.
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
