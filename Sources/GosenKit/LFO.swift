import SyxPack
import ByteKit

public enum DepthDomain: IntegerDomain {
    public static let first = -63
    public static let last = 63
    public static let defaultValue = 0
}

extension DepthDomain: SystemExclusiveEncoding {
    public static func decode(
        from bytes: ArraySlice<UInt8>
    ) -> Integer<DepthDomain>? {
        return Integer<DepthDomain>(Int(bytes.first) - 63)
    }
    
    public static func encode(
        _ value: Integer<DepthDomain>
    ) -> ByteArray {
        [UInt8(value.value + 63)]
    }
}

public typealias Depth = Integer<DepthDomain>

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
        public var depth: Depth  // -63...63
        public var keyScaling: Depth  // -63...63
        
        /// Initialize the LFO control settings with default values.
        public init() {
            self.depth = 0
            self.keyScaling = 0
        }
        
        /// Initialize the LFO control settings from given values.
        public init(depth: Int, keyScaling: Int) {
            self.depth = Depth(depth)
            self.keyScaling = Depth(keyScaling)
        }
        
        /// Parse the LFO control settings from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Control, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            //var descriptor = descriptors[.depth]!

            var temp = Control()
            
            b = data.next(&offset)
            temp.depth = DepthDomain.decode(Int(b))

            b = data.next(&offset)
            temp.keyScaling = DepthDomain.decode(Int(b))

            return .success(temp)
        }
    }
    
    public var waveform: Waveform
    public var speed: Level   // 0...127
    public var fadeInTime: Level  // 0...127
    public var fadeInToSpeed: SignedLevel  // -63...63
    public var delayOnset: Level  // 0...127
    
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
            waveform.index,
            speed,
            delayOnset,
            fadeInTime,
            fadeInToSpeed + descriptor.outgoingOffset
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
        return ByteArray(arrayLiteral: Byte(depth), Byte(keyScaling + descriptors[.keyScalingControl]!.outgoingOffset))
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
