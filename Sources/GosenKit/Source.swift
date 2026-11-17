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
            
            /// Initialize the modulation with default settings.
            public init() {
                self.pressure = MacroController()
                self.wheel = MacroController()
                self.expression = MacroController()
                self.assignable1 = AssignableController()
                self.assignable2 = AssignableController()
            }
            
            /// Parse this modulation from MIDI System Exclusive data.
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
            public var value: Int  // only when kind=.normal
            
            /// Initializes pan settings from kind and value.
            public init(kind: Kind = .normal, value: Int = 0) {
                self.kind = kind
                self.value = value
            }
            
            /// Parse the pan settings from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<PanSettings, ParseError> {
                var offset: Int = 0
                var b: Byte = 0

                var temp = PanSettings()
                
                b = data.next(&offset)
                temp.kind = Kind(index: Int(b))!
                
                b = data.next(&offset)
                temp.value = Int(b) + descriptors[.pan]!.incomingOffset
                
                return .success(temp)
            }
        }

        public var zone: Zone
        
        public var velocitySwitch: VelocitySwitch
        public var effectPath: Int
        public var volume: Int
        public var benderPitch: Int
        public var benderCutoff: Int
        public var modulation: Modulation
        public var keyOnDelay: Int
        public var pan: PanSettings
        
        /// Initializes default control settings.
        public init() {
            self.zone = Zone(low: Key(note: 0), high: Key(note: 127))
            self.velocitySwitch = VelocitySwitch(kind: .off, threshold: 4)
            self.effectPath = 1
            self.volume = 120
            self.benderPitch = 0
            self.benderCutoff = 0
            self.modulation = Modulation()
            self.keyOnDelay = 0
            self.pan = PanSettings(kind: .normal, value: 0)
        }
        
        /// Parse the control settings from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Control, ParseError> {
            var offset: Int = 0
            var b: Byte = 0     // last byte read (will be reused)
            
            var temp = Control()
            
            b = data.next(&offset)
            let zoneLow = Key(note: Int(b))
            b = data.next(&offset)
            let zoneHigh = Key(note: Int(b))
            temp.zone = Zone(low: zoneLow, high: zoneHigh)
            
            b = data.next(&offset)
            switch VelocitySwitch.parse(from: [b]) {
            case .success(let vs):
                temp.velocitySwitch = vs
            case .failure(let error):
                return .failure(error)
            }
            
            b = data.next(&offset)
            temp.effectPath = Int(b) + descriptors[.effectPath]!.incomingOffset
            
            b = data.next(&offset)
            temp.volume = Int(b)
                        
            b = data.next(&offset)
            temp.benderPitch = Int(b) + descriptors[.benderPitch]!.incomingOffset
            
            b = data.next(&offset)
            temp.benderCutoff = Int(b)
            
            let size = Modulation.dataSize
            switch Modulation.parse(from: data.slice(from: offset, length: size)) {
            case .success(let modulation):
                temp.modulation = modulation
            case .failure(let error):
                return .failure(error)
            }
            offset += size
            
            b = data.next(&offset)
            temp.keyOnDelay = Int(b)
            
            switch PanSettings.parse(from: data.slice(from: offset, length: PanSettings.dataSize)) {
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
        self.oscillator = Oscillator()
        self.filter = Filter()
        self.amplifier = Amplifier()
        self.lfo = LFO()
        self.control = Control()
    }
    
    /// Parse the source from MIDI System Exclusive data.
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

// MARK: - SystemExclusiveData protocol conformance

extension Source.Control.Modulation: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this source control modulation.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.pressure.asData())
        data.append(contentsOf: self.wheel.asData())
        data.append(contentsOf: self.expression.asData())
        data.append(contentsOf: self.assignable1.asData())
        data.append(contentsOf: self.assignable2.asData())
        
        return data
    }
    
    public var dataLength: Int { Source.Control.Modulation.dataSize }
    
    public static let dataSize = 18
}

extension Source.Control.PanSettings: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for the source control pan settings.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(self.kind.index))
        data.append(Byte(self.value + descriptors[.pan]!.outgoingOffset))
        
        return data
    }

    public var dataLength: Int { Source.Control.PanSettings.dataSize }

    public static let dataSize = 2
}

extension Source.Control: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this source control.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(self.zone.low.note))
        data.append(Byte(self.zone.high.note))
        data.append(contentsOf: self.velocitySwitch.asData())
        data.append(Byte(self.effectPath + descriptors[.effectPath]!.outgoingOffset))  // adjust to 0~3
        data.append(Byte(self.volume))
        data.append(Byte(self.benderPitch + descriptors[.benderPitch]!.outgoingOffset))  // adjust -12...+12 to 0...24
        data.append(Byte(self.benderCutoff))
        data.append(contentsOf: self.modulation.asData())
        data.append(Byte(self.keyOnDelay))
        data.append(contentsOf: self.pan.asData())

        return data
    }

    public var dataLength: Int { Source.Control.dataSize }

    public static let dataSize = 28
}

extension Source: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this source.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.control.asData())
        data.append(contentsOf: self.oscillator.asData())
        data.append(contentsOf: self.filter.asData())
        data.append(contentsOf: self.amplifier.asData())
        data.append(contentsOf: self.lfo.asData())

        return data
    }
    
    public var dataLength: Int { Source.dataSize }
    
    public static let dataSize = 86
}

// MARK: - CustomStringConvertible protocol conformance

extension Source: CustomStringConvertible {
    public var description: String {
        var s = ""
        
        s += "Control:\n\(self.control)\n"
        s += "Oscillator:\n\(self.oscillator)\n"
        s += "Filter:\n\(self.filter)\n"
        s += "Amplifier:\n\(self.amplifier)\n"
        s += "LFO:\n\(self.lfo)\n"

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
        s += "Zone = \(self.zone.low.name) ... \(self.zone.high.name)\n"
        s += "Velocity Switch: \(self.velocitySwitch)\n"
        s += "Effect Path = \(self.effectPath)\n"
        s += "Volume = \(self.volume)\n"
        s += "Bender: pitch = \(self.benderPitch), cutoff = \(self.benderCutoff)\n"
        s += "Modulation:\n\(self.modulation)\n"
        s += "Key On Delay = \(self.keyOnDelay)\n"
        s += "Pan Settings: \(self.pan)\n"
        return s
    }
}

extension Source.Control.Modulation: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "pressure: \(self.pressure)\n"
        s += "wheel: \(self.wheel)\n"
        s += "expression: \(self.expression)\n"
        s += "assignable1: \(self.assignable1)\n"
        s += "assignable2: \(self.assignable2)"
        return s
    }
}

extension Source.Control.PanSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "kind=\(self.kind), value=\(self.value)"
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

// MARK: - XML output

extension Source.Control: XMLRepresentable {
    public var xml: String {
        return ""
    }
}

extension Source.Control.Modulation: XMLRepresentable {
    public var xml: String {
"""
<control>
    <pressure>\(self.pressure.xml)</pressure>
    <wheel>\(self.wheel.xml)</wheel>
    <expression>\(self.expression.xml)</expression>

</control>
"""
    }
}

extension Source: XMLRepresentable {
    public var xml: String {
"""
<source>
    <oscillator>\(self.oscillator.xml)</oscillator>
    <filter>\(self.filter.xml)</filter>
    <amplifier>\(self.amplifier.xml)</amplifier>
    <lfo>***TODO: LFO***</lfo>
    <control>\(self.control.xml)</control>
</source>
"""
    }
}
