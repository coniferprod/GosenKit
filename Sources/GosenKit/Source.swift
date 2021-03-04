import Foundation

public enum VelocitySwitchType: String, Codable, CaseIterable {
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

// On the synth, the threshold value goes from 4 to 127 in steps of four! (last step is from 124 to 127)
// So as the SysEx spec says, the value of 0 means 4, 1 means 8, and so on... and 31 means 127.
// I guess that 30 must mean 124 then. So the actual value in the SysEx should be 0...31, but it should be
// translated on input from 0...31 to 4...127, and on output from 4...127 to 0...31 again.
public struct VelocitySwitchSettings: Codable {
    public var switchType: VelocitySwitchType
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
    
    public init(switchType: VelocitySwitchType, threshold: Int) {
        self.switchType = switchType
        self.threshold = VelocitySwitchSettings.conversionTable[threshold]
    }
    
    public init(fromSystemExclusive d: Data) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d[offset]
        let vs = Int(b >> 5)   // bits 5-6
        switchType = VelocitySwitchType(index: vs)!
        let n = Int(b & 0b00011111)   // bits 0-4
        threshold = VelocitySwitchSettings.conversionTable[n]
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        let t = VelocitySwitchSettings.conversionTable.firstIndex(of: threshold)!
        let value = t | (self.switchType.index! << 5)
        //print("velocity switch = \(self.velocitySwitchType.rawValue), velocityThreshold = \(self.velocityThreshold) --> velo_sw = \(String(value, radix: 2))")
        data.append(Byte(value))
        return data
    }
}

extension VelocitySwitchSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "\(switchType.rawValue), threshold=\(threshold)"
        return s
    }
}

public struct SourceControlSettings: Codable {
    public var zoneLow: Int
    public var zoneHigh: Int   // TODO: make a MIDI note type
    public var velocitySwitch: VelocitySwitchSettings
    public var effectPath: Int
    public var volume: Int
    public var benderPitch: Int
    public var benderCutoff: Int
    public var modulations: ModulationSettings
    public var keyOnDelay: Int
    public var pan: PanSettings
    
    static let dataLength = 28
    
    public init() {
        zoneLow = 0
        zoneHigh = 127
        velocitySwitch = VelocitySwitchSettings(switchType: .off, threshold: 4)
        effectPath = 0
        volume = 120
        benderPitch = 0
        benderCutoff = 0
        modulations = ModulationSettings()
        keyOnDelay = 0
        pan = PanSettings(panType: .normal, panValue: 0)
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        //print("Source SysEx data = \(d.hexDump)")
        
        b = d[offset]
        zoneLow = Int(b)
        offset += 1
        
        b = d[offset]
        zoneHigh = Int(b)
        offset += 1
        
        b = d[offset]
        velocitySwitch = VelocitySwitchSettings(fromSystemExclusive: Data([b]))
        offset += 1
        
        b = d[offset]
        effectPath = Int(b)
        offset += 1
        
        b = d[offset]
        volume = Int(b)
        offset += 1
        
        b = d[offset]
        benderPitch = Int(b)
        offset += 1
        
        b = d[offset]
        benderCutoff = Int(b)
        offset += 1
        
        modulations = ModulationSettings(data: ByteArray(d[offset ..< offset + ModulationSettings.dataLength]))
        offset += ModulationSettings.dataLength
        
        b = d[offset]
        keyOnDelay = Int(b)
        offset += 1
        
        pan = PanSettings(data: ByteArray(d[offset ..< offset + PanSettings.dataLength]))
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
        data.append(contentsOf: modulations.asData())
        data.append(Byte(keyOnDelay))
        data.append(contentsOf: pan.asData())

        return data
    }
}

extension SourceControlSettings: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "ZoneLow=\(zoneLow) ZoneHigh=\(zoneHigh)\n"
        s += "Velocity Switch: \(velocitySwitch)\n"
        s += "Effect Path = \(effectPath)\n"
        s += "Volume = \(volume)\n"
        s += "Bender Pitch = \(benderPitch), Bender Cutoff = \(benderCutoff)\n"
        s += "Modulations:\n\(modulations)\n"
        s += "Key On Delay = \(keyOnDelay)\n"
        s += "Pan Settings:\n\(pan)\n"
        return s
    }
}

public struct Source: Codable {
    public var oscillator: Oscillator
    public var filter: Filter
    public var amplifier: Amplifier
    public var lfo: LFO
    public var control: SourceControlSettings

    static let dataLength = 86
    
    public init() {
        oscillator = Oscillator()
        filter = Filter()
        amplifier = Amplifier()
        lfo = LFO()
        control = SourceControlSettings()
    }
    
    /// Initializes a source from system exclusive data.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        print("SOURCE: Start Control, offset = \(offset)")
        control = SourceControlSettings(data: ByteArray(d[offset ..< offset + SourceControlSettings.dataLength]))
        offset += SourceControlSettings.dataLength
        
        print("SOURCE: Start DCO, offset = \(offset)")
        oscillator = Oscillator(data: ByteArray(d[offset ..< offset + Oscillator.dataLength]))
        offset += Oscillator.dataLength
        
        print("SOURCE: Start DCF, offset = \(offset)")
        filter = Filter(data: ByteArray(d[offset ..< offset + Filter.dataLength]))
        offset += Filter.dataLength

        print("SOURCE: Start DCA, offset = \(offset)")
        amplifier = Amplifier(data: ByteArray(d[offset ..< offset + Amplifier.dataLength]))
        offset += Amplifier.dataLength
        
        print("SOURCE: Start LFO, offset = \(offset)")
        lfo = LFO(data: ByteArray(d[offset ..< offset + LFO.dataLength]))
        offset += LFO.dataLength
        
        // Don't emit the harmonics here; all the additive kits come after the tone data
        //harmonics = HarmonicSettings(fromSystemExclusive: d.suffix(from: offset))
    }

    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: control.asData())
        data.append(contentsOf: oscillator.asData())
        data.append(contentsOf: filter.asData())
        data.append(contentsOf: amplifier.asData())
        data.append(contentsOf: lfo.asData())

        //data.append(contentsOf: harmonics.asData())  // includes checksum
        //data.append(0) // dummy
        
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
