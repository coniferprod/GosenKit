import Foundation

/// Represents the set of included patches in a bank.
public class ToneMap: CustomStringConvertible {
    public static let size = 19  // bytes
    public static let patchCount = 128
    
    private var include = [Bool]()
    
    public init() {
        self.include = [Bool](repeating: false, count: ToneMap.patchCount)
    }
    
    public init(data: ByteArray) {
        self.include = [Bool]()
        for (index, item) in data.enumerated() {
            for j in 0..<7 {
                self.include.append(item.isBitSet(j))
            }
        }
    }
    
    subscript(index: Int) -> Bool {
        return self.include[index]
    }
    
    public var includedCount: Int {
        return self.include.filter { $0 == true }.count
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
     
        var bits = [Bool]()
        for i in 0..<ToneMap.patchCount {
            bits.append(self.include[i] ? true : false)
            
            // each byte maps seven patches, and every 8th bit must be a zero
            if i % 8 == 0 {
                bits.append(false)
            }
        }
        
        // The patches are enumerated starting from the low bits, so first reverse the string.
        // Then slice it into chunks of eight bits to convert to bytes.
        let bytes = bits.reversed().chunked(into: 8)
        for bb in bytes {
            var by: Byte = 0x00
            for (i, b) in bb.enumerated() {
                if b {
                    by.setBit(i)
                }
            }
            data.append(by)
        }

        return data
    }
    
    public var description: String {
        var s = ""
        for (index, item) in self.include.enumerated() {
            if item {
                s += "\(index + 1) "
            }
        }
        
        return s
    }
}
