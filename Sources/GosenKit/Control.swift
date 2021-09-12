import Foundation

/// Key with note number and name.
public struct Key: Codable {
    public var note: Int
    
    public var name: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = self.note / 12 - 1
        let name = noteNames[self.note % 12]
        return "\(name)\(octave)"
    }
    
    public init(note: Int) {
        self.note = note
    }
    
    public init(name: String) {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        let notes = CharacterSet(charactersIn: "CDEFGAB")
        
        var i = 0
        var notePart = ""
        var octavePart = ""
        while i < name.count {
            let c = name[i ..< i + 1]
            
            let isNote = c.unicodeScalars.allSatisfy { notes.contains($0) }
            if isNote {
                notePart += c
            }
     
            if c == "#" {
                notePart += c
            }
            if c == "-" {
                octavePart += c
            }
            
            let isDigit = c.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) }
            if isDigit {
                octavePart += c
            }

            i += 1
        }

        if let octave = Int(octavePart), let noteIndex = names.firstIndex(where: { $0 == notePart }) {
            self.note = (octave + 1) * 12 + noteIndex
        }
        else {
            self.note = 0
        }
    }
}

/// Keyboard zone with low and high keys.
public struct Zone: Codable {
    public var high: Key
    public var low: Key
}

/// Velocity switch settings.
public struct VelocitySwitch: Codable {
    // On the synth, the threshold value goes from 4 to 127 in steps of four! (last step is from 124 to 127)
    // So as the SysEx spec says, the value of 0 means 4, 1 means 8, and so on... and 31 means 127.
    // I guess that 30 must mean 124 then. So the actual value in the SysEx should be 0...31, but it should be
    // translated on input from 0...31 to 4...127, and on output from 4...127 to 0...31 again.

    public enum Kind: String, Codable, CaseIterable {
        case off
        case loud
        case soft
        
        public init?(index: Int) {
            switch index {
            case 0: self = .off
            case 1: self = .loud
            case 2: self = .soft
            default: return nil
            }
        }
    }

    public var kind: Kind
    public var threshold: Int  // store as a value in the conversion table
    
    static let dataLength = 1
    
    // Get the value on input as table[n] (where n = bottom 5 bits of value),
    // and on output as indexOf(velocityThreshold).
    private static let conversionTable = [
        4, 8, 12, 16, 20, 24, 28, 32,
        36, 40, 44, 48, 52, 56, 60, 64,
        68, 72, 76, 80, 84, 88, 92, 96,
        100, 104, 108, 112, 116, 120, 124, 127
    ]
    
    public init(kind: Kind, threshold: Int) {
        self.kind = kind
        self.threshold = VelocitySwitch.conversionTable[threshold]
    }
    
    public init(data d: ByteArray) {
        let b = d[0]
        let vs = Int(b >> 5)   // bits 5-6
        kind = Kind(index: vs)!
        let n = Int(b & 0b00011111)   // bits 0-4
        threshold = VelocitySwitch.conversionTable[n]
    }
}

public enum ControlDestination: String, Codable, CaseIterable {
    case pitchOffset
    case cutoffOffset
    case level
    case vibratoDepthOffset
    case growlDepthOffset
    case tremoloDepthOffset
    case lfoSpeedOffset
    case attackTimeOffset
    case decay1TimeOffset
    case releaseTimeOffset
    case velocityOffset
    case resonanceOffset
    case panPotOffset
    case formantFilterBiasOffset
    case formantFilterEnvelopeLfoDepthOffset
    case formantFilterEnvelopeLfoSpeedOffset
    case harmonicLowOffset
    case harmonicHighOffset
    case harmonicEvenOffset
    case harmonicOddOffset
    
