import Foundation

enum FilterModeType: String, Codable, CaseIterable {
    case lowPass
    case highPass
    
    init?(index: Int) {
        switch index {
        case 0: self = .lowPass
        case 1: self = .highPass
        default: return nil
        }
    }
}

struct FilterEnvelope: Codable {
    var attackTime: Int
    var decay1Time: Int
    var decay1Level: Int
    var decay2Time: Int
    var decay2Level: Int
    var releaseTime: Int
    var keyScalingToAttack: Int
    var keyScalingToDecay1: Int
    var velocityToEnvelope: Int
    var velocityToAttack: Int
    var velocityToDecay1: Int
    
    static let dataLength = 11
    
    init() {
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
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d[offset]
        attackTime = Int(b)
        offset += 1

        b = d[offset]
        decay1Time = Int(b)
        offset += 1
        
        b = d[offset]
        decay1Level = Int(b) - 64
        offset += 1
        
        b = d[offset]
        decay2Time = Int(b)
        offset += 1
        
        b = d[offset]
        decay2Level = Int(b) - 64
        offset += 1
        
        b = d[offset]
        releaseTime = Int(b)
        offset += 1
        
        b = d[offset]
        keyScalingToAttack = Int(b) - 64
        offset += 1
        
        b = d[offset]
        keyScalingToDecay1 = Int(b) - 64
        offset += 1
        
        b = d[offset]
        velocityToEnvelope = Int(b) - 64
        offset += 1

        b = d[offset]
        velocityToAttack = Int(b) - 64
        offset += 1

        b = d[offset]
        velocityToDecay1 = Int(b) - 64
        offset += 1
    }
    
    func asData() -> ByteArray {
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
    var description: String {
        var s = ""
        s += "attackTime=\(attackTime) decay1Time=\(decay1Time) decay1Level=\(decay1Level)\n"
        s += "decay2Time=\(decay2Time) decay2Level=\(decay2Level) releaseTime=\(releaseTime)\n"
        s += "KSToAttack=\(keyScalingToAttack) KSToDecay=\(keyScalingToDecay1)\n"
        s += "VelToEnv=\(velocityToEnvelope) VelToAttack=\(velocityToAttack) VelToDecay1=\(velocityToDecay1)\n"
        return s
    }
}

struct Filter: Codable {
    var isActive: Bool
    var cutoff: Int
    var resonance: Int
    var mode: FilterModeType
    var velocityCurve: Int  // 1...12
    var level: Int
    var keyScalingToCutoff: Int
    var velocityToCutoff: Int
    var envelopeDepth: Int
    var envelope: FilterEnvelope
    
    static let dataLength = 20
    
    init() {
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
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d[offset]
        isActive = b == 1 ? false : true  // value of 1 means filter is bypassed
        offset += 1
        
        b = d[offset]
        mode = FilterModeType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        velocityCurve = Int(b + 1)  // from 0 ~ 11 to  1 ~ 12
        offset += 1

        b = d[offset]
        resonance = Int(b)
        offset += 1

        b = d[offset]
        level = Int(b)
        offset += 1
        
        b = d[offset]
        cutoff = Int(b)
        offset += 1

        b = d[offset]
        keyScalingToCutoff = Int(b) - 64
        offset += 1
        
        b = d[offset]
        velocityToCutoff = Int(b) - 64
        offset += 1
        
        b = d[offset]
        envelopeDepth = Int(b) - 64
        offset += 1
        
        envelope = FilterEnvelope(data: ByteArray(d[offset ..< offset + FilterEnvelope.dataLength]))
        offset += FilterEnvelope.dataLength
    }
    
    func asData() -> ByteArray {
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
    var description: String {
        var s = ""
        s += "Active=" + (isActive ? "YES" : "NO") + " Mode=\(mode.rawValue)\n"
        s += "Cutoff=\(cutoff) Resonance=\(resonance) Level=\(level)\n"
        s += "Vel.Curve=\(velocityCurve) KStoCut=\(keyScalingToCutoff) VelToCut=\(velocityToCutoff)\n"
        s += "Env.Depth=\(envelopeDepth)\n"
        s += "Filter Envelope:\n\(envelope)\n"
        return s
    }
}
