import SyxPack

public struct LFO {
    public enum Waveform: Int, CaseIterable {
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

    public struct Control {
        public var depth: Depth
        public var keyScaling: Depth
        
        public init() {
            self.depth = Depth(0)
            self.keyScaling = Depth(0)
        }
        
        public init(depth: Depth, keyScaling: Depth) {
            self.depth = depth
            self.keyScaling = keyScaling
        }
    }
    
    public var waveform: Waveform
    public var speed: Level
    public var fadeInTime: Level
    public var fadeInToSpeed: Depth
    public var delayOnset: Level
    
    public var vibrato: Control
    public var growl: Control
    public var tremolo: Control
    
    public init() {
        waveform = .square
        speed = Level(0)
        fadeInTime = Level(0)
        fadeInToSpeed = Depth(0)
        delayOnset = Level(0)
        
        vibrato = Control(depth: Depth(0), keyScaling: Depth(0))
        growl = Control(depth: Depth(0), keyScaling: Depth(0))
        tremolo = Control(depth: Depth(0), keyScaling: Depth(0))
    }
    
    public static func parse(from data: ByteArray) -> Result<LFO, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = LFO()
        
        b = data.next(&offset)
        temp.waveform = Waveform(index: Int(b))!
        
        b = data.next(&offset)
        temp.speed = Level(Int(b))
        
        b = data.next(&offset)
        temp.delayOnset = Level(Int(b))

        b = data.next(&offset)
        temp.fadeInTime = Level(Int(b))

        b = data.next(&offset)
        temp.fadeInToSpeed = Depth(Int(b))

        b = data.next(&offset)
        let vibratoDepth = Depth(Int(b))

        b = data.next(&offset)
        let vibratoKeyScaling = Depth(Int(b) - 64)

        temp.vibrato = Control(depth: vibratoDepth, keyScaling: vibratoKeyScaling)
        
        b = data.next(&offset)
        let growlDepth = Depth(Int(b))

        b = data.next(&offset)
        let growlKeyScaling = Depth(Int(b) - 64)

        temp.growl = Control(depth: growlDepth, keyScaling: growlKeyScaling)
        
        b = data.next(&offset)
        let tremoloDepth = Depth(Int(b))

        b = data.next(&offset)
        let tremoloKeyScaling = Depth(Int(b) - 64)
        
        temp.tremolo = Control(depth: tremoloDepth, keyScaling: tremoloKeyScaling)

        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension LFO: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            waveform.index,
            speed.value,
            delayOnset.value,
            fadeInTime.value,
            fadeInToSpeed.value
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: vibrato.asData())
        data.append(contentsOf: growl.asData())
        data.append(contentsOf: tremolo.asData())

        return data
    }
    
    public var dataLength: Int { LFO.dataSize }
    
    public static let dataSize = 11
}

extension LFO.Control: SystemExclusiveData {
    public func asData() -> ByteArray {
        return ByteArray(arrayLiteral: Byte(depth.value), Byte(keyScaling.value + 64))
    }

    public var dataLength: Int { LFO.Control.dataSize }

    public static let dataSize = 2
}

// MARK: - CustomStringConvertible

extension LFO: CustomStringConvertible {
    public var description: String {
        var result = ""
        result += "Waveform=\(self.waveform) Speed=\(self.speed) FadeInTime=\(self.fadeInTime) FadeInToSpeed=\(self.fadeInToSpeed) DelayOnset=\(self.delayOnset)\n"
        result += "Vibrato: \(self.vibrato) Growl: \(self.growl) Tremolo: \(self.tremolo)"
        return result
    }
}

extension LFO.Waveform: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .triangle:
            result = "TRI"
        case .square:
            result = "SQR"
        case .sawtooth:
            result = "SAW"
        case .sine:
            result = "SIN"
        case .random:
            result = "RND"
        }
        return result
    }
}

extension LFO.Control: CustomStringConvertible {
    public var description: String {
        var result = ""
        result += "Depth=\(self.depth) KeyScaling=\(self.keyScaling)"
        return result
    }
}
