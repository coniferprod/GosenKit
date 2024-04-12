import Foundation

import SyxPack
import ByteKit


/// Represents a source in a singe patch.
public struct Source {
    /// Represents the control settings of a source.
    public struct Control {
        /// Macro and assignable controller settings.
        public struct Modulation {
            public var pressure: MacroController
            public var wheel: MacroController
            public var expression: MacroController
            public var assignable1: AssignableController
            public var assignable2: AssignableController
            
            /// Initializes default modulation settings.
            public init() {
                pressure = MacroController()
                wheel = MacroController()
                expression = MacroController()
                assignable1 = AssignableController()
                assignable2 = AssignableController()
            }
            
            public static func parse(from data: ByteArray) -> Result<Modulation, ParseError> {
                var offset: Int = 0

                var temp = Modulation()  // initialize with defaults, then fill in
                
                var size = MacroController.dataSize
                switch MacroController.parse(from: data.slice(from: offset, length: size)) {
                case .success(let mc):
                    temp.pressure = mc
                case .failure(let error):
                    return .failure(error)
                }
                offset += size

                switch MacroController.parse(from: data.slice(from: offset, length: size)) {
                case .success(let mc):
                    temp.wheel = mc
                case .failure(let error):
                    return .failure(error)
                }
                offset += size
                
                switch MacroController.parse(from: data.slice(from: offset, length: size)) {
                case .success(let mc):
                    temp.expression = mc
                case .failure(let error):
                    return .failure(error)
                }
                offset += size
            
                size = AssignableController.dataSize
                switch AssignableController.parse(from: data.slice(from: offset, length: size)) {
                case .success(let ac):
                    temp.assignable1 = ac
                case .failure(let error):
                    return .failure(error)
                }
                offset += size
                
                switch AssignableController.parse(from: data.slice(from: offset, length: size)) {
                case .success(let ac):
                    temp.assignable2 = ac
                case .failure(let error):
                    return .failure(error)
                }
                offset += size

                return .success(temp)
            }
        }

        /// Pan settings.
        public struct PanSettings {
            /// Pan kind.
            public enum Kind: Byte, Codable, CaseIterable {
                case normal = 0
                case keyScaling = 1
                case negativeKeyScaling = 2
                case random = 3

                /// Initializes the pan kind from a data byte.
                public init?(index: Int) {
                    switch index {
                    case 0: self = .normal
                    case 1: self = .keyScaling
                    case 2: self = .negativeKeyScaling
                    case 3: self = .random
                    default: return nil
                    }
                }
            }
            
            public var kind: Kind
            public var value: Pan  // only when kind=.normal
            
            /// Initializes default pan settings.
            public init() {
                self.kind = .normal
                self.value = 0
            }
            
            /// Initializes pan settings from kind and value.
            public init(kind: Kind, value: Pan) {
                self.kind = kind
                self.value = value
            }
            
            public static func parse(from data: ByteArray) -> Result<PanSettings, ParseError> {
                var offset: Int = 0
                var b: Byte = 0

                var temp = PanSettings()
                
                b = data.next(&offset)
                temp.kind = Kind(index: Int(b))!
                
                b = data.next(&offset)
                temp.value = Pan(Int(b) - 64)
                
                return .success(temp)
            }
        }

        public var zone: Zone
        
        public var velocitySwitch: VelocitySwitch
        public var effectPath: EffectPath
        public var volume: Volume
        public var benderPitch: BenderPitch
        public var benderCutoff: BenderCutoff
        public var modulation: Modulation
        public var keyOnDelay: Level
        public var pan: PanSettings
        
        /// Initializes default control settings.
        public init() {
            zone = Zone(low: Key(note: 0), high: Key(note: 127))
            velocitySwitch = VelocitySwitch(kind: .off, threshold: 4)
            effectPath = 1
            volume = 120
            benderPitch = 0
            benderCutoff = 0
            modulation = Modulation()
            keyOnDelay = 0
            pan = PanSettings(kind: .normal, value: Pan(0))
        }
        
        public static func parse(from data: ByteArray) -> Result<Control, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = Control()
            
            b = data.next(&offset)
            let zoneLow = Key(note: MIDINote(Int(b)))
            b = data.next(&offset)
            let zoneHigh = Key(note: MIDINote(Int(b)))
            temp.zone = Zone(low: zoneLow, high: zoneHigh)
            
            b = data.next(&offset)
            switch VelocitySwitch.parse(from: [b]) {
            case .success(let vs):
                temp.velocitySwitch = vs
            case .failure(let error):
                return .failure(error)
            }
            
            b = data.next(&offset)
            temp.effectPath = EffectPath(Int(b))
            
            b = data.next(&offset)
            temp.volume = Volume(Int(b))
            
            b = data.next(&offset)
            temp.benderPitch = BenderPitch(Int(b) - 12)  // adjust 0...24 to -12...+12
            
            b = data.next(&offset)
            temp.benderCutoff = BenderCutoff(Int(b))
            
            var size = Modulation.dataSize
            switch Modulation.parse(from: data.slice(from: offset, length: size)) {
            case .success(let modulation):
                temp.modulation = modulation
            case .failure(let error):
                return .failure(error)
            }
            offset += size
            
