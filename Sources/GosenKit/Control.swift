import Foundation

import SyxPack


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
    
    // Get the value on input as table[n] (where n = bottom 5 bits of value),
    // and on output as indexOf(velocityThreshold).
    private static let conversionTable = [
        4, 8, 12, 16, 20, 24, 28, 32,
        36, 40, 44, 48, 52, 56, 60, 64,
        68, 72, 76, 80, 84, 88, 92, 96,
        100, 104, 108, 112, 116, 120, 124, 127
    ]
    
    public init() {
        self.kind = .off
        self.threshold = VelocitySwitch.conversionTable[0]
    }
    
    public init(kind: Kind, threshold: Int) {
        self.kind = kind
        self.threshold = VelocitySwitch.conversionTable[threshold]
    }
    
    public static func parse(from data: ByteArray) -> Result<VelocitySwitch, ParseError> {
        var temp = VelocitySwitch()
        
        let b = data[0]
        let vs = Int(b >> 5)   // bits 5-6
        temp.kind = Kind(index: vs)!
        let n = Int(b & 0b00011111)   // bits 0-4
        temp.threshold = VelocitySwitch.conversionTable[n]
        
        return .success(temp)
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

public struct MacroController {
    /// Macro depth
    public struct Depth {
        private var _value: Int
    }
    
    public var destination1: ControlDestination
    public var depth1: Depth  // -31~+31
    public var destination2: ControlDestination
    public var depth2: Depth // -31~+31
    
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
        self.depth1 = Depth(depth1)
        self.destination2 = destination2
        self.depth2 = Depth(depth2)
    }
    
    public static func parse(from data: ByteArray) -> Result<MacroController, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = MacroController()  // initialize with defaults, then fill in
        
        b = data.next(&offset)
        temp.destination1 = ControlDestination(index: Int(b))!

        b = data.next(&offset)
        temp.depth1 = Depth(Int(b) - 64)
        
        b = data.next(&offset)
        temp.destination2 = ControlDestination(index: Int(b))!

        b = data.next(&offset)
        temp.depth2 = Depth(Int(b) - 64)
        
        return .success(temp)
    }
}

extension MacroController.Depth: RangedInt {
    public static let range: ClosedRange<Int> = -31...31
    public static let defaultValue = 0
    
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }
    
    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }

    public var value: Int {
        return _value
    }
}

extension MacroController.Depth: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
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

public enum ControlSource: Int, Codable, CaseIterable {
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

public enum EffectDestination: Int, Codable, CaseIterable {
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

public struct EffectControl {
    public struct Source {
        public var source: ControlSource
        public var destination: EffectDestination
        public var depth: ControlDepth
        
        public init() {
            source = .bender
            destination = .reverbDryWet1
            depth = 0
        }
        
        public static func parse(from data: ByteArray) -> Result<Source, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Source()  // initialize with defaults, then fill in
            
            b = data.next(&offset)
            temp.source = ControlSource(index: Int(b))!
            
            b = data.next(&offset)
            temp.destination = EffectDestination(index: Int(b))!
            
            b = data.next(&offset)
            temp.depth = ControlDepth(Int(b) - 64)
            
            return .success(temp)
        }
    }

    public var source1: Source
    public var source2: Source
    
    public init() {
        source1 = Source()
        source2 = Source()
    }
    
    public static func parse(from data: ByteArray) -> Result<EffectControl, ParseError> {
        var temp = EffectControl()  // initialize with defaults, then fill in
        
        var offset: Int = 0
        let size = Source.dataSize
        
        switch Source.parse(from: data.slice(from: offset, length: size)) {
        case .success(let source):
            temp.source1 = source
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        switch Source.parse(from: data.slice(from: offset, length: size)) {
        case .success(let source):
            temp.source2 = source
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
}

public struct AssignableController {
    public var source: ControlSource
    public var destination: ControlDestination
    public var depth: ControlDepth
    
    public init() {
        source = .bender
        destination = .cutoffOffset
        depth = 0
    }
    
    public static func parse(from data: ByteArray) -> Result<AssignableController, ParseError> {
        var offset: Int = 0
        var b: Byte = 0

        var temp = AssignableController()  // initialize with defaults, then fill in
        
        b = data.next(&offset)
        temp.source = ControlSource(index: Int(b))!
        
        b = data.next(&offset)
        temp.destination = ControlDestination(index: Int(b))!
        
        b = data.next(&offset)
        temp.depth = ControlDepth(Int(b) - 64)

        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension MacroController: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [
            destination1.index,
            depth1.value + 64,
            destination2.index,
            depth2.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }
        return data
    }

    public var dataLength: Int { MacroController.dataSize }
    
    public static let dataSize = 4
}

extension VelocitySwitch: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        let t = VelocitySwitch.conversionTable.firstIndex(of: threshold)!
        let value = t | (self.kind.index << 5)
        //print("velocity switch = \(self.velocitySwitchType.rawValue), velocityThreshold = \(self.velocityThreshold) --> velo_sw = \(String(value, radix: 2))")
        data.append(Byte(value))
        return data
    }
    
    public var dataLength: Int { 1 }
}

extension EffectControl.Source: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [
            source.index,
            destination.index,
            depth.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }
        return data
    }
    
    public var dataLength: Int { EffectControl.Source.dataSize }
    
    public static let dataSize = 3
}

