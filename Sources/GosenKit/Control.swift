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
        
        b = d[offset]
        destination1 = ControlDestination(index: Int(b))!
        offset += 1

        b = d[offset]
        depth1 = Int(b) - 64
        //print("depth1 byte = \(String(b, radix: 16))h, converted to \(depth1)")
        offset += 1
        
        b = d[offset]
        destination2 = ControlDestination(index: Int(b))!
        offset += 1

        b = d[offset]
        depth2 = Int(b) - 64
        //print("depth2 byte = \(String(b, radix: 16))h, converted to \(depth2)")
        offset += 1
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
     
        data.append(Byte(destination1.index!))
        data.append(Byte(depth1 + 64))  // -31(33)~+31(95)
        data.append(Byte(destination2.index!))
        data.append(Byte(depth2 + 64))  // -31(33)~+31(95)

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

public enum SwitchType: String, Codable, CaseIterable {
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

public struct SwitchControl: Codable {
    public var switch1: SwitchType
    public var switch2: SwitchType
    public var footSwitch1: SwitchType
    public var footSwitch2: SwitchType
    
    public func asData() -> ByteArray {
        var data = ByteArray()
     
        data.append(Byte(switch1.index!))
        data.append(Byte(switch2.index!))
        data.append(Byte(footSwitch1.index!))
        data.append(Byte(footSwitch2.index!))

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

public struct EffectControlSourceSettings: Codable {
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
    
        b = d[offset]
        sourceType = ControlSource(index: Int(b))!
        offset += 1
        
        b = d[offset]
        destinationType = EffectDestinationType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        depth = Int(b) - 64
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
     
        data.append(Byte(sourceType.index!))
        data.append(Byte(destinationType.index!))
        data.append(Byte(depth + 64))
        
        return data
    }
}

extension EffectControlSourceSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(sourceType.rawValue), destination=\(destinationType.rawValue), depth=\(depth)"
        return s
    }
}

public struct EffectControlSettings: Codable {
    public var source1: EffectControlSourceSettings
    public var source2: EffectControlSourceSettings
    
    static let dataLength = 6
    
    public init() {
        source1 = EffectControlSourceSettings()
        source2 = EffectControlSourceSettings()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
    
        source1 = EffectControlSourceSettings(data: ByteArray(d[offset ..< offset + EffectControlSourceSettings.dataLength]))
        offset += EffectControlSourceSettings.dataLength
        source2 = EffectControlSourceSettings(data: ByteArray(d[offset ..< offset + EffectControlSourceSettings.dataLength]))
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
    
        data.append(contentsOf: source1.asData())
        data.append(contentsOf: source2.asData())
    
        return data
    }
}

extension EffectControlSettings: CustomStringConvertible {
    public var description: String {
        var s = "Effect Control:\n"
        s += "    Source1: \(source1)\n"
        s += "    Source2: \(source2)\n"
        return s
    }
}

public struct AssignableController: Codable {
    public var sourceType: ControlSource
    public var destination: ControlDestination
    public var depth: Int
    
    static let dataLength = 3
    
    public init() {
        sourceType = .bender
        destination = .cutoffOffset
        depth = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        sourceType = ControlSource(index: Int(b))!
        offset += 1
        
        b = d[offset]
        destination = ControlDestination(index: Int(b))!
        offset += 1
        
        b = d[offset]
        depth = Int(b)
        offset += 1
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()

        data.append(Byte(sourceType.index!))
        data.append(Byte(destination.index!))
        data.append(Byte(depth))

        return data
    }
}

extension AssignableController: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "source=\(sourceType.rawValue), destination=\(destination.rawValue), depth=\(depth)"
        return s
    }
}

public struct ModulationSettings: Codable {
    public var pressure: MacroController
    public var wheel: MacroController
    public var expression: MacroController
    public var assignable1: AssignableController
    public var assignable2: AssignableController
    
    static let dataLength = 18
    
    public init() {
        pressure = MacroController()
        wheel = MacroController()
        expression = MacroController()
        assignable1 = AssignableController()
        assignable2 = AssignableController()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0

        let pressureData = d[offset ..< offset + MacroController.dataLength]
        //print("pressure data = \(pressureData.hexDump)")
        pressure = MacroController(data: ByteArray(pressureData))
        offset += MacroController.dataLength

        let wheelData = d[offset ..< offset + MacroController.dataLength]
        //print("wheel data = \(wheelData.hexDump)")
        wheel = MacroController(data: ByteArray(wheelData))
        offset += MacroController.dataLength
        
        let expressionData = d[offset ..< offset + MacroController.dataLength]
        expression = MacroController(data: ByteArray(expressionData))
        offset += MacroController.dataLength
    
        assignable1 = AssignableController(data: ByteArray(d[offset ..< offset + AssignableController.dataLength]))
        offset += AssignableController.dataLength
        
        assignable2 = AssignableController(data: ByteArray(d[offset ..< offset + AssignableController.dataLength]))
        offset += AssignableController.dataLength
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: pressure.asData())
        data.append(contentsOf: wheel.asData())
        data.append(contentsOf: expression.asData())
        data.append(contentsOf: assignable1.asData())
        data.append(contentsOf: assignable2.asData())
        
        return data
    }
}

extension ModulationSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "pressure: \(pressure), wheel: \(wheel), expression: \(expression), assignable1: \(assignable1), assignable2: \(assignable2)"
        return s
    }
}

public enum PanType: String, Codable, CaseIterable {
    case normal
    case random
    case keyScale
    case negativeKeyScale
    
    public init?(index: Int) {
        switch index {
        case 0: self = .normal
        case 1: self = .random
        case 2: self = .keyScale
        case 3: self = .negativeKeyScale
        default: return nil
        }
    }
}

public struct PanSettings: Codable {
    public var panType: PanType
    public var panValue: Int
    
    static let dataLength = 2
    
    public init(panType: PanType, panValue: Int) {
        self.panType = panType
        self.panValue = panValue        
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        panType = PanType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        panValue = Int(b) - 64
    }

    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(panType.index!))
        data.append(Byte(panValue + 64))
        
        return data
    }
}

extension PanSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "type=\(panType.rawValue), value=\(panValue)"
        return s
    }
}