            size = PanSettings.dataSize
            b = data.next(&offset)
            temp.keyOnDelay = Level(Int(b))
            
            switch PanSettings.parse(from: data.slice(from: offset, length: size)) {
            case .success(let pan):
                temp.pan = pan
            case .failure(let error):
                return .failure(error)
            }
            
            return .success(temp)
        }
    }

    public var oscillator: Oscillator
    public var filter: Filter
    public var amplifier: Amplifier
    public var lfo: LFO
    public var control: Control

    /// Initializes a source with default settings.
    public init() {
        oscillator = Oscillator()
        filter = Filter()
        amplifier = Amplifier()
        lfo = LFO()
        control = Control()
    }
    
    public static func parse(from data: ByteArray) -> Result<Source, ParseError> {
        var offset: Int = 0

        var temp = Source()
        
        var size = Control.dataSize
        switch Control.parse(from: data.slice(from: offset, length: size)) {
        case .success(let control):
            temp.control = control
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = Oscillator.dataSize
        switch Oscillator.parse(from: data.slice(from: offset, length: size)) {
        case .success(let osc):
            temp.oscillator = osc
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = Filter.dataSize
        switch Filter.parse(from: data.slice(from: offset, length: size)) {
        case .success(let filter):
            temp.filter = filter
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        size = Amplifier.dataSize
        switch Amplifier.parse(from: data.slice(from: offset, length: size)) {
        case .success(let amp):
            temp.amplifier = amp
        case .failure(let error):
            return .failure(error)
        }
        offset += size
 
        size = LFO.dataSize
        switch LFO.parse(from: data.slice(from: offset, length: size)) {
        case .success(let lfo):
            temp.lfo = lfo
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Source.Control.Modulation: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: pressure.asData())
        data.append(contentsOf: wheel.asData())
        data.append(contentsOf: expression.asData())
        data.append(contentsOf: assignable1.asData())
        data.append(contentsOf: assignable2.asData())
        
        return data
    }
    
    public var dataLength: Int { Source.Control.Modulation.dataSize }
    
    public static let dataSize = 18
}

extension Source.Control.PanSettings: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(kind.index))
        data.append(Byte(value.value + 64))
        
        return data
    }

    public var dataLength: Int { Source.Control.PanSettings.dataSize }

    public static let dataSize = 2
}

extension Source.Control: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(zone.low.note.value))
        data.append(Byte(zone.high.note.value))
        data.append(contentsOf: velocitySwitch.asData())
        data.append(Byte(effectPath.value - 1))  // adjust to 0~3
        data.append(Byte(volume.value))
        data.append(Byte(benderPitch.value + 12))  // adjust -12...+12 to 0...24
        data.append(Byte(benderCutoff.value))
        data.append(contentsOf: modulation.asData())
        data.append(Byte(keyOnDelay.value))
        data.append(contentsOf: pan.asData())

        return data
    }

    public var dataLength: Int { Source.Control.dataSize }

    public static let dataSize = 28
}

extension Source: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: control.asData())
        data.append(contentsOf: oscillator.asData())
        data.append(contentsOf: filter.asData())
        data.append(contentsOf: amplifier.asData())
        data.append(contentsOf: lfo.asData())

        return data
    }
    
    public var dataLength: Int { Source.dataSize }
    
    public static let dataSize = 86
}

// MARK: - CustomStringConvertible

extension Source: CustomStringConvertible {
    public var description: String {
        var s = ""
        
        s += "Control:\n\(control)\n"
        s += "Oscillator:\n\(oscillator)\n"
        s += "Filter:\n\(filter)\n"
        s += "Amplifier:\n\(amplifier)\n"
        s += "LFO:\n\(lfo)\n"

        /*
        if self.oscillator.waveType == .additive {
            s += "Additive Kit:\n"
            s += "Harmonics:\n\(harmonics)\n"
        }
        */
        
        return s
    }
}

extension Source.Control: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Zone = \(zone.low.name) ... \(zone.high.name)\n"
        s += "Velocity Switch: \(velocitySwitch)\n"
        s += "Effect Path = \(effectPath.value)\n"
        s += "Volume = \(volume.value)\n"
        s += "Bender: pitch = \(benderPitch.value), cutoff = \(benderCutoff.value)\n"
        s += "Modulation:\n\(modulation)\n"
        s += "Key On Delay = \(keyOnDelay)\n"
        s += "Pan Settings: \(pan)\n"
        return s
    }
}

extension Source.Control.Modulation: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "pressure: \(pressure), wheel: \(wheel), expression: \(expression), assignable1: \(assignable1), assignable2: \(assignable2)"
        return s
    }
}

extension Source.Control.PanSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "kind=\(kind), value=\(value.value)"
        return s
    }
}

extension Source.Control.PanSettings.Kind: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .normal:
            result = "Normal"
        case .keyScaling:
            result = "Key Scale"
        case .negativeKeyScaling:
            result = "Negative Key Scale"
        case .random:
            result = "Random"
        }
        return result
    }
}
