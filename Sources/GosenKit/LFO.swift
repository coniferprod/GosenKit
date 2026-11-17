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
        public var depth: Int  // -63...63
        public var keyScaling: Int  // -63...63
        
        /// Initialize the LFO control settings with default values.
        public init() {
            self.depth = 0
            self.keyScaling = 0
        }
        
        /// Initialize the LFO control settings from given values.
        public init(depth: Int, keyScaling: Int) {
            self.depth = depth
            self.keyScaling = keyScaling
        }
        
        /// Parse the LFO control settings from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Control, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            let descriptor = descriptors[.depth]!

            var temp = Control()
            
            b = data.next(&offset)
            temp.depth = Int(b) + descriptor.incomingOffset

            b = data.next(&offset)
            temp.keyScaling = Int(b) + descriptor.incomingOffset

            return .success(temp)
        }
    }
    
    public var waveform: Waveform
    public var speed: Int   // 0...127
    public var fadeInTime: Int  // 0...127
    public var fadeInToSpeed: Int  // -63...63
    public var delayOnset: Int  // 0...127
    
    public var vibrato: Control
    public var growl: Control
    public var tremolo: Control

    /// Initialize the LFO with default values.
    public init() {
        self.waveform = .square
        self.speed = 0
        self.fadeInTime = 0
        self.fadeInToSpeed = 0
        self.delayOnset = 0
        
        // Initialize controls with default values
        self.vibrato = Control()
        self.growl = Control()
        self.tremolo = Control()
    }
    
    /// Parse the LFO from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<LFO, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = LFO()
        
        b = data.next(&offset)
        temp.waveform = Waveform(index: Int(b))!
        
        b = data.next(&offset)
        temp.speed = Int(b)
        
        b = data.next(&offset)
        temp.delayOnset = Int(b)

        b = data.next(&offset)
        temp.fadeInTime = Int(b)

        b = data.next(&offset)
        let descriptor = descriptors[.depth]!
        temp.fadeInToSpeed = Int(b) + descriptor.incomingOffset

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
        let descriptor = descriptors[.depth]!

        var data = ByteArray()
        
        [
            self.waveform.index,
            self.speed,
            self.delayOnset,
            self.fadeInTime,
            self.fadeInToSpeed + descriptor.outgoingOffset
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        [
            self.vibrato,
            self.growl,
            self.tremolo
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
        return ByteArray(arrayLiteral: Byte(self.depth), Byte(self.keyScaling + descriptors[.keyScalingControl]!.outgoingOffset))
    }

    public var dataLength: Int { LFO.Control.dataSize }

    public static let dataSize = 2
}

// MARK: - CustomStringConvertible protocol conformance

extension LFO: CustomStringConvertible {
    public var description: String {
        var result = ""
        result += "Waveform=\(self.waveform) Speed=\(self.speed) FadeInTime=\(self.fadeInTime) FadeInToSpeed=\(self.fadeInToSpeed) DelayOnset=\(self.delayOnset)\n"
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
        result += "Depth=\(self.depth) KeyScaling=\(self.keyScaling)"
        return result
    }
}
