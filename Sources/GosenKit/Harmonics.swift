import Foundation

public enum HarmonicGroupType: String, Codable, CaseIterable {
    case low
    case high
    
    public init?(index: Int) {
        switch index {
        case 0: self = .low
        case 1: self = .high
        default: return nil
        }
    }
}

public struct HarmonicCommonSettings: Codable {
    public var isMorfEnabled: Bool
    public var totalGain: Int // 1~63
    public var group: HarmonicGroupType
    public var keyScalingToGain: Int // -63(1)~+63(127)
    public var velocityCurve: Int  // 1~12 (stored in SysEx as 0~11)
    public var velocityDepth: Int  // 0~127
    
    static let dataLength = 6
    
    public init() {
        isMorfEnabled = false
        totalGain = 0x33
        group = .low
        keyScalingToGain = 0
        velocityCurve = 1
        velocityDepth = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        isMorfEnabled = (b == 1)
        
        b = d.next(&offset)
        totalGain = Int(b)

        b = d.next(&offset)
        group = HarmonicGroupType(index: Int(b))!
        
        b = d.next(&offset)
        keyScalingToGain = Int(b) - 64
        
        b = d.next(&offset)
        velocityCurve = Int(b) + 1 // 0~11 to 1~12
        
        b = d.next(&offset)
        velocityDepth = Int(b)
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(isMorfEnabled ? 1 : 0)
        data.append(Byte(totalGain))
        data.append(Byte(group.index!))
        data.append(Byte(keyScalingToGain + 64))
        data.append(Byte(velocityCurve - 1))
        data.append(Byte(velocityDepth))
        
        return data
    }
}

public struct EnvelopeSegment: Codable {
    public var rate: Int  // 0~127
    public var level: Int // -63(1)~+63(127)
    
    static let dataLength = 2
    
    public init(rate: Int, level: Int) {
        self.rate = rate
        self.level = level
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        rate = Int(b)
        
        b = d.next(&offset)
        level = Int(b) - 64
    }
        
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(rate))
        data.append(Byte(level + 64))
        
        return data
    }
}

extension EnvelopeSegment: CustomStringConvertible {
    public var description: String {
        return "L\(level) R\(rate)"
    }
}

public struct HarmonicEnvelopeSegment: Codable {
    public var rate: Int  // 0~127
    public var level: Int // 0~63
    
    static let dataLength = 2
    
    public init(rate: Int, level: Int) {
        self.rate = rate
        self.level = level
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        rate = Int(b)
        
        b = d.next(&offset)
        level = Int(b)
    }
        
    func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(rate), Byte(level))
    }
}

extension HarmonicEnvelopeSegment: CustomStringConvertible {
    public var description: String {
        return "L\(level) R\(rate)"
    }
}

public enum EnvelopeLoopType: String, Codable, CaseIterable {
    case off
    case loop1
    case loop2
    
    public init?(index: Int) {
        switch index {
        case 0: self = .off
        case 1: self = .loop1
        case 2: self = .loop2
        default: return nil
        }
    }
}

public struct HarmonicEnvelope: Codable {
    public var segment0: HarmonicEnvelopeSegment
    public var segment1: HarmonicEnvelopeSegment
    public var segment2: HarmonicEnvelopeSegment
    public var segment3: HarmonicEnvelopeSegment
    public var loopType: EnvelopeLoopType
    
    static let dataLength = 4 * HarmonicEnvelopeSegment.dataLength
    
    public init() {
        self.segment0 = HarmonicEnvelopeSegment(rate: 127, level: 63)
        self.segment1 = HarmonicEnvelopeSegment(rate: 127, level: 63)
        self.segment2 = HarmonicEnvelopeSegment(rate: 127, level: 63)
        self.segment3 = HarmonicEnvelopeSegment(rate: 0, level: 0)
        self.loopType = .off
    }
    