    public init?(index: Int) {
        switch index {
        case 0: self = .pitchOffset
        case 1: self = .cutoffOffset
        case 2: self = .level
        case 3: self = .vibratoDepthOffset
        case 4: self = .growlDepthOffset
        case 5: self = .tremoloDepthOffset
        case 6: self = .lfoSpeedOffset
        case 7: self = .attackTimeOffset
        case 8: self = .decay1TimeOffset
        case 9: self = .releaseTimeOffset
        case 10: self = .velocityOffset
        case 11: self = .resonanceOffset
        case 12: self = .panPotOffset
        case 13: self = .formantFilterBiasOffset
        case 14: self = .formantFilterEnvelopeLfoDepthOffset
        case 15: self = .formantFilterEnvelopeLfoSpeedOffset
        case 16: self = .harmonicLowOffset
        case 17: self = .harmonicHighOffset
        case 18: self = .harmonicEvenOffset
        case 19: self = .harmonicOddOffset
        default: return nil
        }
    }
}

public struct MacroController: Codable {
    public var destination1: ControlDestination
    public var depth1: Int  // -31~+31
    public var destination2: ControlDestination
    public var depth2: Int // -31~+31
    
    static let dataLength = 4
    
    public init() {
        destination1 = .cutoffOffset
        depth1 = 0
        destination2 = .cutoffOffset
        depth2 = 0
    }
    
    public init(
        destination1: ControlDestination,
        depth1: Int,
        destination2: ControlDestination,
        depth2: Int) {
        self.destination1 = destination1
        self.depth1 = depth1
        self.destination2 = destination2
        self.depth2 = depth2
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        destination1 = ControlDestination(index: Int(b))!

        b = d.next(&offset)
        depth1 = Int(b) - 64
        //print("depth1 byte = \(String(b, radix: 16))h, converted to \(depth1)")
        
        b = d.next(&offset)
        destination2 = ControlDestination(index: Int(b))!

        b = d.next(&offset)
        depth2 = Int(b) - 64
        //print("depth2 byte = \(String(b, radix: 16))h, converted to \(depth2)")
    }
}

public struct SwitchControl: Codable {
    public enum Kind: String, Codable, CaseIterable {
        case off
        case harmMax
        case harmBright
        case harmDark
        case harmSaw
        case selectLoud
        case addLoud
        case addFifth
        case addOdd
        case addEven
        case he1
        case he2
        case harmonicEnvelopeLoop
        case ffMax
        case ffComb
        case ffHiCut
        case ffComb2
        
        public init?(index: Int) {
            switch index {
            case 0: self = .off
            case 1: self = .harmMax
            case 2: self = .harmBright
            case 3: self = .harmDark
            case 4: self = .harmSaw
            case 5: self = .selectLoud
            case 6: self = .addLoud
            case 7: self = .addFifth
            case 8: self = .addOdd
            case 9: self = .addEven
            case 10: self = .he1
            case 11: self = .he2
            case 12: self = .harmonicEnvelopeLoop
            case 13: self = .ffMax
            case 14: self = .ffComb
            case 15: self = .ffHiCut
            case 16: self = .ffComb2
            default: return nil
            }
        }
    }

    public var switch1: Kind
    public var switch2: Kind
    public var footSwitch1: Kind
    public var footSwitch2: Kind
    
    public init() {
        switch1 = .off
        switch2 = .off
        footSwitch1 = .off
        footSwitch2 = .off
    }
    
    public init(switch1: Kind, switch2: Kind, footSwitch1: Kind, footSwitch2: Kind) {
        self.switch1 = switch1
        self.switch2 = switch2
        self.footSwitch1 = footSwitch1
        self.footSwitch2 = footSwitch2
    }
}

public enum ControlSource: String, Codable, CaseIterable {
    case bender
    case channelPressure
    case wheel
    case expression
    case midiVolume
    case panPot
    case generalController1
    case generalController2
    case generalController3
    case generalController4
    case generalController5
    case generalController6
    case generalController7
    case generalController8
    
    public init?(index: Int) {
        switch index {
        case 0: self = .bender
        case 1: self = .channelPressure
        case 2: self = .wheel
        case 3: self = .expression
        case 4: self = .midiVolume
        case 5: self = .panPot
        case 6: self = .generalController1
        case 7: self = .generalController2
        case 8: self = .generalController3
        case 9: self = .generalController4
        case 10: self = .generalController5
        case 11: self = .generalController6
        case 12: self = .generalController7
        case 13: self = .generalController8
        default: return nil
        }
    }
}

