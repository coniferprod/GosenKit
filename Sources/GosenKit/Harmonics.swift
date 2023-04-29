import SyxPack

/// Common settings for harmonics.
public struct HarmonicCommon: Codable {
    public enum Group: String, Codable, CaseIterable {
        case low
        case high
        
        /// Initializes the group from a data byte.
        public init?(index: Int) {
            switch index {
            case 0: self = .low
            case 1: self = .high
            default: return nil
            }
        }
    }

    public var isMorfEnabled: Bool
    
    public var totalGain: Int // 1~63
    
    public var group: Group
    public var keyScalingToGain: Int // -63(1)~+63(127)
    public var velocityCurve: Int  // 1~12 (stored in SysEx as 0~11)
    public var velocityDepth: Int  // 0~127
    
    /// Initializes default harmonic common settings.
    public init() {
        isMorfEnabled = false
        totalGain = 0x33
        group = .low
        keyScalingToGain = 0
        velocityCurve = 1
        velocityDepth = 0
    }
    
    /// Initializes harmonic common settings from MIDI System Exclusive data bytes.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        isMorfEnabled = (b == 1)
        
        b = d.next(&offset)
        totalGain = Int(b)

        b = d.next(&offset)
        group = Group(index: Int(b))!
        
        b = d.next(&offset)
        keyScalingToGain = Int(b) - 64
        
        b = d.next(&offset)
        velocityCurve = Int(b) + 1 // 0~11 to 1~12
        
        b = d.next(&offset)
        velocityDepth = Int(b)
    }
}

/// Harmonic envelope.
public struct HarmonicEnvelope: Codable {
    /// One segment of harmonic envelope.
    public struct Segment: Codable {
        public var rate: Int  // 0~127
        public var level: Int // 0~63
        
        /// Initializes the segment with rate and level.
        public init(rate: Int, level: Int) {
            self.rate = rate
            self.level = level
        }
        
        /// Initializes the segment from MIDI System Exclusive data bytes.
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            b = d.next(&offset)
            rate = Int(b)
            
            b = d.next(&offset)
            level = Int(b)
        }
    }

    public var segments: [Segment]
    
    /// The loop kind of the harmonic envelope. Used in formant filter, harmonic, and MORF envelopes.
    public enum LoopKind: String, Codable, CaseIterable {
        case off
        case loop1
        case loop2
        
        /// Initializes the loop kind from a data byte.
        public init?(index: Int) {
            switch index {
            case 0: self = .off
            case 1: self = .loop1
            case 2: self = .loop2
            default: return nil
            }
        }
    }

    public var loopKind: LoopKind
    
    /// Initializes the harmonic envelope with default settings.
    public init() {
        self.segments = [Segment]()
        self.segments.append(Segment(rate: 127, level: 63))
        self.segments.append(Segment(rate: 127, level: 63))
        self.segments.append(Segment(rate: 127, level: 63))
        self.segments.append(Segment(rate: 0, level: 0))

        self.loopKind = .off
    }
    
    /// Initializes the harmonic envelope with segments and loop kind.
    public init(segments: [Segment], loopKind: LoopKind) {
        self.segments = segments
        self.loopKind = loopKind
    }
    
    /// Initializes the harmonic envelope from MIDI System Exclusive data bytes.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0

        b = d.next(&offset)
        let segment0Rate = Int(b)

        b = d.next(&offset)
        let segment0Level = Int(b)
        
        //print("segment0 rate = 0x\(String(segment0Rate, radix: 16)) level = 0x\(String(segment0Level, radix: 16))")
        
        b = d.next(&offset)
        let segment1Rate = Int(b)
        
        b = d.next(&offset)
        let segment1LevelBit6 = b.isBitSet(6)
        //print("segment1 rate = 0x\(String(segment1Rate, radix: 16)) level = 0x\(String(b, radix: 16)) = 0b\(String(b, radix: 2))")
        //print("bit 6 of segment 1 level set? \(segment1LevelBit6 ? "YES" : "NO")")
        
        b.clearBit(6)
        let segment1Level = Int(b)

        b = d.next(&offset)
        let segment2Rate = Int(b)
        
        b = d.next(&offset)
        let segment2LevelBit6 = b.isBitSet(6)
        //print("segment2 rate = 0x\(String(segment2Rate, radix: 16)) level = 0x\(String(b, radix: 16)) = 0b\(String(b, radix: 2))")
        //print("bit 6 of segment 1 level set? \(segment2LevelBit6 ? "YES" : "NO")")
        b.clearBit(6)
        let segment2Level = Int(b)
        
        b = d.next(&offset)
        let segment3Rate = Int(b)

        b = d.next(&offset)
        let segment3Level = Int(b)
        
        //print("segment3 rate = 0x\(String(segment3Rate, radix: 16)) level = 0x\(String(segment3Level, radix: 16))")

        segments = [Segment]()
        segments.append(Segment(rate: segment0Rate, level: segment0Level))
        segments.append(Segment(rate: segment1Rate, level: segment1Level))
        segments.append(Segment(rate: segment2Rate, level: segment2Level))
        segments.append(Segment(rate: segment3Rate, level: segment3Level))
        
        // Need to post-process segments 1 and 2 to get the loop type
        
        switch (segment1LevelBit6, segment2LevelBit6) {
        case (true, true):
            loopKind = .loop1
        case (true, false):
            //sprint("warning: impossible loop type value '0b10', setting loop type to OFF", to: &standardError)
            loopKind = .off
        case (false, true):
            loopKind = .loop2
        default:
            loopKind = .off
        }
    }
}

