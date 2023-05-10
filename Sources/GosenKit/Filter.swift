import SyxPack

/// Filter (DCF).
public struct Filter: Codable {
    /// Filter mode.
    public enum Mode: Int, Codable, CaseIterable {
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
    public struct Envelope: Codable {
        public var attackTime: Int
        public var decay1Time: Int
        public var decay1Level: Int
        public var decay2Time: Int
        public var decay2Level: Int
        public var releaseTime: Int
        public var keyScalingToAttack: Int
        public var keyScalingToDecay1: Int
        public var velocityToEnvelope: Int
        public var velocityToAttack: Int
        public var velocityToDecay1: Int
        
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
        
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
        
            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attackTime = Int(b)

            b = data.next(&offset)
            temp.decay1Time = Int(b)
            
            b = data.next(&offset)
            temp.decay1Level = Int(b) - 64
            
            b = data.next(&offset)
            temp.decay2Time = Int(b)
            
            b = data.next(&offset)
            temp.decay2Level = Int(b) - 64
            
            b = data.next(&offset)
            temp.releaseTime = Int(b)
            
            b = data.next(&offset)
            temp.keyScalingToAttack = Int(b) - 64
            
            b = data.next(&offset)
            temp.keyScalingToDecay1 = Int(b) - 64
            
            b = data.next(&offset)
            temp.velocityToEnvelope = Int(b) - 64

            b = data.next(&offset)
            temp.velocityToAttack = Int(b) - 64

            b = data.next(&offset)
            temp.velocityToDecay1 = Int(b) - 64

            return .success(temp)
        }
    }

    public var isActive: Bool
    public var cutoff: Int
    public var resonance: Int
    public var mode: Mode
    public var velocityCurve: Int  // 1...12
    public var level: Int
    public var keyScalingToCutoff: Int
    public var velocityToCutoff: Int
    public var envelopeDepth: Int
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
    
    public static func parse(from data: ByteArray) -> Result<Filter, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
    
        var temp = Filter()
        
        b = data.next(&offset)
        temp.isActive = b == 1 ? false : true  // value of 1 means filter is bypassed
        
        b = data.next(&offset)
        temp.mode = Mode(index: Int(b))!
        
        b = data.next(&offset)
        temp.velocityCurve = Int(b + 1)  // from 0 ~ 11 to  1 ~ 12

        b = data.next(&offset)
        temp.resonance = Int(b)

        b = data.next(&offset)
        temp.level = Int(b)
        
        b = data.next(&offset)
        temp.cutoff = Int(b)

        b = data.next(&offset)
        temp.keyScalingToCutoff = Int(b) - 64
        
        b = data.next(&offset)
        temp.velocityToCutoff = Int(b) - 64
        
        b = data.next(&offset)
        temp.envelopeDepth = Int(b) - 64
        
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
            velocityCurve - 1,
            resonance,
            level,
            cutoff,
            keyScalingToCutoff + 64,
            velocityToCutoff + 64,
            envelopeDepth + 64
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: envelope.asData())
        
        return data
    }
    
    public var dataLength: Int { return Filter.dataSize }
    
    public static let dataSize = 20
}

extension Filter.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [attackTime, decay1Time, decay1Level + 64, decay2Time, decay2Level + 64, releaseTime,
         keyScalingToAttack + 64, keyScalingToDecay1 + 64, velocityToEnvelope + 64, velocityToAttack + 64, velocityToDecay1 + 64].forEach {
            data.append(Byte($0))
        }

        return data
    }
    
    public var dataLength: Int { return Filter.Envelope.dataSize }
    
    public static let dataSize = 11
}

// MARK: - CustomStringConvertible

extension Filter: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Active=" + (isActive ? "YES" : "NO") + " Mode=\(mode)\n"
        s += "Cutoff=\(cutoff) Resonance=\(resonance) Level=\(level)\n"
        s += "Vel.Curve=\(velocityCurve) KStoCut=\(keyScalingToCutoff) VelToCut=\(velocityToCutoff)\n"
        s += "Env.Depth=\(envelopeDepth)\n"
        s += "Filter Envelope:\n\(envelope)\n"
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
        s += "attackTime=\(attackTime) decay1Time=\(decay1Time) decay1Level=\(decay1Level)\n"
        s += "decay2Time=\(decay2Time) decay2Level=\(decay2Level) releaseTime=\(releaseTime)\n"
        s += "KSToAttack=\(keyScalingToAttack) KSToDecay=\(keyScalingToDecay1)\n"
        s += "VelToEnv=\(velocityToEnvelope) VelToAttack=\(velocityToAttack) VelToDecay1=\(velocityToDecay1)\n"
        return s
    }
}
