import SyxPack

/// Represents an oscillator in a source of a single patch.
public struct Oscillator {
    /// Pitch envelope of an oscillator.
    public struct PitchEnvelope {
        // Pitch envelope time 0~127
        public struct Time {
            private var _value: Int
        }
        
        /// Pitch envelope level -63~+63
        public struct Level {
            private var _value: Int
        }

        public var start: Level
        public var attackTime: Time
        public var attackLevel: Level
        public var decayTime: Time
        public var timeVelocitySensitivity: Level
        public var levelVelocitySensitivity: Level
        
        /// Initializes a default pitch envelope.
        public init() {
            start = Level(0)
            attackTime = Time(0)
            attackLevel = Level(127)
            decayTime = Time(0)
            timeVelocitySensitivity = Level(0)
            levelVelocitySensitivity = Level(0)
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
            temp.attackLevel = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.decayTime = Time(Int(b))
            
            b = data.next(&offset)
            temp.timeVelocitySensitivity = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.levelVelocitySensitivity = Level(Int(b) - 64)

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
    public var coarse: Coarse
    public var fine: Fine
    public var keyScalingToPitch: KeyScaling
    public var fixedKey: FixedKey
    public var pitchEnvelope: PitchEnvelope
    
    /// Initializes an oscillator with default settings.
    public init() {
        wave = .pcm(411)
        coarse = Coarse(0)
        fine = Fine(0)
        keyScalingToPitch = .zeroCent
        fixedKey = .off
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
        
        switch Wave.parse(msb: waveMSB, lsb: waveLSB) {
        case .success(let wave):
            temp.wave = wave
        case .failure(let error):
            return .failure(error)
        }
        
        b = data.next(&offset)
        temp.coarse = Coarse(Int(b) - 24)

        b = data.next(&offset)
        temp.fine = Fine(Int(b) - 64)

        b = data.next(&offset)
        if b == 0 {
            temp.fixedKey = .off
        }
        else {
            // MIDI spec says: 21 ~ 108 = ON(A-1 ~ C7).
            // With Middle C defined as C4, A0=21 and C8=108.
            // So it seems like the K5000 wants to use the Yamaha convention,
            // where Middle C is C3, so that A-1=21 and C7=108.
            temp.fixedKey = .on(Key(note: MIDINote(Int(b))))
        }

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

// MARK: - SystemExclusiveData

extension Oscillator.PitchEnvelope: SystemExclusiveData {
    /// Gets the MIDI System Excusive data bytes for the pitch envelope.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            start.value + 64,
            attackTime.value,
            attackLevel.value + 64,
            decayTime.value,
            timeVelocitySensitivity.value + 64,
            levelVelocitySensitivity.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }

        return data
    }
    
    /// The number of data bytes for the pitch envelope.
    public var dataLength: Int { Oscillator.PitchEnvelope.dataSize }
    
    public static let dataSize = 6
}

extension Oscillator: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data bytes for the oscillator.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: wave.asData())
        
        var fixedKeyByte = 0x00
        if case .on(let key) = fixedKey {
            fixedKeyByte = key.note.value
        }
        
        [
            coarse.value + 24,
            fine.value + 64,
            fixedKeyByte,
            keyScalingToPitch.index
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        data.append(contentsOf: pitchEnvelope.asData())
        
        return data
    }
    
    /// The number of data bytes for the oscillator.
    public var dataLength: Int { Oscillator.dataSize }
    
    public static let dataSize = 12
}

// MARK: - CustomStringConvertible

extension Oscillator: CustomStringConvertible {
    /// Gets a text representation of the oscillator.
    public var description: String {
        var s = "Wave: '\(wave)' "
        s += "Coarse=\(coarse.value) Fine=\(fine.value) KStoPitch=\(keyScalingToPitch.rawValue) FixedKey=\(fixedKey)\n"
        s += "Pitch Envelope = \(pitchEnvelope)"
        return s
    }
}

extension Oscillator.PitchEnvelope: CustomStringConvertible {
    /// Gets a text representation of the pitch envelope.
    public var description: String {
        var s = ""
        s += "start=\(start.value), attackTime=\(attackTime.value), attackLevel=\(attackLevel.value), decayTime=\(decayTime.value)\n"
        s += "timeVelSens=\(timeVelocitySensitivity.value) levelVelSens=\(levelVelocitySensitivity.value)\n"
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

extension Oscillator.PitchEnvelope.Time: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Oscillator.PitchEnvelope.Level: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}
