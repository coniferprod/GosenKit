import Foundation

public enum EffectType: String, Codable, CaseIterable {
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
    
    public init?(index: Int) {
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

public struct EffectName {
    public var name: String
    public var parameterNames: [String]
}

public var effectNames = [EffectName]([
    /*  0 */ EffectName(name: "Hall 1", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  1 */ EffectName(name: "Hall 2", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  2 */ EffectName(name: "Hall 3", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  3 */ EffectName(name: "Room 1", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  4 */ EffectName(name: "Room 2", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  5 */ EffectName(name: "Room 3", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  6 */ EffectName(name: "Plate 1", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  7 */ EffectName(name: "Plate 2", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  8 */ EffectName(name: "Plate 3", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
    /*  9 */ EffectName(name: "Reverse", parameterNames: ["Dry/Wet 2", "Feedback", "Predelay Time", "High Frequency Damping"]),
    /* 10 */ EffectName(name: "Long Delay", parameterNames: ["Dry/Wet 2", "Feedback", "Delay Time", "High Frequency Damping"]),
    /* 11 */ EffectName(name: "Early Reflection 1", parameterNames: ["Slope", "Predelay Time", "Feedback", "?"]),
    /* 12 */ EffectName(name: "Early Reflection 2", parameterNames: ["Slope", "Predelay Time", "Feedback", "?"]),
    /* 13 */ EffectName(name: "Tap Delay 1", parameterNames: ["Delay Time 1", "Tap Level", "Delay Time 2", "?"]),
    /* 14 */ EffectName(name: "Tap Delay 2", parameterNames: ["Delay Time 1", "Tap Level", "Delay Time 2", "?"]),
    /* 15 */ EffectName(name: "Single Delay", parameterNames: ["Delay Time Fine", "Delay Time Coarse", "Feedback", "?"]),
    /* 16 */ EffectName(name: "Dual Delay", parameterNames: ["Delay Time Left", "Feedback Left", "Delay Time Right", "Feedback Right"]),
    /* 17 */ EffectName(name: "Stereo Delay", parameterNames: ["Delay Time", "Feedback", "?", "?"]),
    /* 18 */ EffectName(name: "Cross Delay", parameterNames: ["Delay Time", "Feedback", "?", "?"]),
    /* 19 */ EffectName(name: "Auto Pan", parameterNames: ["Speed", "Depth", "Predelay Time", "Wave"]),
    /* 20 */ EffectName(name: "Auto Pan & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Wave"]),
    /* 21 */ EffectName(name: "Chorus 1", parameterNames: ["Speed", "Depth", "Predelay Time", "Wave"]),
    /* 22 */ EffectName(name: "Chorus 2", parameterNames: ["Speed", "Depth", "Predelay Time", "Wave"]),
    /* 23 */ EffectName(name: "Chorus 1 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Wave"]),
    /* 24 */ EffectName(name: "Chorus 2 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Wave"]),
    /* 25 */ EffectName(name: "Flanger 1", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
    /* 26 */ EffectName(name: "Flanger 2", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
    /* 27 */ EffectName(name: "Flanger 1 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
    /* 28 */ EffectName(name: "Flanger 2 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
    /* 29 */ EffectName(name: "Ensemble", parameterNames: ["Depth", "Predelay Time", "?", "?"]),
    /* 30 */ EffectName(name: "Ensemble & Delay", parameterNames: ["Depth", "Delay Time", "?", "?"]),
    /* 31 */ EffectName(name: "Celeste", parameterNames: ["Speed", "Depth", "Predelay Time", "?"]),
    /* 32 */ EffectName(name: "Celeste & Delay", parameterNames: [ "Speed", "Depth", "Delay Time", "?"]),
    /* 33 */ EffectName(name: "Tremolo", parameterNames: [ "Speed", "Depth", "Predelay Time", "Wave"]),
    /* 34 */ EffectName(name: "Tremolo & Delay", parameterNames: [ "Speed", "Depth", "Delay Time", "Wave"]),
    /* 35 */ EffectName(name: "Phaser 1", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
    /* 36 */ EffectName(name: "Phaser 2", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
    /* 37 */ EffectName(name: "Phaser 1 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
    /* 38 */ EffectName(name: "Phaser 2 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
    /* 39 */ EffectName(name: "Rotary", parameterNames: ["Slow Speed", "Fast Speed", "Acceleration", "Slow/Fast Switch"]),
    /* 40 */ EffectName(name: "Auto Wah", parameterNames: ["Sense", "Frequency Bottom", "Frequency Top", "Resonance"]),
    /* 41 */ EffectName(name: "Bandpass", parameterNames: ["Center Frequency", "Bandwidth", "?", "?"]),
    /* 42 */ EffectName(name: "Exciter", parameterNames: ["EQ Low", "EQ High", "Intensity", "?"]),
    /* 43 */ EffectName(name: "Enhancer", parameterNames: ["EQ Low", "EQ High", "Intensity", "?"]),
    /* 44 */ EffectName(name: "Overdrive", parameterNames: ["EQ Low", "EQ High", "Output Level", "Drive"]),
    /* 45 */ EffectName(name: "Distortion", parameterNames: ["EQ Low", "EQ High", "Output Level", "Drive"]),
    /* 46 */ EffectName(name: "Overdrive & Delay", parameterNames: ["EQ Low", "EQ High", "Delay Time", "Drive"]),
    /* 47 */ EffectName(name: "Distortion & Delay", parameterNames: ["EQ Low", "EQ High", "Delay Time", "Drive"]),
])

// Create an effect with sensible default settings.
public struct EffectDefinition: Codable {
    static let dataLength = 6
    
    public var effectType: EffectType  // reverb = 0...10, other effects = 11...47
    public var depth: Int  // 0~100  // reverb dry/wet1 = depth
    public var parameter1: Int  // all parameters are 0~127, except reverb param1 = 0~100
    public var parameter2: Int
    public var parameter3: Int
    public var parameter4: Int
    
    public init() {
        effectType = .room1
        depth = 0
        parameter1 = 0
        parameter2 = 0
        parameter3 = 0
        parameter4 = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        effectType = EffectType(index: Int(b))!

        b = d.next(&offset)
        depth = Int(b)

        b = d.next(&offset)
        parameter1 = Int(b)

        b = d.next(&offset)
        parameter2 = Int(b)

        b = d.next(&offset)
        parameter3 = Int(b)

        b = d.next(&offset)
        parameter4 = Int(b)
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [effectType.index!, depth, parameter1, parameter2, parameter3, parameter4].forEach {
            data.append(Byte($0))
        }

        return data
    }
}

public struct EffectSettings: Codable {
    public var algorithm: Int  // 1...4
    public var reverb: EffectDefinition
    public var effect1: EffectDefinition
    public var effect2: EffectDefinition
    public var effect3: EffectDefinition
    public var effect4: EffectDefinition
    
    static let dataLength = 31
    
    public init() {
        algorithm = 1
        reverb = EffectDefinition()
        effect1 = EffectDefinition()
        effect2 = EffectDefinition()
        effect3 = EffectDefinition()
        effect4 = EffectDefinition()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        algorithm = Int(b + 1)  // adjust 0~3 to 1~4
        
        reverb = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataLength))
        offset += EffectDefinition.dataLength
        
        effect1 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataLength))
        offset += EffectDefinition.dataLength
        
        effect2 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataLength))
        offset += EffectDefinition.dataLength
        
        effect3 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataLength))
        offset += EffectDefinition.dataLength
        
        effect4 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataLength))
    }
        
    public func asData() -> ByteArray {
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
    public var description: String {
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