    public init(segment0: HarmonicEnvelopeSegment, segment1: HarmonicEnvelopeSegment, segment2: HarmonicEnvelopeSegment, segment3: HarmonicEnvelopeSegment, loopType: EnvelopeLoopType) {
        self.segment0 = segment0
        self.segment1 = segment1
        self.segment2 = segment2
        self.segment3 = segment3
        self.loopType = loopType
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0

        //print("> HARM ENV = \(d.hexDump)")
        
        // I'm just going to test out my new ByteArray extension
        // to see how it feels like...
        
        // Old code:
        //b = d[offset]
        //let segment0Rate = Int(b)
        //offset += 1

        // New code:
        b = d.next(&offset)
        let segment0Rate = Int(b)

        // You just need to remember to use & for the inout parameter
        
        b = d.next(&offset)
        let segment0Level = Int(b)
        
        //print("segment0 rate = 0x\(String(segment0Rate, radix: 16)) level = 0x\(String(segment0Level, radix: 16))")
        
        b = d.next(&offset)
        let segment1Rate = Int(b)
        
        b = d.next(&offset)
        let segment1LevelBit6 = b.isBitSet(6)
        //print("segment1 rate = 0x\(String(segment1Rate, radix: 16)) level = 0x\(String(b, radix: 16)) = 0b\(String(b, radix: 2))")
        //print("bit 6 of segment 1 level set? \(segment1LevelBit6 ? "YES" : "NO")")
        
        b.unsetBit(6)
        let segment1Level = Int(b)

        b = d.next(&offset)
        let segment2Rate = Int(b)
        
        b = d.next(&offset)
        let segment2LevelBit6 = b.isBitSet(6)
        print("segment2 rate = 0x\(String(segment2Rate, radix: 16)) level = 0x\(String(b, radix: 16)) = 0b\(String(b, radix: 2))")
        //print("bit 6 of segment 1 level set? \(segment2LevelBit6 ? "YES" : "NO")")
        b.unsetBit(6)
        let segment2Level = Int(b)
        
        b = d.next(&offset)
        let segment3Rate = Int(b)

        b = d.next(&offset)
        let segment3Level = Int(b)
        
        //print("segment3 rate = 0x\(String(segment3Rate, radix: 16)) level = 0x\(String(segment3Level, radix: 16))")

        segment0 = HarmonicEnvelopeSegment(rate: segment0Rate, level: segment0Level)
        segment1 = HarmonicEnvelopeSegment(rate: segment1Rate, level: segment1Level)
        segment2 = HarmonicEnvelopeSegment(rate: segment2Rate, level: segment2Level)
        segment3 = HarmonicEnvelopeSegment(rate: segment3Rate, level: segment3Level)
        
        // Need to post-process segments 1 and 2 to get the loop type
        
        var bitString = ""
        bitString += segment1LevelBit6 ? "1" : "0"
        bitString += segment2LevelBit6 ? "1" : "0"
        print(bitString)
        if bitString == "10" {
            print("warning: impossible loop type value '\(bitString)', setting loop to OFF")
            loopType = .off
        }
        else if bitString == "11" {
            loopType = .loop1
        }
        else if bitString == "01" {
            loopType = .loop2
        }
        else {
            loopType = .off
        }
    }

    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: segment0.asData())
        
        // When emitting segment1 and segment2 data,
        // we need to bake the loop type into the levels.
        
        var segment1Level = Byte(segment1.level)
        var segment2Level = Byte(segment2.level)

        if loopType == .loop2 {  // bit pattern from bits 6 of L1 and L2 = "01"
            segment1Level.unsetBit(6)
            segment2Level.setBit(6)
        }
        else if loopType == .loop1 {    // "11"
            segment1Level.setBit(6)
            segment2Level.setBit(6)
        }
        else if loopType == .off {  // "00"
            segment1Level.unsetBit(6)
            segment2Level.unsetBit(6)
        }
        
        var segment1Data = segment1.asData()
        //print("< HARM ENV seg1 level = 0x\(String(segment1Level, radix: 16))")
        segment1Data[1] = segment1Level
        data.append(contentsOf: segment1Data)

        var segment2Data = segment2.asData()
        //print("> HARM ENV seg2 level = 0x\(String(segment2Level, radix: 16))")
        segment2Data[1] = segment2Level
        data.append(contentsOf: segment2Data)

        data.append(contentsOf: segment3.asData())

        //print("< HARM ENV = \(Data(data).hexDump)")

        return data
    }
}

extension HarmonicEnvelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "  Atk  DC1  DC2  RLS\n"
        s += "    Lvl  \(segment0.level)   \(segment1.level)   \(segment2.level)   \(segment3.level)\n"
        s += "   Rate  \(segment0.rate)   \(segment1.rate)   \(segment2.rate)   \(segment3.rate)\n"
        s += "   Decay Loop: \(loopType)\n"
        return s
    }
}

public struct HarmonicLevels: Codable {
    public var soft: [Int]  // 1~64
    public var loud: [Int]  // 65~128
    // all values are 0~127
    
    static let harmonicCount = 64
    
    static let dataLength = 128
    
    public init() {
        soft = [Int]()
        soft.append(127)
        for _ in 1..<HarmonicLevels.harmonicCount {
            soft.append(0)
        }
        
        loud = [Int]()
        loud.append(127)
        for _ in 1..<HarmonicLevels.harmonicCount {
            loud.append(0)
        }
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0

        var i = 0
        soft = [Int]()
        while i < HarmonicLevels.harmonicCount {
            b = d.next(&offset)
            soft.append(Int(b))
            i += 1
        }
        
        i = 0
        loud = [Int]()
        while i < HarmonicLevels.harmonicCount {
            b = d.next(&offset)
            loud.append(Int(b))
            i += 1
        }
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        for i in 0..<HarmonicLevels.harmonicCount {
            data.append(Byte(soft[i]))
        }

        for i in 0..<HarmonicLevels.harmonicCount {
            data.append(Byte(loud[i]))
        }

        return data
    }
}
