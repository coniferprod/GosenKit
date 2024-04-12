import SyxPack
import ByteKit

/// Common settings for harmonics.
public struct HarmonicCommon {
    /// Harmonic group.
    public enum Group: String, CaseIterable {
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
    
    public var totalGain: Gain // 1~63
    
    public var group: Group
    public var keyScalingToGain: Depth // -63(1)~+63(127)
    public var velocityCurve: VelocityCurve  // 1~12 (stored in SysEx as 0~11)
    public var velocityDepth: Level  // 0~127
    
    /// Initializes default harmonic common settings.
    public init() {
        isMorfEnabled = false
        totalGain = 0x33
        group = .low
        keyScalingToGain = 0
        velocityCurve = 1
        velocityDepth = 0
    }
    
    public static func parse(from data: ByteArray) -> Result<HarmonicCommon, ParseError> {
        var offset: Int = 0
        var b: Byte = 0

        var temp = HarmonicCommon()
        
        b = data.next(&offset)
        temp.isMorfEnabled = (b == 1)
        
        b = data.next(&offset)
        temp.totalGain = Gain(Int(b))

        b = data.next(&offset)
        temp.group = Group(index: Int(b))!
        
        b = data.next(&offset)
        temp.keyScalingToGain = Depth(Int(b) - 64)
        
        b = data.next(&offset)
        temp.velocityCurve = VelocityCurve(Int(b) + 1) // 0~11 to 1~12
        
        b = data.next(&offset)
        temp.velocityDepth = Level(Int(b))

        return .success(temp)
    }
}

/// Harmonic envelope.
public struct HarmonicEnvelope {
    public struct Rate {
        private var _value: Int
    }
    
    public struct Level {
        private var _value: Int
    }
    
    /// One segment of harmonic envelope.
    public struct Segment {
        public var rate: Rate  // 0~127
        public var level: Level // 0~63
        
        public init() {
            self.rate = 0
            self.level = 0
        }
        
        /// Initializes the segment with rate and level.
        public init(rate: Rate, level: Level) {
            self.rate = rate
            self.level = level
        }
        
        public static func parse(from data: ByteArray) -> Result<Segment, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Segment()
            
            b = data.next(&offset)
            temp.rate = Rate(Int(b))
            
            b = data.next(&offset)
            temp.level = Level(Int(b))
            
            return .success(temp)
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
        self.segments = [
            Segment(rate: 127, level: 63),
            Segment(rate: 127, level: 63),
            Segment(rate: 127, level: 63),
            Segment(rate: 0, level: 0),
        ]

        self.loopKind = .off
    }
    
    /// Initializes the harmonic envelope with segments and loop kind.
    public init(segments: [Segment], loopKind: LoopKind) {
        self.segments = segments
        self.loopKind = loopKind
    }
    
    public static func parse(from data: ByteArray) -> Result<HarmonicEnvelope, ParseError> {
        var offset: Int = 0
        var b: Byte = 0

        var temp = HarmonicEnvelope()
        
        b = data.next(&offset)
        let segment0Rate = Rate(Int(b))

        b = data.next(&offset)
        let segment0Level = Level(Int(b))
        
        b = data.next(&offset)
        let segment1Rate = Rate(Int(b))
        
        b = data.next(&offset)
        let segment1LevelBit6 = b.isBitSet(6)
        
        b.clearBit(6)
        let segment1Level = Level(Int(b))

        b = data.next(&offset)
        let segment2Rate = Rate(Int(b))
        
        b = data.next(&offset)
        let segment2LevelBit6 = b.isBitSet(6)
        b.clearBit(6)
        let segment2Level = Level(Int(b))
        
        b = data.next(&offset)
        let segment3Rate = Rate(Int(b))

        b = data.next(&offset)
        let segment3Level = Level(Int(b))
        
        temp.segments = [
            Segment(rate: segment0Rate, level: segment0Level),
            Segment(rate: segment1Rate, level: segment1Level),
            Segment(rate: segment2Rate, level: segment2Level),
            Segment(rate: segment3Rate, level: segment3Level),
        ]
        
        // Need to post-process segments 1 and 2 to get the loop type
        
        switch (segment1LevelBit6, segment2LevelBit6) {
        case (true, true):
            temp.loopKind = .loop1
        case (true, false):
            temp.loopKind = .off
        case (false, true):
            temp.loopKind = .loop2
        default:
            temp.loopKind = .off
        }

        return .success(temp)
    }
}

extension HarmonicEnvelope.Rate: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

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

extension HarmonicEnvelope.Rate: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension HarmonicEnvelope.Level: RangedInt {
    public static let range: ClosedRange<Int> = 0...63

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

extension HarmonicEnvelope.Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

// Harmonic levels.
public struct HarmonicLevels {
    public var soft: [Level]  // 1~64
    public var loud: [Level]  // 65~128
    // all values are 0~127
    
