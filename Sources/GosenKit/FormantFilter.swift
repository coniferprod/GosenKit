import Foundation

struct FormantFilterEnvelope: Codable {
    var attack: EnvelopeSegment
    var decay1: EnvelopeSegment
    var decay2: EnvelopeSegment
    var release: EnvelopeSegment
    var decayLoop: EnvelopeLoopType
    var velocityDepth: Int // -63(1)~+63(127)
    var keyScalingDepth: Int // -63(1)~+63(127)
    
    static let dataLength = 11
    
    init() {
        attack = EnvelopeSegment(rate: 127, level: 63)
        decay1 = EnvelopeSegment(rate: 127, level: 63)
        decay2 = EnvelopeSegment(rate: 127, level: 63)
        release = EnvelopeSegment(rate: 127, level: 63)
        decayLoop = .off
        velocityDepth = 0
        keyScalingDepth = 0
    }
    
    init(data d: ByteArray) {
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

        b = d[offset]
        decayLoop = EnvelopeLoopType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        velocityDepth = Int(b) - 64
        offset += 1

        b = d[offset]
        keyScalingDepth = Int(b) - 64
        offset += 1
    }
    
    func asData() -> ByteArray {
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

enum FormantFilterLFOShape: String, Codable, CaseIterable {
    case triangle
    case sawtooth
    case random
    
    init?(index: Int) {
        switch index {
        case 0: self = .triangle
        case 1: self = .sawtooth
        case 2: self = .random
        default: return nil
        }
    }
}

struct FormantFilterLFO: Codable {
    var speed: Int  // 0~127
    var shape: FormantFilterLFOShape
    var depth: Int  // 0~63
    
    static let dataLength = 3
    
    init() {
        shape = .triangle
        speed = 0
        depth = 0
    }
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        speed = Int(b)
        offset += 1

        b = d[offset]
        shape = FormantFilterLFOShape(index: Int(b))!
        offset += 1
        
        b = d[offset]
        depth = Int(b)
        offset += 1
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(speed))
        data.append(Byte(shape.index!))
        data.append(Byte(depth))
    
        return data
    }
}

enum FormantFilterMode: String, Codable, CaseIterable {
    case envelope
    case lfo
    
    init?(index: Int) {
        switch index {
        case 0: self = .envelope
        case 1: self = .lfo
        default: return nil
        }
    }
}

struct FormantFilterBands: Codable {
    var levels: [Int]  // all 0~127

    static let bandCount = 128
    static let dataLength = 128

    init() {
        levels = [Int]()
        for _ in 0..<FormantFilterBands.bandCount {
            levels.append(127)
        }
    }
       
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        levels = [Int]()
        for _ in 0..<FormantFilterBands.bandCount {
            b = d[offset]
            levels.append(Int(b))
            offset += 1
        }
    }
        
    func asData() -> ByteArray {
        var data = ByteArray()
    
        for (_, element) in levels.enumerated() {
            data.append(Byte(element))
        }
            
        return data
    }
}

struct FormantFilterSettings: Codable {
    var bands: FormantFilterBands
    var bias: Int  // -63(1)~+63(127)
    var mode: FormantFilterMode  // 0=ENV, 1=LFO
    var envelopeDepth: Int // -63(1)~+63(127)
    var envelope: FormantFilterEnvelope
    var lfo: FormantFilterLFO
    
    static let dataLength = 17  // does not include the bands!
    
    init() {
        bands = FormantFilterBands()
        bias = -10
        mode = .envelope
        envelopeDepth = 0
        envelope = FormantFilterEnvelope()
        lfo = FormantFilterLFO()
    }
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        // the bands are not here!
        
        b = d[offset]
        bias = Int(b) - 64
        offset += 1
        
        b = d[offset]
        mode = FormantFilterMode(index: Int(b))!
        offset += 1
        
        b = d[offset]
        envelopeDepth = Int(b) - 64
        offset += 1
        
        envelope = FormantFilterEnvelope(data: ByteArray(d[offset ..< offset + FormantFilterEnvelope.dataLength]))
        offset += FormantFilterEnvelope.dataLength
        
        lfo = FormantFilterLFO(data: ByteArray(d[offset ..< offset + FormantFilterLFO.dataLength]))
        offset += FormantFilterLFO.dataLength

        // These will be rewritten when they are parsed from SysEx later on
        bands = FormantFilterBands()
    }
    
    func asData() -> ByteArray {
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
