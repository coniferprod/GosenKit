import SyxPack

public struct Filter: Codable {
    public enum Mode: String, Codable, CaseIterable {
        case lowPass
        case highPass
        
        public init?(index: Int) {
            switch index {
            case 0: self = .lowPass
            case 1: self = .highPass
            default: return nil
            }
        }
    }

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
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
        
            b = d.next(&offset)
            attackTime = Int(b)

            b = d.next(&offset)
            decay1Time = Int(b)
            
            b = d.next(&offset)
            decay1Level = Int(b) - 64
            
            b = d.next(&offset)
            decay2Time = Int(b)
            
            b = d.next(&offset)
            decay2Level = Int(b) - 64
            
            b = d.next(&offset)
            releaseTime = Int(b)
            
            b = d.next(&offset)
            keyScalingToAttack = Int(b) - 64
            
            b = d.next(&offset)
            keyScalingToDecay1 = Int(b) - 64
            
            b = d.next(&offset)
            velocityToEnvelope = Int(b) - 64

            b = d.next(&offset)
            velocityToAttack = Int(b) - 64

            b = d.next(&offset)
            velocityToDecay1 = Int(b) - 64
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
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d.next(&offset)
        isActive = b == 1 ? false : true  // value of 1 means filter is bypassed
        
        b = d.next(&offset)
        mode = Mode(index: Int(b))!
        
        b = d.next(&offset)
        velocityCurve = Int(b + 1)  // from 0 ~ 11 to  1 ~ 12

        b = d.next(&offset)
        resonance = Int(b)

        b = d.next(&offset)
        level = Int(b)
        
        b = d.next(&offset)
        cutoff = Int(b)

        b = d.next(&offset)
        keyScalingToCutoff = Int(b) - 64
        
        b = d.next(&offset)
        velocityToCutoff = Int(b) - 64
        
        b = d.next(&offset)
        envelopeDepth = Int(b) - 64
        
        envelope = Envelope(data: d.slice(from: offset, length: Envelope.dataSize))
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
        s += "Active=" + (isActive ? "YES" : "NO") + " Mode=\(mode.rawValue)\n"
        s += "Cutoff=\(cutoff) Resonance=\(resonance) Level=\(level)\n"
        s += "Vel.Curve=\(velocityCurve) KStoCut=\(keyScalingToCutoff) VelToCut=\(velocityToCutoff)\n"
        s += "Env.Depth=\(envelopeDepth)\n"
        s += "Filter Envelope:\n\(envelope)\n"
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