    public static let harmonicCount = 64
    
    /// Initializes default harmonic levels. For both soft and loud,
    /// the first level is initialized to 127 and the rest to zero.
    public init() {
        soft = [Level]()
        soft.append(127)
        for _ in 1..<HarmonicLevels.harmonicCount {
            soft.append(0)
        }
        
        loud = [Level]()
        loud.append(127)
        for _ in 1..<HarmonicLevels.harmonicCount {
            loud.append(0)
        }
    }
    
    /// Initializes harmonic levels with soft and loud harmonics.
    public init(soft: [Int], loud: [Int]) {
        self.soft = [Level]()
        for level in soft {
            self.soft.append(Level(level))
        }
        
        self.loud = [Level]()
        for level in loud {
            self.loud.append(Level(level))
        }
    }

    /// Initializes harmonic levels from MIDI System Exclusive data bytes.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0

        var i = 0
        soft = [Level]()
        while i < HarmonicLevels.harmonicCount {
            b = d.next(&offset)
            soft.append(Level(Int(b)))
            i += 1
        }
        
        i = 0
        loud = [Level]()
        while i < HarmonicLevels.harmonicCount {
            b = d.next(&offset)
            loud.append(Level(Int(b)))
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
        
        var segment1Level = Byte(segments[1].level.value)
        var segment2Level = Byte(segments[2].level.value)

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
    public var dataLength: Int { HarmonicEnvelope.dataSize }
    
    public static let dataSize = 4 * 2 // four segments with two bytes each
}


extension HarmonicLevels: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for the harmonic levels.
    public func asData() -> ByteArray {
        var data = ByteArray()
        soft.forEach { data.append(Byte($0.value)) }
        loud.forEach { data.append(Byte($0.value)) }
        return data
    }
    
    /// The number of data bytes in the harmonic levels.
    public var dataLength: Int { HarmonicLevels.dataSize }

    public static let dataSize: Int = 128
}

extension HarmonicCommon: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for the harmonic common settings.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            isMorfEnabled ? 1 : 0,
            totalGain.value,
            group.index,
            keyScalingToGain.value + 64,
            velocityCurve.value - 1,
            velocityDepth.value
        ]
        .forEach {
            data.append(Byte($0))
        }
                
        return data
    }
    
    /// The number of data bytes in the harmonic common settings.
    public var dataLength: Int { HarmonicCommon.dataSize }

    public static let dataSize = 6
}

extension HarmonicEnvelope.Segment: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for this harmonic envelope segment.
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(rate.value), Byte(level.value))
    }
    
    /// The number of data bytes in this harmonic envelope segment.
    public var dataLength: Int { HarmonicEnvelope.Segment.dataSize }

    public static let dataSize = 2
}

// MARK: - CustomStringConvertible

extension HarmonicLevels: CustomStringConvertible {
    public var description: String {
        var s = ""
        
        s += "Soft: "
        for level in self.soft {
            s += "\(level) "
        }
        
        s += "\nLoud: "
        for level in self.loud {
            s += "\(level) "
        }
            
        return s
    }
}

extension HarmonicEnvelope.Segment: CustomStringConvertible {
    /// Gets a printable representation of this harmonic envelope segment.
    public var description: String {
        return "L\(self.level) R\(self.rate)"
    }
}

extension HarmonicEnvelope.Level: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

extension HarmonicEnvelope.Rate: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

extension HarmonicEnvelope.LoopKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .off:
            return "OFF"
        case .loop1:
            return "LOOP1"
        case .loop2:
            return "LOOP2"
        }
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

extension HarmonicCommon: CustomStringConvertible {
    /// Gets a printable representation of the harmonic common settings.
    public var description: String {
        var s = "  MORF enabled = " + (self.isMorfEnabled ? "yes" : "no") + "\n"
        s += "  Total gain = \(self.totalGain)\n"
        s += "  Group = \(self.group)\n"
        s += "  KStoGain = \(self.keyScalingToGain)\n"
        s += "  Velocity curve = \(self.velocityCurve)\n"
        s += "  Velocity depth = \(self.velocityDepth)"
        return s
    }
}

extension HarmonicCommon.Group: CustomStringConvertible {
    public var description: String {
        switch self {
        case .low:
            return "LO"
        case .high:
            return "HI"
        }
    }
}
