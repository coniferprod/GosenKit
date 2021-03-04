import Foundation

enum EffectType: String, Codable, CaseIterable {
    case hall1
    case hall2
    case hall3
    case room1
    case room2
    case room3
    case plate1
    case plate2
    case plate3
    case reverse
    case longDelay
    case earlyReflection1
    case earlyReflection2
    case tapDelay1
    case tapDelay2
    case singleDelay
    case dualDelay
    case stereoDelay
    case crossDelay
    case autoPan
    case autoPanAndDelay
    case chorus1
    case chorus2
    case chorus1AndDelay
    case chorus2AndDelay
    case flanger1
    case flanger2
    case flanger1AndDelay
    case flanger2AndDelay
    case ensemble
    case ensembleAndDelay
    case celeste
    case celesteAndDelay
    case tremolo
    case tremoloAndDelay
    case phaser1
    case phaser2
    case phaser1AndDelay
    case phaser2AndDelay
    case rotary
    case autoWah
    case bandpass
    case exciter
    case enhancer
    case overdrive
    case distortion
    case overdriveAndDelay
    case distortionAndDelay
    
    init?(index: Int) {
        switch index {
        case 0: self = .hall1
        case 1: self = .hall2
        case 2: self = .hall3
        case 3: self = .room1
        case 4: self = .room2
        case 5: self = .room3
        case 6: self = .plate1
        case 7: self = .plate2
        case 8: self = .plate3
        case 9: self = .reverse
        case 10: self = .longDelay
        case 11: self = .earlyReflection1
        case 12: self = .earlyReflection2
        case 13: self = .tapDelay1
        case 14: self = .tapDelay2
        case 15: self = .singleDelay
        case 16: self = .dualDelay
        case 17: self = .stereoDelay
        case 18: self = .crossDelay
        case 19: self = .autoPan
        case 20: self = .autoPanAndDelay
        case 21: self = .chorus1
        case 22: self = .chorus2
        case 23: self = .chorus1AndDelay
        case 24: self = .chorus2AndDelay
        case 25: self = .flanger1
        case 26: self = .flanger2
        case 27: self = .flanger1AndDelay
        case 28: self = .flanger2AndDelay
        case 29: self = .ensemble
        case 30: self = .ensembleAndDelay
        case 31: self = .celeste
        case 32: self = .celesteAndDelay
        case 33: self = .tremolo
        case 34: self = .tremoloAndDelay
        case 35: self = .phaser1
        case 36: self = .phaser2
        case 37: self = .phaser1AndDelay
        case 38: self = .phaser2AndDelay
        case 39: self = .rotary
        case 40: self = .autoWah
        case 41: self = .bandpass
        case 42: self = .exciter
        case 43: self = .enhancer
        case 44: self = .overdrive
        case 45: self = .distortion
        case 46: self = .overdriveAndDelay
        case 47: self = .distortionAndDelay
        default: return nil
        }
    }
}

struct EffectDefinition: Codable {
    static let dataLength = 6
    
    var effectType: EffectType  // reverb = 0...10, other effects = 11...47
    var depth: Int  // 0~100  // reverb dry/wet1 = depth
    var parameter1: Int  // all parameters are 0~127, except reverb param1 = 0~100
    var parameter2: Int
    var parameter3: Int
    var parameter4: Int
    
    init() {
        effectType = .room1
        depth = 0
        parameter1 = 0
        parameter2 = 0
        parameter3 = 0
        parameter4 = 0
    }
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        effectType = EffectType(index: Int(b))!

        offset += 1
        b = d[offset]
        depth = Int(b)

        offset += 1
        b = d[offset]
        parameter1 = Int(b)

        offset += 1
        b = d[offset]
        parameter2 = Int(b)

        offset += 1
        b = d[offset]
        parameter3 = Int(b)

        offset += 1
        b = d[offset]
        parameter4 = Int(b)
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(effectType.index!))
        data.append(Byte(depth))
        data.append(Byte(parameter1))
        data.append(Byte(parameter2))
        data.append(Byte(parameter3))
        data.append(Byte(parameter4))

        return data
    }
}

struct EffectSettings: Codable {
    var algorithm: Int  // 1...4
    var reverb: EffectDefinition
    var effect1: EffectDefinition
    var effect2: EffectDefinition
    var effect3: EffectDefinition
    var effect4: EffectDefinition
    
    static let dataLength = 31
    
    init() {
        algorithm = 1
        reverb = EffectDefinition()
        effect1 = EffectDefinition()
        effect2 = EffectDefinition()
        effect3 = EffectDefinition()
        effect4 = EffectDefinition()
    }
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        algorithm = Int(b + 1)  // adjust 0~3 to 1~4
        offset += 1
        
        reverb = EffectDefinition(data: ByteArray(d[offset ..< offset + EffectDefinition.dataLength]))
        offset += EffectDefinition.dataLength
        
        effect1 = EffectDefinition(data: ByteArray(d[offset ..< offset + EffectDefinition.dataLength]))
        offset += EffectDefinition.dataLength
        
        effect2 = EffectDefinition(data: ByteArray(d[offset ..< offset + EffectDefinition.dataLength]))
        offset += EffectDefinition.dataLength
        
        effect3 = EffectDefinition(data: ByteArray(d[offset ..< offset + EffectDefinition.dataLength]))
        offset += EffectDefinition.dataLength
        
        effect4 = EffectDefinition(data: ByteArray(d[offset ..< offset + EffectDefinition.dataLength]))
        offset += EffectDefinition.dataLength
    }
        
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(algorithm - 1))  // offset one to make the value 0~3
        data.append(contentsOf: reverb.asData())
        data.append(contentsOf: effect1.asData())
        data.append(contentsOf: effect2.asData())
        data.append(contentsOf: effect3.asData())
        data.append(contentsOf: effect4.asData())
        
        return data
    }
}

extension EffectSettings: CustomStringConvertible {
    var description: String {
        var s = ""
        s += "Effect Settings:\n"
        s += "Algorithm = \(algorithm)\n"
        s += "Reverb: type=\(reverb.effectType.rawValue), dry/wet=\(reverb.depth), para1=\(reverb.parameter1), para2=\(reverb.parameter2), para3=\(reverb.parameter3), para4=\(reverb.parameter4)\n"
        s += "Effect1: type=\(effect1.effectType.rawValue), depth=\(effect1.depth), para1=\(effect1.parameter1), para2=\(effect1.parameter2), para3=\(effect1.parameter3), para4=\(effect1.parameter4)\n"
        s += "Effect2: type=\(effect2.effectType.rawValue), depth=\(effect2.depth), para1=\(effect2.parameter1), para2=\(effect2.parameter2), para3=\(effect2.parameter3), para4=\(effect2.parameter4)\n"
        s += "Effect3: type=\(effect3.effectType.rawValue), depth=\(effect3.depth), para1=\(effect3.parameter1), para2=\(effect3.parameter2), para3=\(effect3.parameter3), para4=\(effect3.parameter4)\n"
        s += "Effect4: type=\(effect4.effectType.rawValue), depth=\(effect4.depth), para1=\(effect4.parameter1), para2=\(effect4.parameter2), para3=\(effect4.parameter3), para4=\(effect4.parameter4)"
        return s
    }
}
