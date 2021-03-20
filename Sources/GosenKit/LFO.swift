import Foundation

public enum LFOWaveformType: String, Codable, CaseIterable {
    case triangle
    case square
    case sawtooth
    case sine
    case random
    
    public init?(index: Int) {
        switch index {
        case 0: self = .triangle
        case 1: self = .square
        case 2: self = .sawtooth
        case 3: self = .sine
        case 4: self = .random
        default: return nil
        }
    }
}

public struct LFOControl: Codable {
    public var depth: Int
    public var keyScaling: Int
    
    public init() {
        self.depth = 0
        self.keyScaling = 0
    }
    
    public init(depth: Int, keyScaling: Int) {
        self.depth = depth
        self.keyScaling = keyScaling
    }
    
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(depth), Byte(keyScaling + 64))
    }
}

public struct LFO: Codable {
    public var waveform: LFOWaveformType
    public var speed: Int
    public var fadeInTime: Int
    public var fadeInToSpeed: Int
    public var delayOnset: Int
    
    public var vibrato: LFOControl
    public var growl: LFOControl
    public var tremolo: LFOControl
    
    static let dataLength = 11
    
    public init() {
        waveform = .square
        speed = 0
        fadeInTime = 0
        fadeInToSpeed = 0
        delayOnset = 0
        
        vibrato = LFOControl(depth: 0, keyScaling: 0)
        growl = LFOControl(depth: 0, keyScaling: 0)
        tremolo = LFOControl(depth: 0, keyScaling: 0)
    }
    
    public init(data d: ByteArray) {
        //print("LFO data (\(d.count) bytes): \(d.hexDump)")

        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        waveform = LFOWaveformType(index: Int(b))!
        
        b = d.next(&offset)
        speed = Int(b)
        
        b = d.next(&offset)
        delayOnset = Int(b)

        b = d.next(&offset)
        fadeInTime = Int(b)

        b = d.next(&offset)
        fadeInToSpeed = Int(b)

        b = d.next(&offset)
        let vibratoDepth = Int(b)

        b = d.next(&offset)
        let vibratoKeyScaling = Int(b) - 64

        vibrato = LFOControl(depth: vibratoDepth, keyScaling: vibratoKeyScaling)
        
        b = d.next(&offset)
        let growlDepth = Int(b)

        b = d.next(&offset)
        let growlKeyScaling = Int(b) - 64

        growl = LFOControl(depth: growlDepth, keyScaling: growlKeyScaling)
        
        b = d.next(&offset)
        let tremoloDepth = Int(b)

        b = d.next(&offset)
        let tremoloKeyScaling = Int(b) - 64
        
        tremolo = LFOControl(depth: tremoloDepth, keyScaling: tremoloKeyScaling)
    }
        
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [waveform.index!, speed, delayOnset, fadeInTime, fadeInToSpeed].forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: vibrato.asData())
        data.append(contentsOf: growl.asData())
        data.append(contentsOf: tremolo.asData())

        return data
    }
}
