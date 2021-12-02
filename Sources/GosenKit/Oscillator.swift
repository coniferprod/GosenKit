public struct Oscillator: Codable {
    public struct PitchEnvelope: Codable {
        public var start: Int
        public var attackTime: Int
        public var attackLevel: Int
        public var decayTime: Int
        public var timeVelocitySensitivity: Int
        public var levelVelocitySensitivity: Int
        
        public static let dataLength = 6
        
        public init() {
            start = 0
            attackTime = 0
            attackLevel = 127
            decayTime = 0
            timeVelocitySensitivity = 0
            levelVelocitySensitivity = 0
        }
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            b = d.next(&offset)
            start = Int(b) - 64
            
            b = d.next(&offset)
            attackTime = Int(b)
            
            b = d.next(&offset)
            attackLevel = Int(b) - 64
            
            b = d.next(&offset)
            decayTime = Int(b)
            
            b = d.next(&offset)
            timeVelocitySensitivity = Int(b) - 64
            
            b = d.next(&offset)
            levelVelocitySensitivity = Int(b) - 64
        }
    }

    public enum KeyScaling: String, Codable, CaseIterable {
        case zeroCent
        case twentyFiveCent
        case thirtyTreeCent
        case fiftyCent
        
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
    
    public static let dataLength = 12
    
    public init() {
        wave = Wave(number: 411)
        coarse = 0
        fine = 0
        keyScalingToPitch = .zeroCent
        fixedKey = 0
        pitchEnvelope = PitchEnvelope()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        let waveMSB = b
        b = d.next(&offset)
        let waveLSB = b
        wave = Wave(msb: waveMSB, lsb: waveLSB)
        
        b = d.next(&offset)
        coarse = Int(b) - 24

        b = d.next(&offset)
        fine = Int(b) - 64

        b = d.next(&offset)
        fixedKey = Int(b)

        b = d.next(&offset)
        keyScalingToPitch = KeyScaling(index: Int(b))!

        pitchEnvelope = PitchEnvelope(data: d.slice(from: offset, length: PitchEnvelope.dataLength))
    }
}

// MARK: - CustomStringConvertible

extension Oscillator: CustomStringConvertible {
    public var description: String {
        var s = "Wave: \(wave) "
        s += "Coarse=\(coarse) Fine=\(fine) KStoPitch=\(keyScalingToPitch.rawValue) FixedKey=\(fixedKey)\n"
        s += "Pitch Envelope:\n\(pitchEnvelope)\n"
        return s
    }
}

extension Oscillator.PitchEnvelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "start=\(start), attackTime=\(attackTime), attackLevel=\(attackLevel), decayTime=\(decayTime)\n"
        s += "timeVelSens=\(timeVelocitySensitivity) levelVelSens=\(levelVelocitySensitivity)\n"
        return s
    }
}

// MARK: - SystemExclusiveData

extension Oscillator.PitchEnvelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [start + 64, attackTime, attackLevel + 64, decayTime,
         timeVelocitySensitivity + 64, levelVelocitySensitivity + 64].forEach {
            data.append(Byte($0))
        }

        return data
    }
}

extension Oscillator: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: wave.asData())
        
        [coarse + 24, fine + 64, fixedKey, keyScalingToPitch.index!].forEach {
            data.append(Byte($0))
        }
        
        data.append(contentsOf: pitchEnvelope.asData())
        
        return data
    }
}
