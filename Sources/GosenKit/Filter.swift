import SyxPack
import ByteKit

/// Filter (DCF).
public struct Filter {
    /// Filter mode.
    public enum Mode: Int, CaseIterable {
        case lowPass
        case highPass
        
        /// Initializes filter mode from SysEx byte.
        public init?(index: Int) {
            switch index {
            case 0: self = .lowPass
            case 1: self = .highPass
            default: return nil
            }
        }
    }

    /// Filter envelope.
    public struct Envelope {
        /// Filter envelope time (for attack, decay 1, decay 2, and release) (0...127)
        public struct Time: RangedInt {
            public var value: Int
            public static let range: ClosedRange<Int> = 0...127
            public static let defaultValue = 0

            public init(_ value: Int) {
                self.value = Self.range.clamp(value)
            }
        }

        /// Filter envelope level (for decay 1, decay 2, etc.) (-63...63)
        public struct Level: RangedInt {
            public var value: Int
            public static let range: ClosedRange<Int> = -63...63
            public static let defaultValue = 0

            public init(_ value: Int) {
                self.value = Self.range.clamp(value)
            }
        }

        public var attackTime: Time
        public var decay1Time: Time
        public var decay1Level: Level
        public var decay2Time: Time
        public var decay2Level: Level
        public var releaseTime: Time
        public var keyScalingToAttack: Level
        public var keyScalingToDecay1: Level
        public var velocityToEnvelope: Level
        public var velocityToAttack: Level
        public var velocityToDecay1: Level
        
        public init() {
            attackTime = 0
            decay1Time = 0
            decay1Level = 0
            decay2Time = 0
            decay2Level = 0
            releaseTime = 0
            keyScalingToAttack = 0
            keyScalingToDecay1 = 0
            velocityToEnvelope = 0
            velocityToAttack = 0
            velocityToDecay1 = 0
        }
        
        /// Parse the filter envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
        
            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attackTime = Time(Int(b))

            b = data.next(&offset)
            temp.decay1Time = Time(Int(b))
            
            b = data.next(&offset)
            temp.decay1Level = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.decay2Time = Time(Int(b))
            
            b = data.next(&offset)
            temp.decay2Level = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.releaseTime = Time(Int(b))
            
            b = data.next(&offset)
            temp.keyScalingToAttack = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.keyScalingToDecay1 = Level(Int(b) - 64)
            
            b = data.next(&offset)
            temp.velocityToEnvelope = Level(Int(b) - 64)

            b = data.next(&offset)
            temp.velocityToAttack = Level(Int(b) - 64)

            b = data.next(&offset)
            temp.velocityToDecay1 = Level(Int(b) - 64)

            return .success(temp)
        }
    }

    public var isActive: Bool
    public var cutoff: Level
    public var resonance: Resonance
    public var mode: Mode
    public var velocityCurve: VelocityCurve  // 1...12
    public var level: Level
    public var keyScalingToCutoff: Depth
    public var velocityToCutoff: Depth
    public var envelopeDepth: Depth
    public var envelope: Envelope
    
    public init() {
        isActive = false
        cutoff = 127
        resonance = 0
        mode = .lowPass
        velocityCurve = 1
        level = 7
        keyScalingToCutoff = 0
        velocityToCutoff = 0
        envelopeDepth = 0
        envelope = Envelope()
    }
    
    /// Parse the filter from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<Filter, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
    
        var temp = Filter()
        
        b = data.next(&offset)
        temp.isActive = b == 1 ? false : true  // value of 1 means filter is bypassed
        
        b = data.next(&offset)
        temp.mode = Mode(index: Int(b))!
        
        b = data.next(&offset)
        temp.velocityCurve = VelocityCurve(Int(b + 1))  // from 0 ~ 11 to  1 ~ 12

        b = data.next(&offset)
        temp.resonance = Resonance(Int(b))

        b = data.next(&offset)
        temp.level = Level(Int(b))
        
        b = data.next(&offset)
        temp.cutoff = Level(Int(b))

        b = data.next(&offset)
        temp.keyScalingToCutoff = Depth(Int(b) - 64)
        
        b = data.next(&offset)
        temp.velocityToCutoff = Depth(Int(b) - 64)
        
        b = data.next(&offset)
        temp.envelopeDepth = Depth(Int(b) - 64)
        
        switch Envelope.parse(from: data.slice(from: offset, length: Envelope.dataSize)) {
        case .success(let env):
            temp.envelope = env
        case .failure(let error):
            return .failure(error)
        }

        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Filter: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            isActive ? 0 : 1,
            mode.index,
            velocityCurve.value - 1,
            resonance.value,
            level.value,
            cutoff.value,
            keyScalingToCutoff.value + 64,
            velocityToCutoff.value + 64,
            envelopeDepth.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: envelope.asData())
        
        return data
    }
    
    public var dataLength: Int { Filter.dataSize }
    
    public static let dataSize = 20
}

extension Filter.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            attackTime.value,
            decay1Time.value,
            decay1Level.value + 64,
            decay2Time.value, 
            decay2Level.value + 64,
            releaseTime.value,
            keyScalingToAttack.value + 64, 
            keyScalingToDecay1.value + 64,
            velocityToEnvelope.value + 64, 
            velocityToAttack.value + 64,
            velocityToDecay1.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }

        return data
    }
    
    public var dataLength: Int { Filter.Envelope.dataSize }
    
    public static let dataSize = 11
}

// MARK: - CustomStringConvertible

extension Filter: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Active=" + (isActive ? "YES" : "NO") + " Mode=\(mode)\n"
        s += "Cutoff=\(cutoff.value) Resonance=\(resonance.value) Level=\(level.value)\n"
        s += "Vel.Curve=\(velocityCurve.value) KStoCut=\(keyScalingToCutoff.value) VelToCut=\(velocityToCutoff.value)\n"
        s += "Env.Depth=\(envelopeDepth.value)\n"
        s += "\nFilter Envelope:\n\(envelope)\n"
        return s
    }
}

extension Filter.Mode: CustomStringConvertible {
    public var description: String {
        var s = ""
        switch self {
        case .lowPass:
            s = "LP"
        case .highPass:
            s = "HP"
        }
        return s
    }
}

extension Filter.Envelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "attackTime=\(attackTime.value) decay1Time=\(decay1Time.value) decay1Level=\(decay1Level.value)\n"
        s += "decay2Time=\(decay2Time.value) decay2Level=\(decay2Level.value) releaseTime=\(releaseTime.value)\n"
        s += "KSToAttack=\(keyScalingToAttack.value) KSToDecay=\(keyScalingToDecay1.value)\n"
        s += "VelToEnv=\(velocityToEnvelope.value) VelToAttack=\(velocityToAttack.value) VelToDecay1=\(velocityToDecay1.value)"
        return s
    }
}
