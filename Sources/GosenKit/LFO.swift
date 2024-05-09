import SyxPack
import ByteKit

/// LFO (Low Frequency Oscillator) settings.
public struct LFO {
    /// LFO waveform.
    public enum Waveform: Int, CaseIterable {
        case triangle
        case square
        case sawtooth
        case sine
        case random
        
        /// Initialize the LFO waveform from an integer.
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

    /// LFO control settings.
    public struct Control {
        public var depth: Depth
        public var keyScaling: Depth
        
        /// Initialize the LFO control settings with default values.
        public init() {
            self.depth = 0
            self.keyScaling = 0
        }
        
        /// Initialize the LFO control settings from given values.
        public init(depth: Depth, keyScaling: Depth) {
            self.depth = depth
            self.keyScaling = keyScaling
        }
        
        /// Parse the LFO control settings from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Control, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Control()
            
            b = data.next(&offset)
            temp.depth = Depth(Int(b))

            b = data.next(&offset)
            temp.keyScaling = Depth(Int(b) - 64)

            return .success(temp)
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

    /// Initialize the LFO with default values.
    public init() {
        waveform = .square
        speed = 0
        fadeInTime = 0
        fadeInToSpeed = 0
        delayOnset = 0
        
        // Initialize controls with default values
        vibrato = Control()
        growl = Control()
        tremolo = Control()
    }
    
    /// Parse the LFO from MIDI System Exclusive data.
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

        let size = Control.dataSize
        switch Control.parse(from: data.slice(from: offset, length: size)) {
        case .success(let vibrato):
            temp.vibrato = vibrato
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        switch Control.parse(from: data.slice(from: offset, length: size)) {
        case .success(let growl):
            temp.growl = growl
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        switch Control.parse(from: data.slice(from: offset, length: size)) {
        case .success(let tremolo):
            temp.tremolo = tremolo
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        return .success(temp)
    }
}

// MARK: - SystemExclusiveData protocol conformance

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
        
        [
            vibrato,
            growl,
            tremolo
        ]
        .forEach {
            data.append(contentsOf: $0.asData())
        }

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

// MARK: - CustomStringConvertible protocol conformance

extension LFO: CustomStringConvertible {
    public var description: String {
        var result = ""
        result += "Waveform=\(self.waveform) Speed=\(self.speed.value) FadeInTime=\(self.fadeInTime.value) FadeInToSpeed=\(self.fadeInToSpeed.value) DelayOnset=\(self.delayOnset.value)\n"
        result += "Vibrato: \(self.vibrato)\nGrowl: \(self.growl)\nTremolo: \(self.tremolo)"
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
        result += "Depth=\(self.depth.value) KeyScaling=\(self.keyScaling.value)"
        return result
    }
}
