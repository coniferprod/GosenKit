import Foundation

import SyxPack
import ByteKit

/// Represents a formant filter.
public struct FormantFilter {
    /// Formant filter envelope.
    public struct Envelope {
        /// Formant filter envelope segment with rate and level.
        public struct Segment {
            public var rate: Int  // 0~127
            public var level: Int // -63(1)~+63(127)
            
            /// Initializes a formant filter envelope segment with specific `Int` values.
            public init(rate: Int = 0, level: Int = 0) {
                self.rate = rate
                self.level = level
            }

            /// Parses formant filter envelope segment from System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<Segment, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                
                var temp = Segment()
                
                b = data.next(&offset)
                temp.rate = Int(b)
                
                b = data.next(&offset)
                temp.level = Int(b) + descriptors[.filterEnvelopeLevel]!.incomingOffset
                
                return .success(temp)
            }
            
            public var xml: String {
                "<rate>\(rate)</rate></level>\(level)</level>"
            }
        }

        public var attack: Segment
        public var decay1: Segment
        public var decay2: Segment
        public var release: Segment
        public var decayLoop: HarmonicEnvelope.LoopKind
        public var velocityDepth: Int // -63(1)~+63(127)
        public var keyScalingDepth: Int // -63(1)~+63(127)
        
        /// Initializes formant filter envelope with default values.
        public init() {
            self.attack = Segment(rate: 127, level: 63)
            self.decay1 = Segment(rate: 127, level: 63)
            self.decay2 = Segment(rate: 127, level: 63)
            self.release = Segment(rate: 127, level: 63)
            self.decayLoop = .off
            self.velocityDepth = 0
            self.keyScalingDepth = 0
        }
        
        /// Parses formant filter envelope from System Exclusive data.
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
            
            let descriptor = descriptors[.depth]!
            b = data.next(&offset)
            temp.velocityDepth = Int(b) + descriptor.incomingOffset

            b = data.next(&offset)
            temp.keyScalingDepth = Int(b) + descriptor.incomingOffset

            return .success(temp)
        }
    }
    
    /// Formant filter LFO.
    public struct LFO {
        /// Formant filter LFO shape.
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

        public var speed: Int  // 0~127
        public var shape: Shape
        public var depth: Int  // 0~63

        /// Initializes formant filter LFO with default values.
        public init() {
            self.shape = .triangle
            self.speed = 0
            self.depth = 0
        }
        
        /// Parses formant filter LFO from System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<LFO, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = LFO()
            
            b = data.next(&offset)
            temp.speed = Int(b)

            b = data.next(&offset)
            temp.shape = Shape(index: Int(b))!
            
            b = data.next(&offset)
            temp.depth = Int(b)

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
        
        public var xml: String {
            "<mode>\(self.rawValue)</mode>"
        }
    }

    /// Formant filter bands.
    public struct Bands {
        public var levels: [Int]  // all values are 0~127

        public static let bandCount = 128

        /// Initializes the formant filter bands with default values.
        public init() {
            self.levels = Array(repeating: 0, count: Bands.bandCount)
        }
        
        /// Initializes the formant filter bands with specific levels.
        public init(levels: [Int]) {
            // Make sure that there are at max 128 levels
            self.levels = [Int](levels.prefix(upTo: Bands.bandCount))
        }
        
        /// Parses the formant filter bands from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Bands, ParseError> {
            guard
                data.count == Bands.bandCount
            else {
                return .failure(.invalidLength(data.count, Bands.bandCount))
            }
            
            var temp = Bands()
            
            var offset: Int = 0
            var b: Byte = 0
            
            var levels = [Int]()
            for _ in 0 ..< Bands.bandCount {
                b = data.next(&offset)
                levels.append(Int(b))
            }
            
            temp.levels = levels
            return .success(temp)
        }
    }
    
    public var bias: Int  // -63(1)~+63(127)
    public var mode: Mode  // 0=ENV, 1=LFO
    public var envelopeDepth: Int // -63(1)~+63(127)
    public var envelope: Envelope
    public var lfo: LFO
    
    /// Initialize the formant filter with default values.
    public init() {
        self.bias = -10
        self.mode = .envelope
        self.envelopeDepth = 0
        self.envelope = Envelope()
        self.lfo = LFO()
    }
    
    /// Parse the formant filter from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<FormantFilter, ParseError> {
        var offset: Int = 0
        var b: Byte = 0

        var temp = FormantFilter()
        
        let descriptor = descriptors[.depth]!
        
        b = data.next(&offset)
        temp.bias = Int(b) + descriptor.incomingOffset
        
        b = data.next(&offset)
        temp.mode = Mode(index: Int(b))!
        
        b = data.next(&offset)
        temp.envelopeDepth = Int(b) + descriptor.incomingOffset
        
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

