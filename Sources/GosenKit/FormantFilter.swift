import SyxPack
import ByteKit

/// Represents a formant filter.
public struct FormantFilter {
    /// Formant filter envelope.
    public struct Envelope {
        /// Formant filter envelope rate (0~127).
        public struct Rate {
            private var _value: Int
        }
        
        /// Format filter envelope level (-63~+63).
        public struct Level {
            private var _value: Int
        }
        
        /// Formant filter envelope segment.
        public struct Segment {
            public var rate: Rate  // 0~127
            public var level: Level // -63(1)~+63(127)
            
            public init() {
                self.rate = 0
                self.level = 0
            }
            
            public init(rate: Int, level: Int) {
                self.rate = Rate(rate)
                self.level = Level(level)
            }
            
            public static func parse(from data: ByteArray) -> Result<Segment, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                
                var temp = Segment()
                
                b = data.next(&offset)
                temp.rate = Rate(Int(b))
                
                b = data.next(&offset)
                temp.level = Level(Int(b) - 64)
                
                return .success(temp)
            }
        }

        public var attack: Segment
        public var decay1: Segment
        public var decay2: Segment
        public var release: Segment
        public var decayLoop: HarmonicEnvelope.LoopKind
        public var velocityDepth: Depth // -63(1)~+63(127)
        public var keyScalingDepth: Depth // -63(1)~+63(127)
        
        public init() {
            attack = Segment(rate: 127, level: 63)
            decay1 = Segment(rate: 127, level: 63)
            decay2 = Segment(rate: 127, level: 63)
            release = Segment(rate: 127, level: 63)
            decayLoop = .off
            velocityDepth = 0
            keyScalingDepth = 0
        }
        
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Envelope()
            
            let size = Segment.dataSize
            
            switch Segment.parse(from: data.slice(from: offset, length: size)) {
            case .success(let seg):
                temp.attack = seg
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            switch Segment.parse(from: data.slice(from: offset, length: size)) {
            case .success(let seg):
                temp.decay1 = seg
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            switch Segment.parse(from: data.slice(from: offset, length: size)) {
            case .success(let seg):
                temp.decay2 = seg
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            switch Segment.parse(from: data.slice(from: offset, length: size)) {
            case .success(let seg):
                temp.release = seg
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            b = data.next(&offset)
            temp.decayLoop = HarmonicEnvelope.LoopKind(index: Int(b))!
            
            b = data.next(&offset)
            temp.velocityDepth = Depth(Int(b) - 64)

            b = data.next(&offset)
            temp.keyScalingDepth = Depth(Int(b) - 64)

            return .success(temp)
        }
    }
    
    /// Formant filter LFO.
    public struct LFO {
        public enum Shape: String, Codable, CaseIterable {
            case triangle
            case sawtooth
            case random
            
            public init?(index: Int) {
                switch index {
                case 0: self = .triangle
                case 1: self = .sawtooth
                case 2: self = .random
                default: return nil
                }
            }
        }

        /// Format filter LFO depth (0~63).
        public struct Depth {
            private var _value: Int
        }
        
        public var speed: Level  // 0~127
        public var shape: Shape
        public var depth: Depth  // 0~63
        
        public init() {
            shape = .triangle
            speed = 0
            depth = 0
        }
        
        public static func parse(from data: ByteArray) -> Result<LFO, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = LFO()
            
            b = data.next(&offset)
            temp.speed = Level(Int(b))

            b = data.next(&offset)
            temp.shape = Shape(index: Int(b))!
            
            b = data.next(&offset)
            temp.depth = Depth(Int(b))

            return .success(temp)
        }
    }

    /// Formant filter mode.
    public enum Mode: String, Codable, CaseIterable {
        case envelope
        case lfo
        
        public init?(index: Int) {
            switch index {
            case 0: self = .envelope
            case 1: self = .lfo
            default: return nil
            }
        }
    }

    /// Formant filter bands.
    public struct Bands {
        public var levels: [Level]  // all 0~127

        public static let bandCount = 128

        public init() {
            levels = Array(repeating: Level(127), count: Bands.bandCount)
        }
           
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            levels = [Level]()
            for _ in 0 ..< Bands.bandCount {
                b = d.next(&offset)
                levels.append(Level(Int(b)))
            }
        }
    }
    
    public var bias: Depth  // -63(1)~+63(127)
    public var mode: Mode  // 0=ENV, 1=LFO
    public var envelopeDepth: Depth // -63(1)~+63(127)
    public var envelope: Envelope
    public var lfo: LFO
    
