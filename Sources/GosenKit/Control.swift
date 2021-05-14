import Foundation

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
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        [destination1.index!, depth1 + 64, destination2.index!, depth2 + 64].forEach {
            data.append(Byte($0))
        }
        return data
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
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        [switch1.index!, switch2.index!, footSwitch1.index!, footSwitch2.index!].forEach {
            data.append(Byte($0))
        }
        return data
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

public enum EffectDestinationType: String, Codable, CaseIterable {
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

public struct EffectControlSource: Codable {
    public var sourceType: ControlSource
    public var destinationType: EffectDestinationType
    public var depth: Int
    
    static let dataLength = 3
    
    public init() {
        sourceType = .bender
        destinationType = .reverbDryWet1
        depth = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d.next(&offset)
        sourceType = ControlSource(index: Int(b))!
        
        b = d.next(&offset)
        destinationType = EffectDestinationType(index: Int(b))!
        
        b = d.next(&offset)
        depth = Int(b) - 64
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        [sourceType.index!, destinationType.index!, depth + 64].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

extension EffectControlSource: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(sourceType.rawValue), destination=\(destinationType.rawValue), depth=\(depth)"
        return s
    }
}

public struct EffectControl: Codable {
    public var source1: EffectControlSource
    public var source2: EffectControlSource
    
    static let dataLength = 6
    
    public init() {
        source1 = EffectControlSource()
        source2 = EffectControlSource()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
    
        let length = EffectControlSource.dataLength
        source1 = EffectControlSource(data: d.slice(from: offset, length: length))
        offset += length
        source2 = EffectControlSource(data: d.slice(from: offset, length: length))
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
    
        data.append(contentsOf: source1.asData())
        data.append(contentsOf: source2.asData())
    
        return data
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
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        [source.index!, destination.index!, depth].forEach {
            data.append(Byte($0))
        }
        return data
    }
}

extension AssignableController: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(source.rawValue), destination=\(destination.rawValue), depth=\(depth)"
        return s
    }
}