// MARK: - SystemExclusiveData protocol conformance

extension FormantFilter.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.attack.asData())
        data.append(contentsOf: self.decay1.asData())
        data.append(contentsOf: self.decay2.asData())
        data.append(contentsOf: self.release.asData())
        
        let descriptor = descriptors[.depth]!
        [
            self.decayLoop.index,
            self.velocityDepth + descriptor.outgoingOffset,
            self.keyScalingDepth + descriptor.outgoingOffset,
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
        return ByteArray(arrayLiteral: Byte(rate), Byte(level + descriptors[.filterEnvelopeLevel]!.outgoingOffset))
    }
    
    public var dataLength: Int { FormantFilter.Envelope.Segment.dataSize }
    
    public static let dataSize = 2
}

extension FormantFilter: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()

        let descriptor = descriptors[.depth]!
        [
            self.bias + descriptor.outgoingOffset,
            self.mode.index,
            self.envelopeDepth + descriptor.outgoingOffset,
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: self.envelope.asData())
        data.append(contentsOf: self.lfo.asData())
        
        return data
    }
    
    public var dataLength: Int { FormantFilter.dataSize }
    
    public static let dataSize = 17  // does not include the bands!
}

extension FormantFilter.Bands: SystemExclusiveData {
    public func asData() -> ByteArray {
        return self.levels.map { Byte($0) }
    }

    public var dataLength: Int { FormantFilter.Bands.dataSize }

    public static let dataSize = 128
}

extension FormantFilter.LFO: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            self.speed,
            self.shape.index,
            self.depth
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        return data
    }
    
    public var dataLength: Int { FormantFilter.LFO.dataSize }

    public static let dataSize = 3
}

// MARK: - CustomStringConvertible protocol conformance

extension FormantFilter: CustomStringConvertible {
    /// Generates a string representation of the value.
    public var description: String {
        var s = ""
        s += "  Bias: \(self.bias)\n"
        s += "  Mode: \(self.mode)\n"
        s += "  Env Depth: \(self.envelopeDepth)\n"
        s += "  Envelope: \(self.envelope)\n"
        s += "  LFO: \(self.lfo)"
        return s
    }
}

extension FormantFilter.Mode: CustomStringConvertible {
    /// Generates a string representation of the value.
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
    /// Generates a string representation of the value.
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
    /// Generates a string representation of the value.
    public var description: String {
        return "L\(self.level) R\(self.rate)"
    }
}

extension FormantFilter.LFO.Shape: CustomStringConvertible {
    /// Generates a string representation of the value.
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

extension FormantFilter.LFO: CustomStringConvertible {
    /// Gets a string representation of this formant filter LFO.
    public var description: String {
        var s = ""
        s += "Speed: \(self.speed) "
        s += "Shape: \(self.shape) "
        s += "Depth: \(self.depth)"
        return s
    }
}

// MARK: - XML output

extension FormantFilter.LFO {
    public var xml: String {
        return "<lfo speed=\"\(self.speed)\" shape=\"\(self.shape)\" depth=\"\(self.depth)\"/>"
    }
}

extension FormantFilter.Envelope {
    public var xml: String {
"""
<envelope>
    <attack>\(self.attack)</attack>
    <decay1>\(self.decay1)</decay1>
    <decay2>\(self.decay2)</decay2>
    <release>\(self.release)</release>
    \(self.decayLoop.xml)
    <velocity-depth>\(self.velocityDepth)</velocity-depth>
    <key-scaling-depth>\(self.keyScalingDepth)</key-scaling-depth>
</envelope>
"""
    }
}

extension FormantFilter {
    public var xml: String {
"""
<formant-filter bias=\"\(self.bias)\" mode=\"\(self.mode)\" envelope-depth=\"\(self.envelopeDepth)\">
    \(self.lfo.xml)
    \(self.envelope.xml)
</formant-filter>
"""
    }
}