    public init() {
        bias = -10
        mode = .envelope
        envelopeDepth = 0
        envelope = Envelope()
        lfo = LFO()
    }
    
    public static func parse(from data: ByteArray) -> Result<FormantFilter, ParseError> {
        var offset: Int = 0
        var b: Byte = 0

        var temp = FormantFilter()
        
        b = data.next(&offset)
        temp.bias = Depth(Int(b) - 64)
        
        b = data.next(&offset)
        temp.mode = Mode(index: Int(b))!
        
        b = data.next(&offset)
        temp.envelopeDepth = Depth(Int(b) - 64)
        
        var size = Envelope.dataSize
        switch Envelope.parse(from: data.slice(from: offset, length: size)) {
        case .success(let env):
            temp.envelope = env
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = LFO.dataSize
        switch LFO.parse(from: data.slice(from: offset, length: size)) {
        case .success(let lfo):
            temp.lfo = lfo
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
}

extension FormantFilter.Envelope.Rate: RangedInt {
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

extension FormantFilter.Envelope.Rate: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension FormantFilter.Envelope.Level: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

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

extension FormantFilter.Envelope.Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension FormantFilter.LFO.Depth: RangedInt {
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

extension FormantFilter.LFO.Depth: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

// MARK: - SystemExclusiveData

extension FormantFilter.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: attack.asData())
        data.append(contentsOf: decay1.asData())
        data.append(contentsOf: decay2.asData())
        data.append(contentsOf: release.asData())
        
        [
            decayLoop.index,
            velocityDepth.value + 64,
            keyScalingDepth.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        return data
    }
    
    public var dataLength: Int { FormantFilter.Envelope.dataSize }
    
    public static let dataSize = 11
}

extension FormantFilter.Envelope.Segment: SystemExclusiveData {
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(rate.value), Byte(level.value + 64))
    }
    
    public var dataLength: Int { FormantFilter.Envelope.Segment.dataSize }
    
    public static let dataSize = 2
}

extension FormantFilter: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()

        [
            bias.value + 64,
            mode.index,
            envelopeDepth.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: lfo.asData())
        
        return data
    }
    
    public var dataLength: Int { FormantFilter.dataSize }
    
    public static let dataSize = 17  // does not include the bands!
}

extension FormantFilter.Bands: SystemExclusiveData {
    public func asData() -> ByteArray {
        return levels.map { Byte($0.value) }
    }

    public var dataLength: Int { FormantFilter.Bands.dataSize }

    public static let dataSize = 128
}

extension FormantFilter.LFO: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            speed.value,
            shape.index,
            depth.value
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        return data
    }
    
    public var dataLength: Int { FormantFilter.LFO.dataSize }

    public static let dataSize = 3
}

// MARK: - CustomStringConvertible

extension FormantFilter: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Bias: \(self.bias) "
        s += "Mode: \(self.mode) "
        s += "Env Depth: \(self.envelopeDepth) "
        s += "Envelope: \(self.envelope) "
        s += "LFO: \(self.lfo)"
        return s
    }
}

extension FormantFilter.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .envelope:
            return "ENV"
        case .lfo:
            return "LFO"
        }
    }
}

extension FormantFilter.Envelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Attack = \(self.attack) "
        s += "Decay1: \(self.decay1) "
        s += "Decay2: \(self.decay2) "
        s += "Release: \(self.release) "
        s += "Decay Loop: \(self.decayLoop) "
        s += "Vel Depth: \(self.velocityDepth) "
        s += "KS Depth: \(self.keyScalingDepth)"
        return s
    }
}

extension FormantFilter.Envelope.Segment: CustomStringConvertible {
    public var description: String {
        return "L\(self.level) R\(self.rate)"
    }
}

extension FormantFilter.LFO.Shape: CustomStringConvertible {
    public var description: String {
        switch self {
        case .triangle:
            return "TRI"
        case .sawtooth:
            return "SAW"
        case .random:
            return "RND"
        }
    }
}

extension FormantFilter.LFO.Depth: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

extension FormantFilter.LFO: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Speed: \(self.speed) "
        s += "Shape: \(self.shape) "
        s += "Depth: \(self.depth)"
        return s
    }
}

extension FormantFilter.Envelope.Rate: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}

extension FormantFilter.Envelope.Level: CustomStringConvertible {
    // Generates a string representation of the value.
    public var description: String {
        return "\(self.value)"
    }
}
