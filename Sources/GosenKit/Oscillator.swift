import SyxPack

/// Represents an oscillator in a source of a single patch.
public struct Oscillator {
    /// Pitch envelope of an oscillator.
    public struct PitchEnvelope {
        public struct Level {
            private var _value: Int
        }
        
        public struct Time {
            private var _value: Int
        }
        
        public var start: Level
        public var attackTime: Time
        public var attackLevel: Level
        public var decayTime: Time
        public var timeVelocitySensitivity: Depth
        public var levelVelocitySensitivity: Depth
        
        /// Initializes a default pitch envelope.
        public init() {
            start = Level(0)
            attackTime = Time(0)
            attackLevel = Level(127)
            decayTime = Time(0)
            timeVelocitySensitivity = Depth(0)
            levelVelocitySensitivity = Depth(0)
        }
        
        public static func parse(from data: ByteArray) -> Result<PitchEnvelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = PitchEnvelope()
            
            b = data.next(&offset)
            temp.start = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.attackTime = Time(Int(b))
            
            b = data.next(&offset)
            temp.attackLevel = Depth(Int(b) - 64)
            
            b = data.next(&offset)
            temp.decayTime = Time(Int(b))
            
            b = data.next(&offset)
            temp.timeVelocitySensitivity = Depth(Int(b) - 64)
            
            b = data.next(&offset)
            temp.levelVelocitySensitivity = Depth(Int(b) - 64)

            return .success(temp)
        }
    }

    /// Key scaling setting for an oscillator.
    public enum KeyScaling: String, Codable, CaseIterable {
        case zeroCent
        case twentyFiveCent
        case thirtyTreeCent
        case fiftyCent
        
        /// Initializes a key scaling setting from a data byte.
        public init?(index: Int) {
            switch index {
            case 0: self = .zeroCent
            case 1: self = .twentyFiveCent
            case 2: self = .thirtyTreeCent
            case 3: self = .fiftyCent
            default: return nil
            }
        }
    }

    public var wave: Wave
    public var coarse: Int
    public var fine: Int
    public var keyScalingToPitch: KeyScaling
    public var fixedKey: Int  // TODO: OFF / MIDI note
    public var pitchEnvelope: PitchEnvelope
    
    /// Initializes an oscillator with default settings.
    public init() {
        wave = Wave(number: 411)
        coarse = 0
        fine = 0
        keyScalingToPitch = .zeroCent
        fixedKey = 0
        pitchEnvelope = PitchEnvelope()
    }
    
    public static func parse(from data: ByteArray) -> Result<Oscillator, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = Oscillator()
        
        b = data.next(&offset)
        let waveMSB = b
        b = data.next(&offset)
        let waveLSB = b
        temp.wave = Wave(msb: waveMSB, lsb: waveLSB)
        
        b = data.next(&offset)
        temp.coarse = Int(b) - 24

        b = data.next(&offset)
        temp.fine = Int(b) - 64

        b = data.next(&offset)
        temp.fixedKey = Int(b)

        b = data.next(&offset)
        temp.keyScalingToPitch = KeyScaling(index: Int(b))!

        switch PitchEnvelope.parse(from: data.slice(from: offset, length: PitchEnvelope.dataSize)) {
        case .success(let env):
            temp.pitchEnvelope = env
        case .failure(let error):
            return .failure(error)
        }

        return .success(temp)
    }
}

extension Oscillator.PitchEnvelope.Level: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Oscillator.PitchEnvelope.Time: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

// MARK: - SystemExclusiveData

extension Oscillator.PitchEnvelope: SystemExclusiveData {
    /// Gets the MIDI System Excusive data bytes for the pitch envelope.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            start + 64,
            attackTime,
            attackLevel + 64,
            decayTime,
            timeVelocitySensitivity + 64,
            levelVelocitySensitivity + 64
        ]
        .forEach {
            data.append(Byte($0))
        }

        return data
    }
    
    /// The number of data bytes for the pitch envelope.
    public var dataLength: Int { return Oscillator.PitchEnvelope.dataSize }
    
    public static let dataSize = 6
}

extension Oscillator: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for the oscillator.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: wave.asData())
        
        [
            coarse + 24,
            fine + 64,
            fixedKey,
            keyScalingToPitch.index
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        data.append(contentsOf: pitchEnvelope.asData())
        
        return data
    }
    
    /// The number of data bytes for the oscillator.
    public var dataLength: Int { return Oscillator.dataSize }
    
    public static let dataSize = 12
}

// MARK: - CustomStringConvertible

extension Oscillator: CustomStringConvertible {
    /// Gets a text representation of the oscillator.
    public var description: String {
        var s = "Wave: '\(wave)' "
        s += "Coarse=\(coarse) Fine=\(fine) KStoPitch=\(keyScalingToPitch.rawValue) FixedKey=\(fixedKey)\n"
        s += "Pitch Envelope = \(pitchEnvelope)\n"
        return s
    }
}

extension Oscillator.PitchEnvelope: CustomStringConvertible {
    /// Gets a text representation of the pitch envelope.
    public var description: String {
        var s = ""
        s += "start=\(start), attackTime=\(attackTime), attackLevel=\(attackLevel), decayTime=\(decayTime)\n"
        s += "timeVelSens=\(timeVelocitySensitivity) levelVelSens=\(levelVelocitySensitivity)\n"
        return s
    }
}

extension Oscillator.KeyScaling: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .zeroCent:
            result = "0cent"
        case .twentyFiveCent:
            result = "25cent"
        case .thirtyTreeCent:
            result = "33cent"
        case .fiftyCent:
            result = "50cent"
        }
        return result
    }
}