public enum EffectDestination: String, Codable, CaseIterable {
    case effect1DryWet
    case effect1Parameter
    case effect2DryWet
    case effect2Parameter
    case effect3DryWet
    case effect3Parameter
    case effect4DryWet
    case effect4Parameter
    case reverbDryWet1
    case reverbDryWet2
    
    public init?(index: Int) {
        switch index {
        case 0: self = .effect1DryWet
        case 1: self = .effect1Parameter
        case 2: self = .effect2DryWet
        case 3: self = .effect2Parameter
        case 4: self = .effect3DryWet
        case 5: self = .effect3Parameter
        case 6: self = .effect4DryWet
        case 7: self = .effect4Parameter
        case 8: self = .reverbDryWet1
        case 9: self = .reverbDryWet2
        default: return nil
        }
    }
}

public struct EffectControl: Codable {
    public struct Source: Codable {
        public var source: ControlSource
        public var destination: EffectDestination
        public var depth: Int
        
        static let dataLength = 3
        
        public init() {
            source = .bender
            destination = .reverbDryWet1
            depth = 0
        }
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
        
            b = d.next(&offset)
            source = ControlSource(index: Int(b))!
            
            b = d.next(&offset)
            destination = EffectDestination(index: Int(b))!
            
            b = d.next(&offset)
            depth = Int(b) - 64
        }
    }

    public var source1: Source
    public var source2: Source
    
    static let dataLength = 6
    
    public init() {
        source1 = Source()
        source2 = Source()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
    
        let length = Source.dataLength
        source1 = Source(data: d.slice(from: offset, length: length))
        offset += length
        source2 = Source(data: d.slice(from: offset, length: length))
    }
}

public struct AssignableController: Codable {
    public var source: ControlSource
    public var destination: ControlDestination
    public var depth: Int
    
    static let dataLength = 3
    
    public init() {
        source = .bender
        destination = .cutoffOffset
        depth = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        source = ControlSource(index: Int(b))!
        
        b = d.next(&offset)
        destination = ControlDestination(index: Int(b))!
        
        b = d.next(&offset)
        depth = Int(b)
    }
}

// MARK: - SystemExclusiveData

extension MacroController: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [destination1.index!, depth1 + 64, destination2.index!, depth2 + 64].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

extension VelocitySwitch: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        let t = VelocitySwitch.conversionTable.firstIndex(of: threshold)!
        let value = t | (self.kind.index! << 5)
        //print("velocity switch = \(self.velocitySwitchType.rawValue), velocityThreshold = \(self.velocityThreshold) --> velo_sw = \(String(value, radix: 2))")
        data.append(Byte(value))
        return data
    }
}

extension EffectControl.Source: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [source.index!, destination.index!, depth + 64].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

extension AssignableController: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [source.index!, destination.index!, depth].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

extension EffectControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
    
        data.append(contentsOf: source1.asData())
        data.append(contentsOf: source2.asData())
    
        return data
    }
}

extension SwitchControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [switch1.index!, switch2.index!, footSwitch1.index!, footSwitch2.index!].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

// MARK: - CustomStringConvertible

extension AssignableController: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(source.rawValue), destination=\(destination.rawValue), depth=\(depth)"
        return s
    }
}

extension EffectControl.Source: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(source.rawValue), destination=\(destination.rawValue), depth=\(depth)"
        return s
    }
}

extension EffectControl: CustomStringConvertible {
    public var description: String {
        var s = "Effect Control:\n"
        s += "    Source1: \(source1)\n"
        s += "    Source2: \(source2)\n"
        return s
    }
}

extension MacroController: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "destination1=\(destination1.rawValue), depth1=\(depth1)\n"
        s += "destination2=\(destination2.rawValue), depth1=\(depth2)\n"
        return s
    }
}

extension VelocitySwitch: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "\(kind.rawValue), threshold=\(threshold)"
        return s
    }
}
