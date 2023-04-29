import SyxPack

public struct LFO: Codable {
    public enum Waveform: String, Codable, CaseIterable {
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

    public struct Control: Codable {
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
    }

    public var waveform: Waveform
    public var speed: Int
    public var fadeInTime: Int
    public var fadeInToSpeed: Int
    public var delayOnset: Int
    
    public var vibrato: Control
    public var growl: Control
    public var tremolo: Control
    
    public init() {
        waveform = .square
        speed = 0
        fadeInTime = 0
        fadeInToSpeed = 0
        delayOnset = 0
        
        vibrato = Control(depth: 0, keyScaling: 0)
        growl = Control(depth: 0, keyScaling: 0)
        tremolo = Control(depth: 0, keyScaling: 0)
    }
    
    public init(data d: ByteArray) {
        //print("LFO data (\(d.count) bytes): \(d.hexDump)")

        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        waveform = Waveform(index: Int(b))!
        
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

        vibrato = Control(depth: vibratoDepth, keyScaling: vibratoKeyScaling)
        
        b = d.next(&offset)
        let growlDepth = Int(b)

        b = d.next(&offset)
        let growlKeyScaling = Int(b) - 64

        growl = Control(depth: growlDepth, keyScaling: growlKeyScaling)
        
        b = d.next(&offset)
        let tremoloDepth = Int(b)

        b = d.next(&offset)
        let tremoloKeyScaling = Int(b) - 64
        
        tremolo = Control(depth: tremoloDepth, keyScaling: tremoloKeyScaling)
    }
}

// MARK: - SystemExclusiveData

extension LFO: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [waveform.index, speed, delayOnset, fadeInTime, fadeInToSpeed].forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: vibrato.asData())
        data.append(contentsOf: growl.asData())
        data.append(contentsOf: tremolo.asData())

        return data
    }
    
    public var dataLength: Int { return LFO.dataSize }
    
    public static let dataSize = 11
}

extension LFO.Control: SystemExclusiveData {
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(depth), Byte(keyScaling + 64))
    }

    public var dataLength: Int { return LFO.Control.dataSize }

    public static let dataSize = 2
}
