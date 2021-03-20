import Foundation

public struct FormantFilterEnvelope: Codable {
    public var attack: EnvelopeSegment
    public var decay1: EnvelopeSegment
    public var decay2: EnvelopeSegment
    public var release: EnvelopeSegment
    public var decayLoop: EnvelopeLoopType
    public var velocityDepth: Int // -63(1)~+63(127)
    public var keyScalingDepth: Int // -63(1)~+63(127)
    
    static let dataLength = 11
    
    public init() {
        attack = EnvelopeSegment(rate: 127, level: 63)
        decay1 = EnvelopeSegment(rate: 127, level: 63)
        decay2 = EnvelopeSegment(rate: 127, level: 63)
        release = EnvelopeSegment(rate: 127, level: 63)
        decayLoop = .off
        velocityDepth = 0
        keyScalingDepth = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0

        attack = EnvelopeSegment(data: ByteArray(d[offset ..< offset + EnvelopeSegment.dataLength]))
        offset += EnvelopeSegment.dataLength

        decay1 = EnvelopeSegment(data: ByteArray(d[offset ..< offset + EnvelopeSegment.dataLength]))
        offset += EnvelopeSegment.dataLength

        decay2 = EnvelopeSegment(data: ByteArray(d[offset ..< offset + EnvelopeSegment.dataLength]))
        offset += EnvelopeSegment.dataLength

        release = EnvelopeSegment(data: ByteArray(d[offset ..< offset + EnvelopeSegment.dataLength]))
        offset += EnvelopeSegment.dataLength

        b = d.next(&offset)
        decayLoop = EnvelopeLoopType(index: Int(b))!
        
        b = d.next(&offset)
        velocityDepth = Int(b) - 64

        b = d.next(&offset)
        keyScalingDepth = Int(b) - 64
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: attack.asData())
        data.append(contentsOf: decay1.asData())
        data.append(contentsOf: decay2.asData())
        data.append(contentsOf: release.asData())
        data.append(Byte(decayLoop.index!))

        data.append(Byte(velocityDepth + 64))
        data.append(Byte(keyScalingDepth + 64))
        
        return data
    }
}

public enum FormantFilterLFOShape: String, Codable, CaseIterable {
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

public struct FormantFilterLFO: Codable {
    public var speed: Int  // 0~127
    public var shape: FormantFilterLFOShape
    public var depth: Int  // 0~63
    
    static let dataLength = 3
    
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
        shape = FormantFilterLFOShape(index: Int(b))!
        
        b = d.next(&offset)
        depth = Int(b)
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(speed))
        data.append(Byte(shape.index!))
        data.append(Byte(depth))
    
        return data
    }
}

public enum FormantFilterMode: String, Codable, CaseIterable {
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

public struct FormantFilterBands: Codable {
    public var levels: [Int]  // all 0~127

    public static let bandCount = 128
    public static let dataLength = 128

    public init() {
        levels = [Int]()
        for _ in 0..<FormantFilterBands.bandCount {
            levels.append(127)
        }
    }
       
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        levels = [Int]()
        for _ in 0..<FormantFilterBands.bandCount {
            b = d.next(&offset)
            levels.append(Int(b))
        }
    }
        
    public func asData() -> ByteArray {
        var data = ByteArray()
    
        for (_, element) in levels.enumerated() {
            data.append(Byte(element))
        }
            
        return data
    }
}

public struct FormantFilterSettings: Codable {
    public var bands: FormantFilterBands
    public var bias: Int  // -63(1)~+63(127)
    public var mode: FormantFilterMode  // 0=ENV, 1=LFO
    public var envelopeDepth: Int // -63(1)~+63(127)
    public var envelope: FormantFilterEnvelope
    public var lfo: FormantFilterLFO
    
    static let dataLength = 17  // does not include the bands!
    
    public init() {
        bands = FormantFilterBands()
        bias = -10
        mode = .envelope
        envelopeDepth = 0
        envelope = FormantFilterEnvelope()
        lfo = FormantFilterLFO()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        // the bands are not here!
        
        b = d.next(&offset)
        bias = Int(b) - 64
        
        b = d.next(&offset)
        mode = FormantFilterMode(index: Int(b))!
        
        b = d.next(&offset)
        envelopeDepth = Int(b) - 64
        
        envelope = FormantFilterEnvelope(data: ByteArray(d[offset ..< offset + FormantFilterEnvelope.dataLength]))
        offset += FormantFilterEnvelope.dataLength
        
        lfo = FormantFilterLFO(data: ByteArray(d[offset ..< offset + FormantFilterLFO.dataLength]))
        offset += FormantFilterLFO.dataLength

        // These will be rewritten when they are parsed from SysEx later on
        bands = FormantFilterBands()
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
     
        data.append(Byte(bias + 64))
        data.append(Byte(mode.index!))
        data.append(Byte(envelopeDepth + 64))
        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: lfo.asData())
        
        // The formant filter band levels are emitted separately,
        // after the harmonic levels.
        
        return data
    }
}
