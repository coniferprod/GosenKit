import Foundation

import SyxPack


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
                
                switch MacroController.parse(from: data.slice(from: offset, length: MacroController.dataSize)) {
                case .success(let mc):
                    temp.pressure = mc
                case .failure(let error):
                    return .failure(error)
                }
                offset += MacroController.dataSize

                switch MacroController.parse(from: data.slice(from: offset, length: MacroController.dataSize)) {
                case .success(let mc):
                    temp.wheel = mc
                case .failure(let error):
                    return .failure(error)
                }
                offset += MacroController.dataSize
                
                switch MacroController.parse(from: data.slice(from: offset, length: MacroController.dataSize)) {
                case .success(let mc):
                    temp.expression = mc
                case .failure(let error):
                    return .failure(error)
                }
                offset += MacroController.dataSize
            
                switch AssignableController.parse(from: data.slice(from: offset, length: AssignableController.dataSize)) {
                case .success(let ac):
                    temp.assignable1 = ac
                case .failure(let error):
                    return .failure(error)
                }
                offset += AssignableController.dataSize
                
                switch AssignableController.parse(from: data.slice(from: offset, length: AssignableController.dataSize)) {
                case .success(let ac):
                    temp.assignable2 = ac
                case .failure(let error):
                    return .failure(error)
                }
                offset += AssignableController.dataSize

                return .success(temp)
            }
        }

        /// Pan settings.
        public struct Pan: Codable {
            /// Pan kind.
            public enum Kind: String, Codable, CaseIterable {
                case normal
                case random
                case keyScale
                case negativeKeyScale
                
                /// Initializes the pan kind from a data byte.
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

            public var kind: Kind
            public var value: Int
            
            /// Initializes default pan settings.
            public init() {
                self.kind = .normal
                self.value = 0
            }
            
            /// Initializes pan settings from kind and value.
            public init(kind: Kind, value: Int) {
                self.kind = kind
                self.value = value
            }
            
            /// Initializes pan settings from MIDI System Exclusive data.
            public init(data d: ByteArray) {
                var offset: Int = 0
                var b: Byte = 0
                
                b = d.next(&offset)
                kind = Kind(index: Int(b))!
                
                b = d.next(&offset)
                value = Int(b) - 64
            }
            
            public static func parse(from data: ByteArray) -> Result<Pan, ParseError> {
                var offset: Int = 0
                var b: Byte = 0

                var temp = Pan()
                
                b = data.next(&offset)
                temp.kind = Kind(index: Int(b))!
                
                b = data.next(&offset)
                temp.value = Int(b) - 64
                
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
        public var pan: Pan
        
        /// Initializes default control settings.
        public init() {
            zone = Zone(high: Key(note: 127), low: Key(note: 0))
            velocitySwitch = VelocitySwitch(kind: .off, threshold: 4)
            effectPath = 0
            volume = 120
            benderPitch = 0
            benderCutoff = 0
            modulation = Modulation()
            keyOnDelay = 0
            pan = Pan(kind: .normal, value: 0)
        }
        
        public static func parse(from data: ByteArray) -> Result<Control, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = Control()
            
            b = data.next(&offset)
            let zoneLow = Key(note: Int(b))
            b = data.next(&offset)
            let zoneHigh = Key(note: Int(b))
            temp.zone = Zone(high: zoneHigh, low: zoneLow)
            
            b = data.next(&offset)
            switch VelocitySwitch.parse(from: [b]) {
            case .success(let vs):
                temp.velocitySwitch = vs
            case .failure(let error):
                return .failure(error)
            }
            
            b = data.next(&offset)
            temp.effectPath = Int(b)
            
            b = data.next(&offset)
            temp.volume = Int(b)
            
            b = data.next(&offset)
            temp.benderPitch = Int(b)
            
            b = data.next(&offset)
            temp.benderCutoff = Int(b)
            
            switch Modulation.parse(from: data.slice(from: offset, length: Modulation.dataSize)) {
            case .success(let modulation):
                temp.modulation = modulation
            case .failure(let error):
                return .failure(error)
            }
            offset += Modulation.dataSize
            
            b = data.next(&offset)
            temp.keyOnDelay = Int(b)
            
            switch Pan.parse(from: data.slice(from: offset, length: Pan.dataSize)) {
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
        
        switch Control.parse(from: data.slice(from: offset, length: Control.dataSize)) {
        case .success(let control):
            temp.control = control
        case .failure(let error):
            return .failure(error)
        }
        offset += Control.dataSize
        
        switch Oscillator.parse(from: data.slice(from: offset, length: Oscillator.dataSize)) {
        case .success(let osc):
            temp.oscillator = osc
        case .failure(let error):
            return .failure(error)
        }
        offset += Oscillator.dataSize
        
        switch Filter.parse(from: data.slice(from: offset, length: Filter.dataSize)) {
        case .success(let filter):
            temp.filter = filter
        case .failure(let error):
            return .failure(error)
        }
        offset += Filter.dataSize

        switch Amplifier.parse(from: data.slice(from: offset, length: Amplifier.dataSize)) {
        case .success(let amp):
            temp.amplifier = amp
        case .failure(let error):
            return .failure(error)
        }
        offset += Amplifier.dataSize
 
        switch LFO.parse(from: data.slice(from: offset, length: LFO.dataSize)) {
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
    
    public var dataLength: Int { return Source.Control.Modulation.dataSize }
    
    public static let dataSize = 18
}

extension Source.Control.Pan: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(kind.index))
        data.append(Byte(value + 64))
        
        return data
    }

    public var dataLength: Int { return Source.Control.Pan.dataSize }

    public static let dataSize = 2
}

extension Source.Control: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(zone.low.note))
        data.append(Byte(zone.high.note))
        data.append(contentsOf: velocitySwitch.asData())
        data.append(Byte(effectPath))
        data.append(Byte(volume))
        data.append(Byte(benderPitch))
        data.append(Byte(benderCutoff))
        data.append(contentsOf: modulation.asData())
        data.append(Byte(keyOnDelay))
        data.append(contentsOf: pan.asData())

        return data
    }

    public var dataLength: Int { return Source.Control.dataSize }

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
    
    public var dataLength: Int { return Source.dataSize }
    
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
        s += "Effect Path = \(effectPath)\n"
        s += "Volume = \(volume)\n"
        s += "Bender: pitch = \(benderPitch), cutoff = \(benderCutoff)\n"
        s += "Modulation = \(modulation)\n"
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

extension Source.Control.Pan: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "kind=\(kind), value=\(value)"
        return s
    }
}

extension Source.Control.Pan.Kind: CustomStringConvertible {
    public var description: String {
        var result = ""
        switch self {
        case .normal:
            result = "Normal"
        case .random:
            result = "Random"
        case .keyScale:
            result = "Key Scale"
        case .negativeKeyScale:
            result = "Negative Key Scale"
        }
        return result
    }
}
