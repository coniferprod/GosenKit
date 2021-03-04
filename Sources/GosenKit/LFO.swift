import Foundation

enum LFOWaveformType: String, Codable, CaseIterable {
    case triangle
    case square
    case sawtooth
    case sine
    case random
    
    init?(index: Int) {
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

struct LFOControl: Codable {
    var depth: Int
    var keyScaling: Int
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(depth))
        data.append(Byte(keyScaling + 64))

        return data
    }
}

struct LFO: Codable {
    var waveform: LFOWaveformType
    var speed: Int
    var fadeInTime: Int
    var fadeInToSpeed: Int
    var delayOnset: Int
    
    var vibrato: LFOControl
    var growl: LFOControl
    var tremolo: LFOControl
    
    static let dataLength = 11
    
    init() {
        waveform = .square
        speed = 0
        fadeInTime = 0
        fadeInToSpeed = 0
        delayOnset = 0
        
        vibrato = LFOControl(depth: 0, keyScaling: 0)
        growl = LFOControl(depth: 0, keyScaling: 0)
        tremolo = LFOControl(depth: 0, keyScaling: 0)
    }
    
    init(data d: ByteArray) {
        //print("LFO data (\(d.count) bytes): \(d.hexDump)")

        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        waveform = LFOWaveformType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        speed = Int(b)
        offset += 1
        
        b = d[offset]
        delayOnset = Int(b)
        offset += 1

        b = d[offset]
        fadeInTime = Int(b)
        offset += 1

        b = d[offset]
        fadeInToSpeed = Int(b)
        offset += 1

        b = d[offset]
        let vibratoDepth = Int(b)
        offset += 1

        b = d[offset]
        let vibratoKeyScaling = Int(b) - 64
        offset += 1

        vibrato = LFOControl(depth: vibratoDepth, keyScaling: vibratoKeyScaling)
        
        b = d[offset]
        let growlDepth = Int(b)
        offset += 1

        b = d[offset]
        let growlKeyScaling = Int(b) - 64
        offset += 1

        growl = LFOControl(depth: growlDepth, keyScaling: growlKeyScaling)
        
        b = d[offset]
        let tremoloDepth = Int(b)
        offset += 1

        b = d[offset]
        let tremoloKeyScaling = Int(b) - 64
        offset += 1
        
        tremolo = LFOControl(depth: tremoloDepth, keyScaling: tremoloKeyScaling)
    }
        
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(waveform.index!))
        data.append(Byte(speed))
        data.append(Byte(delayOnset))
        data.append(Byte(fadeInTime))
        data.append(Byte(fadeInToSpeed))

        data.append(contentsOf: vibrato.asData())
        data.append(contentsOf: growl.asData())
        data.append(contentsOf: tremolo.asData())

        return data
    }
}
