import Foundation

import SyxPack


public struct Source: Codable {
    public struct Control: Codable {
        public struct Modulation: Codable {
            public var pressure: MacroController
            public var wheel: MacroController
            public var expression: MacroController
            public var assignable1: AssignableController
            public var assignable2: AssignableController
            
            public init() {
                pressure = MacroController()
                wheel = MacroController()
                expression = MacroController()
                assignable1 = AssignableController()
                assignable2 = AssignableController()
            }
            
            public init(data d: ByteArray) {
                var offset: Int = 0

                pressure = MacroController(data: d.slice(from: offset, length: MacroController.dataSize))
                offset += MacroController.dataSize

                wheel = MacroController(data: d.slice(from: offset, length: MacroController.dataSize))
                offset += MacroController.dataSize
                
                expression = MacroController(data: d.slice(from: offset, length: MacroController.dataSize))
                offset += MacroController.dataSize
            
                assignable1 = AssignableController(data: d.slice(from: offset, length: AssignableController.dataSize))
                offset += AssignableController.dataSize
                
                assignable2 = AssignableController(data: d.slice(from: offset, length: AssignableController.dataSize))
                offset += AssignableController.dataSize
            }
        }

        public struct Pan: Codable {
            public enum Kind: String, Codable, CaseIterable {
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

            public var kind: Kind
            public var value: Int
            
            public init(kind: Kind, value: Int) {
                self.kind = kind
                self.value = value
            }
            
            public init(data d: ByteArray) {
                var offset: Int = 0
                var b: Byte = 0
                
                b = d.next(&offset)
                kind = Kind(index: Int(b))!
                
                b = d.next(&offset)
                value = Int(b) - 64
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
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            //print("Source SysEx data = \(d.hexDump)")
            
            b = d.next(&offset)
            let zoneLow = Key(note: Int(b))
            b = d.next(&offset)
            let zoneHigh = Key(note: Int(b))
            zone = Zone(high: zoneHigh, low: zoneLow)
            
            b = d.next(&offset)
            velocitySwitch = VelocitySwitch(data: [b])
            
            b = d.next(&offset)
            effectPath = Int(b)
            
            b = d.next(&offset)
            volume = Int(b)
            
            b = d.next(&offset)
            benderPitch = Int(b)
            
            b = d.next(&offset)
            benderCutoff = Int(b)
            
            modulation = Modulation(data: d.slice(from: offset, length: Modulation.dataSize))
            offset += Modulation.dataSize
            
            b = d.next(&offset)
            keyOnDelay = Int(b)
            
            pan = Pan(data: d.slice(from: offset, length: Pan.dataSize))
        }
    }

    public var oscillator: Oscillator
    public var filter: Filter
    public var amplifier: Amplifier
    public var lfo: LFO
    public var control: Control

    public init() {
        oscillator = Oscillator()
        filter = Filter()
        amplifier = Amplifier()
        lfo = LFO()
        control = Control()
    }
    
    /// Initializes a source from system exclusive data.
    public init(data d: ByteArray) {
        var offset: Int = 0
        
        //print("SOURCE: Start Control, offset = \(offset)")
        control = Control(data: d.slice(from: offset, length: Control.dataSize))
        offset += Control.dataSize
        
        //print("SOURCE: Start DCO, offset = \(offset)")
        oscillator = Oscillator(data: d.slice(from: offset, length: Oscillator.dataSize))
        offset += Oscillator.dataSize
        
        //print("SOURCE: Start DCF, offset = \(offset)")
        filter = Filter(data: d.slice(from: offset, length: Filter.dataSize))
        offset += Filter.dataSize

        //print("SOURCE: Start DCA, offset = \(offset)")
        amplifier = Amplifier(data: d.slice(from: offset, length: Amplifier.dataSize))
        offset += Amplifier.dataSize
        
        //print("SOURCE: Start LFO, offset = \(offset)")
        lfo = LFO(data: d.slice(from: offset, length: LFO.dataSize))
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
        s += "Bender Pitch = \(benderPitch), Bender Cutoff = \(benderCutoff)\n"
        s += "Modulation:\n\(modulation)\n"
        s += "Key On Delay = \(keyOnDelay)\n"
        s += "Pan Settings:\n\(pan)\n"
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
        s += "kind=\(kind.rawValue), value=\(value)"
        return s
    }
}
