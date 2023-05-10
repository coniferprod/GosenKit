import SyxPack


/// Effect definition.
public struct EffectDefinition: Codable {
    /// Effect kind enumeration.
    public enum Kind: Int, Codable, CaseIterable {
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
        
        /// Initialize effect definition from System Exclusive byte value.
        /// Fails if byte is outside the enum value range.
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
    
    /// Name of the effect and its parameters.
    public struct Name: Codable {
        /// Effect name.
        public var name: String
        
        /// Effect parameter names. There are always four values,
        /// and unused parameters are represented with "?".
        public var parameterNames: [String]
    }

    public static let names: [Name] = [
        /*  0 */ Name(name: "Hall 1", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  1 */ Name(name: "Hall 2", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  2 */ Name(name: "Hall 3", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  3 */ Name(name: "Room 1", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  4 */ Name(name: "Room 2", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  5 */ Name(name: "Room 3", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  6 */ Name(name: "Plate 1", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  7 */ Name(name: "Plate 2", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  8 */ Name(name: "Plate 3", parameterNames: ["Dry/Wet 2", "Reverb Time", "Predelay Time", "High Frequency Damping"]),
        /*  9 */ Name(name: "Reverse", parameterNames: ["Dry/Wet 2", "Feedback", "Predelay Time", "High Frequency Damping"]),
        /* 10 */ Name(name: "Long Delay", parameterNames: ["Dry/Wet 2", "Feedback", "Delay Time", "High Frequency Damping"]),
        /* 11 */ Name(name: "Early Reflection 1", parameterNames: ["Slope", "Predelay Time", "Feedback", "?"]),
        /* 12 */ Name(name: "Early Reflection 2", parameterNames: ["Slope", "Predelay Time", "Feedback", "?"]),
        /* 13 */ Name(name: "Tap Delay 1", parameterNames: ["Delay Time 1", "Tap Level", "Delay Time 2", "?"]),
        /* 14 */ Name(name: "Tap Delay 2", parameterNames: ["Delay Time 1", "Tap Level", "Delay Time 2", "?"]),
        /* 15 */ Name(name: "Single Delay", parameterNames: ["Delay Time Fine", "Delay Time Coarse", "Feedback", "?"]),
        /* 16 */ Name(name: "Dual Delay", parameterNames: ["Delay Time Left", "Feedback Left", "Delay Time Right", "Feedback Right"]),
        /* 17 */ Name(name: "Stereo Delay", parameterNames: ["Delay Time", "Feedback", "?", "?"]),
        /* 18 */ Name(name: "Cross Delay", parameterNames: ["Delay Time", "Feedback", "?", "?"]),
        /* 19 */ Name(name: "Auto Pan", parameterNames: ["Speed", "Depth", "Predelay Time", "Wave"]),
        /* 20 */ Name(name: "Auto Pan & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Wave"]),
        /* 21 */ Name(name: "Chorus 1", parameterNames: ["Speed", "Depth", "Predelay Time", "Wave"]),
        /* 22 */ Name(name: "Chorus 2", parameterNames: ["Speed", "Depth", "Predelay Time", "Wave"]),
        /* 23 */ Name(name: "Chorus 1 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Wave"]),
        /* 24 */ Name(name: "Chorus 2 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Wave"]),
        /* 25 */ Name(name: "Flanger 1", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
        /* 26 */ Name(name: "Flanger 2", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
        /* 27 */ Name(name: "Flanger 1 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
        /* 28 */ Name(name: "Flanger 2 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
        /* 29 */ Name(name: "Ensemble", parameterNames: ["Depth", "Predelay Time", "?", "?"]),
        /* 30 */ Name(name: "Ensemble & Delay", parameterNames: ["Depth", "Delay Time", "?", "?"]),
        /* 31 */ Name(name: "Celeste", parameterNames: ["Speed", "Depth", "Predelay Time", "?"]),
        /* 32 */ Name(name: "Celeste & Delay", parameterNames: [ "Speed", "Depth", "Delay Time", "?"]),
        /* 33 */ Name(name: "Tremolo", parameterNames: [ "Speed", "Depth", "Predelay Time", "Wave"]),
        /* 34 */ Name(name: "Tremolo & Delay", parameterNames: [ "Speed", "Depth", "Delay Time", "Wave"]),
        /* 35 */ Name(name: "Phaser 1", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
        /* 36 */ Name(name: "Phaser 2", parameterNames: ["Speed", "Depth", "Predelay Time", "Feedback"]),
        /* 37 */ Name(name: "Phaser 1 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
        /* 38 */ Name(name: "Phaser 2 & Delay", parameterNames: ["Speed", "Depth", "Delay Time", "Feedback"]),
        /* 39 */ Name(name: "Rotary", parameterNames: ["Slow Speed", "Fast Speed", "Acceleration", "Slow/Fast Switch"]),
        /* 40 */ Name(name: "Auto Wah", parameterNames: ["Sense", "Frequency Bottom", "Frequency Top", "Resonance"]),
        /* 41 */ Name(name: "Bandpass", parameterNames: ["Center Frequency", "Bandwidth", "?", "?"]),
        /* 42 */ Name(name: "Exciter", parameterNames: ["EQ Low", "EQ High", "Intensity", "?"]),
        /* 43 */ Name(name: "Enhancer", parameterNames: ["EQ Low", "EQ High", "Intensity", "?"]),
        /* 44 */ Name(name: "Overdrive", parameterNames: ["EQ Low", "EQ High", "Output Level", "Drive"]),
        /* 45 */ Name(name: "Distortion", parameterNames: ["EQ Low", "EQ High", "Output Level", "Drive"]),
        /* 46 */ Name(name: "Overdrive & Delay", parameterNames: ["EQ Low", "EQ High", "Delay Time", "Drive"]),
        /* 47 */ Name(name: "Distortion & Delay", parameterNames: ["EQ Low", "EQ High", "Delay Time", "Drive"]),
    ]

    public var kind: Kind  // reverb = 0...10, other effects = 11...47
    public var depth: Int  // 0~100  // reverb dry/wet1 = depth
    public var parameter1: Int  // all parameters are 0~127, except reverb param1 = 0~100
    public var parameter2: Int
    public var parameter3: Int
    public var parameter4: Int
    
    /// Initializes the effect definition with default values.
    public init() {
        kind = .room1
        depth = 0
        parameter1 = 0
        parameter2 = 0
        parameter3 = 0
        parameter4 = 0
    }
    
    /// Initializes the effect definition from MIDI System Exclusive data.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        kind = Kind(index: Int(b))!

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
    
    public static func parse(from data: ByteArray) -> Result<EffectDefinition, ParseError> {
        var offset: Int = 0
        var b: Byte = 0

        var temp = EffectDefinition()  // initialize with defaults, then fill in
        
        b = data.next(&offset)
        temp.kind = Kind(index: Int(b))!

        b = data.next(&offset)
        temp.depth = Int(b)

        b = data.next(&offset)
        temp.parameter1 = Int(b)

        b = data.next(&offset)
        temp.parameter2 = Int(b)

        b = data.next(&offset)
        temp.parameter3 = Int(b)

        b = data.next(&offset)
        temp.parameter4 = Int(b)
        
        return .success(temp)
    }
}

/// Represents the effect settings for a patch.
public struct EffectSettings: Codable {
    public var algorithm: Int  // 1...4
    public var reverb: EffectDefinition
    public var effect1: EffectDefinition
    public var effect2: EffectDefinition
    public var effect3: EffectDefinition
    public var effect4: EffectDefinition
    
    /// Initializes the effect settings with defaults.
    public init() {
        algorithm = 1
        reverb = EffectDefinition()
        effect1 = EffectDefinition()
        effect2 = EffectDefinition()
        effect3 = EffectDefinition()
        effect4 = EffectDefinition()
    }
    
    /// Initializes the effect settings from MIDI System Exclusive data bytes.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        algorithm = Int(b + 1)  // adjust 0~3 to 1~4
        
        reverb = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataSize))
        offset += EffectDefinition.dataSize
        
        effect1 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataSize))
        offset += EffectDefinition.dataSize
        
        effect2 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataSize))
        offset += EffectDefinition.dataSize
        
        effect3 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataSize))
        offset += EffectDefinition.dataSize
        
        effect4 = EffectDefinition(data: d.slice(from: offset, length: EffectDefinition.dataSize))
    }

    public static func parse(from data: ByteArray) -> Result<EffectSettings, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = EffectSettings()  // initialize with defaults, then fill in
        
        b = data.next(&offset)
        temp.algorithm = Int(b + 1)  // adjust 0~3 to 1~4
        
        switch EffectDefinition.parse(from: data.slice(from: offset, length: EffectDefinition.dataSize)) {
        case .success(let effect):
            temp.reverb = effect
        case .failure(let error):
            return .failure(error)
        }
        offset += EffectDefinition.dataSize
        
        switch EffectDefinition.parse(from: data.slice(from: offset, length: EffectDefinition.dataSize)) {
        case .success(let effect):
            temp.effect1 = effect
        case .failure(let error):
            return .failure(error)
        }
        offset += EffectDefinition.dataSize
        
        switch EffectDefinition.parse(from: data.slice(from: offset, length: EffectDefinition.dataSize)) {
        case .success(let effect):
            temp.effect2 = effect
        case .failure(let error):
            return .failure(error)
        }
        offset += EffectDefinition.dataSize
        
        switch EffectDefinition.parse(from: data.slice(from: offset, length: EffectDefinition.dataSize)) {
        case .success(let effect):
            temp.effect3 = effect
        case .failure(let error):
            return .failure(error)
        }
        offset += EffectDefinition.dataSize
        
        switch EffectDefinition.parse(from: data.slice(from: offset, length: EffectDefinition.dataSize)) {
        case .success(let effect):
            temp.effect4 = effect
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension EffectDefinition: SystemExclusiveData {
    /// Gets the effect definition as MIDI System Exclusive data bytes.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            kind.index, depth,
            parameter1, parameter2, parameter3, parameter4
        ]
        .forEach {
            data.append(Byte($0))
        }

        return data
    }
    
    /// Number of MIDI System Exclusive bytes.
    public var dataLength: Int { return EffectDefinition.dataSize }
    
    public static let dataSize = 6
}

extension EffectSettings: SystemExclusiveData {
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

    public var dataLength: Int { return EffectSettings.dataSize }
    public static let dataSize = 31
}

// MARK: - CustomStringConvertible

extension EffectSettings: CustomStringConvertible {
    // Helper function to construct a printable effect definition string.
    private func getEffectString(effectDefinition: EffectDefinition, effectNumber: Int) -> String {
        var result = ""
        
        if effectNumber == 0 {  // means reverb
            result += "Reverb: "
        }
        else {
            result += "Effect \(effectNumber): "
        }

        let effectName = EffectDefinition.names[effectDefinition.kind.rawValue]
        result += effectName.name
        
        if effectNumber == 0 {
            result += " Dry/Wet"
        }
        else {
            result += " Depth"
        }
        result += "=\(effectDefinition.depth) "
        
        if effectName.parameterNames[0] != "?" {
            result += "\(effectName.parameterNames[0])=\(effectDefinition.parameter1) "
        }
        
        if effectName.parameterNames[1] != "?" {
            result += "\(effectName.parameterNames[1])=\(effectDefinition.parameter2) "
        }

        if effectName.parameterNames[2] != "?" {
            result += "\(effectName.parameterNames[2])=\(effectDefinition.parameter3) "
        }
        
        if effectName.parameterNames[3] != "?" {
            result += "\(effectName.parameterNames[3])=\(effectDefinition.parameter4)"
        }

        result += "\n"
        return result
    }
    
    /// Gets a printable representation of the effect settings.
    public var description: String {
        var s = "\nEffect Settings:\n"
        s += "Algorithm = \(algorithm)\n"
        
        s += getEffectString(effectDefinition: reverb, effectNumber: 0)
        s += getEffectString(effectDefinition: effect1, effectNumber: 1)
        s += getEffectString(effectDefinition: effect2, effectNumber: 2)
        s += getEffectString(effectDefinition: effect3, effectNumber: 3)
        s += getEffectString(effectDefinition: effect4, effectNumber: 4)

        return s
    }
}
