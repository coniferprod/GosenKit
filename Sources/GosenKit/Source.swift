import Foundation

public struct Source: Codable {
    public struct Control: Codable {
        public struct Modulation: Codable {
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

                pressure = MacroController(data: d.slice(from: offset, length: MacroController.dataLength))
                offset += MacroController.dataLength

                wheel = MacroController(data: d.slice(from: offset, length: MacroController.dataLength))
                offset += MacroController.dataLength
                
                expression = MacroController(data: d.slice(from: offset, length: MacroController.dataLength))
                offset += MacroController.dataLength
            
                assignable1 = AssignableController(data: d.slice(from: offset, length: AssignableController.dataLength))
                offset += AssignableController.dataLength
                
                assignable2 = AssignableController(data: d.slice(from: offset, length: AssignableController.dataLength))
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

        // On the synth, the threshold value goes from 4 to 127 in steps of four! (last step is from 124 to 127)
        // So as the SysEx spec says, the value of 0 means 4, 1 means 8, and so on... and 31 means 127.
        // I guess that 30 must mean 124 then. So the actual value in the SysEx should be 0...31, but it should be
        // translated on input from 0...31 to 4...127, and on output from 4...127 to 0...31 again.
        public struct VelocitySwitch: Codable {
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
            
            public func asData() -> ByteArray {
                var data = ByteArray()
                let t = VelocitySwitch.conversionTable.firstIndex(of: threshold)!
                let value = t | (self.kind.index! << 5)
                //print("velocity switch = \(self.velocitySwitchType.rawValue), velocityThreshold = \(self.velocityThreshold) --> velo_sw = \(String(value, radix: 2))")
                data.append(Byte(value))
                return data
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
            
            static let dataLength = 2
            
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

            public func asData() -> ByteArray {
                var data = ByteArray()
                
                data.append(Byte(kind.index!))
                data.append(Byte(value + 64))
                
                return data
            }
        }

        public var zoneLow: Int
        public var zoneHigh: Int   // TODO: make a MIDI note type
        public var velocitySwitch: VelocitySwitch
        public var effectPath: Int
        public var volume: Int
        public var benderPitch: Int
        public var benderCutoff: Int
        public var modulation: Modulation
        public var keyOnDelay: Int
        public var pan: Pan
        
        static let dataLength = 28
        
        public init() {
            zoneLow = 0
            zoneHigh = 127
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
            zoneLow = Int(b)
            
            b = d.next(&offset)
            zoneHigh = Int(b)
            
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
            
            modulation = Modulation(data: d.slice(from: offset, length: Modulation.dataLength))
            offset += Modulation.dataLength
            
            b = d.next(&offset)
            keyOnDelay = Int(b)
            
            pan = Pan(data: d.slice(from: offset, length: Pan.dataLength))
        }
        
        public func asData() -> ByteArray {
            var data = ByteArray()
            
            data.append(Byte(zoneLow))
            data.append(Byte(zoneHigh))
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
    }

    public var oscillator: Oscillator
    public var filter: Filter
    public var amplifier: Amplifier
    public var lfo: LFO
    public var control: Control

    static let dataLength = 86
    
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
        
        print("SOURCE: Start Control, offset = \(offset)")
        control = Control(data: d.slice(from: offset, length: Control.dataLength))
        offset += Control.dataLength
        
        print("SOURCE: Start DCO, offset = \(offset)")
        oscillator = Oscillator(data: d.slice(from: offset, length:Oscillator.dataLength))
        offset += Oscillator.dataLength
        
        print("SOURCE: Start DCF, offset = \(offset)")
        filter = Filter(data: d.slice(from: offset, length: Filter.dataLength))
        offset += Filter.dataLength

        print("SOURCE: Start DCA, offset = \(offset)")
        amplifier = Amplifier(data: d.slice(from: offset, length: Amplifier.dataLength))
        offset += Amplifier.dataLength
        
        print("SOURCE: Start LFO, offset = \(offset)")
        lfo = LFO(data: d.slice(from: offset, length: LFO.dataLength))
    }

    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: control.asData())
        data.append(contentsOf: oscillator.asData())
        data.append(contentsOf: filter.asData())
        data.append(contentsOf: amplifier.asData())
        data.append(contentsOf: lfo.asData())

        return data
    }
}

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
        s += "ZoneLow=\(zoneLow) ZoneHigh=\(zoneHigh)\n"
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

extension Source.Control.VelocitySwitch: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "\(kind.rawValue), threshold=\(threshold)"
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

