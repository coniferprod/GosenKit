public struct FormantFilter: Codable {
    public struct Envelope: Codable {
        public struct Segment: Codable {
            public var rate: Int  // 0~127
            public var level: Int // -63(1)~+63(127)
            
            public static let dataLength = 2
            
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
        }

        public var attack: Segment
        public var decay1: Segment
        public var decay2: Segment
        public var release: Segment
        public var decayLoop: EnvelopeLoopKind
        public var velocityDepth: Int // -63(1)~+63(127)
        public var keyScalingDepth: Int // -63(1)~+63(127)
        
        public static let dataLength = 11
        
        public init() {
            attack = Segment(rate: 127, level: 63)
            decay1 = Segment(rate: 127, level: 63)
            decay2 = Segment(rate: 127, level: 63)
            release = Segment(rate: 127, level: 63)
            decayLoop = .off
            velocityDepth = 0
            keyScalingDepth = 0
        }
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0

            let length = Segment.dataLength
            attack = Segment(data: d.slice(from: offset, length: length))
            offset += length

            decay1 = Segment(data: d.slice(from: offset, length: length))
            offset += length

            decay2 = Segment(data: d.slice(from: offset, length: length))
            offset += length

            release = Segment(data: d.slice(from: offset, length: length))
            offset += length

            b = d.next(&offset)
            decayLoop = EnvelopeLoopKind(index: Int(b))!
            
            b = d.next(&offset)
            velocityDepth = Int(b) - 64

            b = d.next(&offset)
            keyScalingDepth = Int(b) - 64
        }
    }
    
    public struct LFO: Codable {
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
        
        public static let dataLength = 3
        
        public init() {
            shape = .triangle
            speed = 0
            depth = 0
        }
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            b = d.next(&offset)
            speed = Int(b)

            b = d.next(&offset)
            shape = Shape(index: Int(b))!
            
            b = d.next(&offset)
            depth = Int(b)
        }
    }

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

    public struct Bands: Codable {
        public var levels: [Int]  // all 0~127

        public static let bandCount = 128
        public static let dataLength = 128

        public init() {
            levels = Array(repeating: 127, count: Bands.bandCount)
        }
           
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            levels = [Int]()
            for _ in 0 ..< Bands.bandCount {
                b = d.next(&offset)
                levels.append(Int(b))
            }
        }
    }
    
    public var bias: Int  // -63(1)~+63(127)
    public var mode: Mode  // 0=ENV, 1=LFO
    public var envelopeDepth: Int // -63(1)~+63(127)
    public var envelope: Envelope
    public var lfo: LFO
    
    public static let dataLength = 17  // does not include the bands!
    
    public init() {
        bias = -10
        mode = .envelope
        envelopeDepth = 0
        envelope = Envelope()
        lfo = LFO()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d.next(&offset)
        bias = Int(b) - 64
        
        b = d.next(&offset)
        mode = Mode(index: Int(b))!
        
        b = d.next(&offset)
        envelopeDepth = Int(b) - 64
        
        envelope = Envelope(data: d.slice(from: offset, length: Envelope.dataLength))
        offset += Envelope.dataLength
        
        lfo = LFO(data: d.slice(from: offset, length: LFO.dataLength))
        offset += LFO.dataLength
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
        
        [decayLoop.index!, velocityDepth + 64, keyScalingDepth + 64].forEach {
            data.append(Byte($0))
        }
        
        return data
    }
}

extension FormantFilter.Envelope.Segment: SystemExclusiveData {
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(rate), Byte(level + 64))
    }
}

extension FormantFilter: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()

        [bias + 64, mode.index!, envelopeDepth + 64].forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: lfo.asData())
        
        return data
    }
}

extension FormantFilter.Bands: SystemExclusiveData {
    public func asData() -> ByteArray {
        return levels.map { Byte($0) }
    }
}

extension FormantFilter.LFO: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [speed, shape.index!, depth].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

// MARK: - CustomStringConvertible

extension FormantFilter.Envelope.Segment: CustomStringConvertible {
    public var description: String {
        return "L\(level) R\(rate)"
    }
}