extension AssignableController: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [
            source.index,
            destination.index,
            depth.value
        ]
        .forEach {
            data.append(Byte($0))
        }
        return data
    }
    
    public var dataLength: Int { AssignableController.dataSize }
    
    public static let dataSize = 3
}

extension EffectControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
    
        data.append(contentsOf: source1.asData())
        data.append(contentsOf: source2.asData())
    
        return data
    }
    
    public var dataLength: Int { EffectControl.dataSize }
    
    public static let dataSize = 6
}

extension SwitchControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [
            switch1.index,
            switch2.index,
            footSwitch1.index,
            footSwitch2.index
        ]
        .forEach {
            data.append(Byte($0))
        }
        return data
    }
    
    public var dataLength: Int { 4 }
}

// MARK: - CustomStringConvertible

extension AssignableController: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(source), destination=\(destination), depth=\(depth)"
        return s
    }
}

extension EffectControl.Source: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(source), destination=\(destination), depth=\(depth)"
        return s
    }
}

extension EffectControl: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Source1: \(source1)\n"
        s += "Source2: \(source2)\n"
        return s
    }
}

extension MacroController: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "destination1=\(destination1), depth1=\(depth1)\n"
        s += "destination2=\(destination2), depth1=\(depth2)\n"
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

extension ControlSource: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .bender:
            result = "Bender"
        case .channelPressure:
            result = "Channel Pressure"
        case .wheel:
            result = "Wheel"
        case .expression:
            result = "Expression"
        case .midiVolume:
            result = "MIDI Volume"
        case .panPot:
            result = "Pan Pot"
        case .generalController1:
            result = "General Controller 1"
        case .generalController2:
            result = "General Controller 2"
        case .generalController3:
            result = "General Controller 3"
        case .generalController4:
            result = "General Controller 4"
        case .generalController5:
            result = "General Controller 5"
        case .generalController6:
            result = "General Controller 6"
        case .generalController7:
            result = "General Controller 7"
        case .generalController8:
            result = "General Controller 8"
        }
        return result
    }
}

extension ControlDestination: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .pitchOffset:
            result = "Pitch Offset"
        case .cutoffOffset:
            result = "Cutoff Offset"
        case .level:
            result = "Level"
        case .vibratoDepthOffset:
            result = "Vibrato Depth Offset"
        case .growlDepthOffset:
            result = "Growl Depth Offset"
        case .tremoloDepthOffset:
            result = "Tremolo Depth Offset"
        case .lfoSpeedOffset:
            result = "LFO Speed Offset"
        case .attackTimeOffset:
            result = "Attack Time Offset"
        case .decay1TimeOffset:
            result = "Decay 1 Time Offset"
        case .releaseTimeOffset:
            result = "Release Time Offset"
        case .velocityOffset:
            result = "Velocity Offset"
        case .resonanceOffset:
            result = "Resonance Offset"
        case .panPotOffset:
            result = "Pan Pot Offset"
        case .formantFilterBiasOffset:
            result = "Formant Filter Bias Offset"
        case .formantFilterEnvelopeLfoDepthOffset:
            result = "Formant Filter Envelope LFO Depth Offset"
        case .formantFilterEnvelopeLfoSpeedOffset:
            result = "Formant Filter Envelope LFO Speed Offset"
        case .harmonicLowOffset:
            result = "Harmonic Low Offset"
        case .harmonicHighOffset:
            result = "Harmonic High Offset"
        case .harmonicEvenOffset:
            result = "Harmonic Even Offset"
        case .harmonicOddOffset:
            result = "Harmonic Odd Offset"
        }
        return result
    }
}

extension EffectDestination: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .effect1DryWet:
            result = "Effect 1 Dry/Wet"
        case .effect1Parameter:
            result = "Effect 1 Parameter"
        case .effect2DryWet:
            result = "Effect 2 Dry/Wet"
        case .effect2Parameter:
            result = "Effect 2 Parameter"
        case .effect3DryWet:
            result = "Effect 3 Dry/Wet"
        case .effect3Parameter:
            result = "Effect 3 Parameter"
        case .effect4DryWet:
            result = "Effect 4 Dry/Wet"
        case .effect4Parameter:
            result = "Effect 4 Parameter"
        case .reverbDryWet1:
            result = "Reverb Dry/Wet 1"
        case .reverbDryWet2:
            result = "Reverb Dry/Wet 2"
        }
        return result
    }
}

extension SwitchControl.Kind: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .off:
            result = "OFF"
        case .harmMax:
            result = "HARMMAX"
        case .harmBright:
            result = "HARMBRIT"
        case .harmDark:
            result = "HARMDARK"
        case .harmSaw:
            result = "HARMSAW"
        case .selectLoud:
            result = "SELECTLOUD"
        case .addLoud:
            result = "DHL LOUD"
        case .addFifth:
            result = "DHL 5TH"
        case .addOdd:
            result = "DHL ODD"
        case .addEven:
            result = "DHL EVEN"
        case .he1:
            result = "DHE#1"
        case .he2:
            result = "DHE#2"
        case .harmonicEnvelopeLoop:
            result = "DHE LOOP ON"
        case .ffMax:
            result = "DHF MAX"
        case .ffComb:
            result = "DHF COMB"
        case .ffHiCut:
            result = "DHF HICUT"
        case .ffComb2:
            result = "DHF COMB2"
        }
        return result
    }
}