// Harmonic levels.
public struct HarmonicLevels: Codable {
    public var soft: [Int]  // 1~64
    public var loud: [Int]  // 65~128
    // all values are 0~127
    
    public static let harmonicCount = 64
    
    /// Initializes default harmonic levels. For both soft and loud,
    /// the first level is initialized to 127 and the rest to zero.
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
    
    /// Initializes harmonic levels with soft and loud harmonics.
    public init(soft: [Int], loud: [Int]) {
        self.soft = soft
        self.loud = loud
    }

    /// Initializes harmonic levels from MIDI System Exclusive data bytes.
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
}

// MARK: - SystemExclusiveData

extension HarmonicEnvelope: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for this harmonic envelope.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: segments[0].asData())
        
        // When emitting segment1 and segment2 data,
        // we need to bake the loop type into the levels.
        
        var segment1Level = Byte(segments[1].level)
        var segment2Level = Byte(segments[2].level)

        if loopKind == .loop2 {  // bit pattern from bits 6 of L1 and L2 = "01"
            segment1Level.clearBit(6)
            segment2Level.setBit(6)
        }
        else if loopKind == .loop1 {    // "11"
            segment1Level.setBit(6)
            segment2Level.setBit(6)
        }
        else if loopKind == .off {  // "00"
            segment1Level.clearBit(6)
            segment2Level.clearBit(6)
        }
        
        var segment1Data = segments[1].asData()
        //print("< HARM ENV seg1 level = 0x\(String(segment1Level, radix: 16))")
        segment1Data[1] = segment1Level
        data.append(contentsOf: segment1Data)

        var segment2Data = segments[2].asData()
        //print("> HARM ENV seg2 level = 0x\(String(segment2Level, radix: 16))")
        segment2Data[1] = segment2Level
        data.append(contentsOf: segment2Data)

        data.append(contentsOf: segments[3].asData())

        return data
    }
    
    /// The number of data bytes in the harmonic envelope.
    public var dataLength: Int { return HarmonicEnvelope.dataSize }
    
    public static let dataSize = 4 * 2 // four segments with two bytes each
}


extension HarmonicLevels: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for the harmonic levels.
    public func asData() -> ByteArray {
        var data = ByteArray()
        soft.forEach { data.append(Byte($0)) }
        loud.forEach { data.append(Byte($0)) }
        return data
    }
    
    /// The number of data bytes in the harmonic levels.
    public var dataLength: Int { return HarmonicLevels.dataSize }

    public static let dataSize: Int = 128
}

extension HarmonicCommon: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for the harmonic common settings.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(isMorfEnabled ? 1 : 0)
        data.append(Byte(totalGain))
        data.append(Byte(group.index))
        data.append(Byte(keyScalingToGain + 64))
        data.append(Byte(velocityCurve - 1))
        data.append(Byte(velocityDepth))
        
        return data
    }
    
    /// The number of data bytes in the harmonic common settings.
    public var dataLength: Int { return HarmonicCommon.dataSize }

    public static let dataSize = 6
}

extension HarmonicEnvelope.Segment: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for this harmonic envelope segment.
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(rate), Byte(level))
    }
    
    /// The number of data bytes in this harmonic envelope segment.
    public var dataLength: Int { return HarmonicEnvelope.Segment.dataSize }

    public static let dataSize = 2
}

// MARK: - CustomStringConvertible

extension HarmonicEnvelope.Segment: CustomStringConvertible {
    /// Gets a printable representation of this harmonic envelope segment.
    public var description: String {
        return "L\(level) R\(rate)"
    }
}

extension HarmonicEnvelope: CustomStringConvertible {
    /// Gets a printable representation of this harmonic envelope.
    public var description: String {
        var s = "  Atk  DC1  DC2  RLS\n"
        
        s += "    Lvl  "
        for seg in segments {
            s += "\(seg.level)   "
        }
        s += "\n"

        s += "   Rate  "
        for seg in segments {
            s += "\(seg.rate)   "
        }
        s += "\n"

        s += "   Decay Loop: \(loopKind)\n"
        
        return s
    }
}
