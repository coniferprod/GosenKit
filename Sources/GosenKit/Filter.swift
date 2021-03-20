import Foundation

public enum FilterModeType: String, Codable, CaseIterable {
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

public struct FilterEnvelope: Codable {
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
    
    static let dataLength = 11
    
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
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(attackTime))
        data.append(Byte(decay1Time))
        data.append(Byte(decay1Level + 64))
        data.append(Byte(decay2Time))
        data.append(Byte(decay2Level + 64))
        data.append(Byte(releaseTime))
        data.append(Byte(keyScalingToAttack + 64))
        data.append(Byte(keyScalingToDecay1 + 64))
        data.append(Byte(velocityToEnvelope + 64))
        data.append(Byte(velocityToAttack + 64))
        data.append(Byte(velocityToDecay1 + 64))

        return data
    }
}

extension FilterEnvelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "attackTime=\(attackTime) decay1Time=\(decay1Time) decay1Level=\(decay1Level)\n"
        s += "decay2Time=\(decay2Time) decay2Level=\(decay2Level) releaseTime=\(releaseTime)\n"
        s += "KSToAttack=\(keyScalingToAttack) KSToDecay=\(keyScalingToDecay1)\n"
        s += "VelToEnv=\(velocityToEnvelope) VelToAttack=\(velocityToAttack) VelToDecay1=\(velocityToDecay1)\n"
        return s
    }
}

public struct Filter: Codable {
    public var isActive: Bool
    public var cutoff: Int
    public var resonance: Int
    public var mode: FilterModeType
    public var velocityCurve: Int  // 1...12
    public var level: Int
    public var keyScalingToCutoff: Int
    public var velocityToCutoff: Int
    public var envelopeDepth: Int
    public var envelope: FilterEnvelope
    
    static let dataLength = 20
    
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
        envelope = FilterEnvelope()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d.next(&offset)
        isActive = b == 1 ? false : true  // value of 1 means filter is bypassed
        
        b = d.next(&offset)
        mode = FilterModeType(index: Int(b))!
        
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
        
        envelope = FilterEnvelope(data: ByteArray(d[offset ..< offset + FilterEnvelope.dataLength]))
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(isActive ? 0 : 1)  // note that we need to flip the values for the SysEx!
        data.append(Byte(mode.index!))
        data.append(Byte(velocityCurve - 1))  // make 0~11
        data.append(Byte(resonance))
        data.append(Byte(level))
        data.append(Byte(cutoff))
        data.append(Byte(keyScalingToCutoff + 64))
        data.append(Byte(velocityToCutoff + 64))
        data.append(Byte(envelopeDepth + 64))
        data.append(contentsOf: envelope.asData())
        
        return data
    }
}

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
