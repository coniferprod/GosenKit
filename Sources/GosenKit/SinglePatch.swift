import Foundation

public enum PolyphonyType: String, Codable, CaseIterable {
    case poly
    case solo1
    case solo2
    
    public init?(index: Int) {
        switch index {
        case 0: self = .poly
        case 1: self = .solo1
        case 2: self = .solo2
        default: return nil
        }
    }
}

public enum AmplitudeModulationType: String, Codable, CaseIterable {
    case off
    case source2
    case source3
    case source4
    case source5
    case source6

    public init?(index: Int) {
        switch index {
        case 0: self = .off
        case 1: self = .source2
        case 2: self = .source3
        case 3: self = .source4
        case 4: self = .source5
        case 5: self = .source6
        default: return nil
        }
    }
}

/// The common settings for a single patch.
public struct SingleCommon: Codable {
    public var name: String
    public var volume: Int
    public var polyphony: PolyphonyType
    public var sourceCount: Int
    public var sourceMutes: [Bool]
    public var isPortamentoActive: Bool
    public var portamentoSpeed: Int
    public var amplitudeModulation: AmplitudeModulationType
    public var macros: [MacroController]
    public var switches: SwitchControl
    public var effects: EffectSettings
    public var geq: [Int]  // 58(-6) ~ 70(+6), so 64 is zero
    public var effectControl: EffectControlSettings
    
    static let sourceCountOffset = 50
    static let geqBandCount = 7
    static let nameLength = 8
    static let macroCount = 4
    
    static let dataSize = 82
    
    /// Initializes the common part with default values.
    public init() {
        name = "NewSound"
        volume = 115
        polyphony = .poly
        sourceCount = 2
        sourceMutes = [true, true, false, false, false, false]
        isPortamentoActive = false
        portamentoSpeed = 0
        amplitudeModulation = .off
        macros = [MacroController]()
        macros.append(MacroController())
        macros.append(MacroController())
        macros.append(MacroController())
        macros.append(MacroController())
        switches = SwitchControl(switch1: .off, switch2: .off, footSwitch1: .off, footSwitch2: .off)
        effects = EffectSettings()
        geq = [ 2, 1, 0, 0, -1, -2, 1 ]
        effectControl = EffectControlSettings()
    }
    
    /// Initializes the common part of a single patch from MIDI System Exclusive data.
    /// - Parameter d: A byte array with the System Exclusive data.
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        let checksum = d.next(&offset)
        
        //print("Original checksum = \(String(checksum, radix: 16))")
        
        effects = EffectSettings(data: ByteArray(d[offset ..< offset + EffectSettings.dataLength]))
        offset += EffectSettings.dataLength

        geq = [Int]()
        for i in 0..<SingleCommon.geqBandCount {
            b = d.next(&offset)
            let v: Int = Int(b) - 64  // 58(-6) ~ 70(+6), so 64 is zero
            //print("GEQ band \(i + 1): \(b) --> \(v)")
            geq.append(Int(v))
        }
        
        // Eat the drum mark (39)
        offset += 1
        
        //print("Start name, offset = \(offset)")

        name = String(data: Data(d.slice(from: offset, length: SingleCommon.nameLength)), encoding: .ascii) ?? "--------"
        offset += SingleCommon.nameLength
        
        b = d.next(&offset)
        volume = Int(b)
        
        b = d.next(&offset)
        polyphony = PolyphonyType(index: Int(b))!

        // Eat the "no use" byte (50)
        offset += 1
        
        b = d.next(&offset)
        sourceCount = Int(b)
        
        //print("Start source mutes, offset = \(offset)")

        b = d.next(&offset)
        // Unpack the source mutes into a Bool array. Spec says "0:mute".
        sourceMutes = [Bool]()
        sourceMutes.append(b.isBitSet(0) ? false : true)
        sourceMutes.append(b.isBitSet(1) ? false : true)
        sourceMutes.append(b.isBitSet(2) ? false : true)
        sourceMutes.append(b.isBitSet(3) ? false : true)
        sourceMutes.append(b.isBitSet(4) ? false : true)
        sourceMutes.append(b.isBitSet(5) ? false : true)

        b = d.next(&offset)
        amplitudeModulation = AmplitudeModulationType(index: Int(b))!

        effectControl = EffectControlSettings(data: ByteArray(d[offset ..< offset + EffectControlSettings.dataLength]))
        offset += EffectControlSettings.dataLength

        b = d.next(&offset)
        isPortamentoActive = (b == 1) ? true : false
        
        b = d.next(&offset)
        portamentoSpeed = Int(b)

        //print("Start macros, offset = \(offset)")
        
        var macroDestinations = [Int]()
        for _ in 0..<8 {
            b = d.next(&offset)
            macroDestinations.append(Int(b))
        }
        
        var macroDepths = [Int]()
        for _ in 0..<8 {
            b = d.next(&offset)
            macroDepths.append(Int(b) - 64)
        }

        macros = [MacroController]()
        for i in stride(from: 0, to: 8, by: 2) {
            macros.append(MacroController(
                destination1: ControlDestination(index: macroDestinations[i])!,
                depth1: macroDepths[i + 1],
                destination2: ControlDestination(index: macroDestinations[i])!,
                depth2: macroDepths[i + 1]))
        }
        
        //print("Start switches, offset = \(offset)")
        
        b = d.next(&offset)
        let sw1t = SwitchType(index: Int(b))!

        b = d.next(&offset)
        let sw2t = SwitchType(index: Int(b))!
        
        b = d.next(&offset)
        let fsw1t = SwitchType(index: Int(b))!
        
        b = d.next(&offset)
        let fsw2t = SwitchType(index: Int(b))!

        switches = SwitchControl(switch1: sw1t, switch2: sw2t, footSwitch1: fsw1t, footSwitch2: fsw2t)
    }
    
    /// Gets the common part as MIDI System Exclusive data.
    /// - Returns: A byte array with the common part data.
    func asData() -> ByteArray {
        var data = ByteArray()
        
        // The MIDI System Exclusive specification determines the order and format.
        
        data.append(contentsOf: self.effects.asData())
        
        geq.forEach { data.append(Byte($0 + 64)) } // 58(-6)~70(+6)
        
        data.append(0)  // drum_mark

        // TODO: Ensure that name contains only ASCII characters
        
        //print("patch name = '\(name)'")
        let nameBuffer: ByteArray = Array(name.utf8)
        data.append(contentsOf: nameBuffer)

        // Pad name to exactly eight characters with spaces
        var nameIndex = name.count
        while nameIndex < 8 {
            data.append(0x20)
            nameIndex += 1
        }

        [volume, polyphony.index!, 0, sourceCount].forEach {
            data.append(Byte($0))
        }
        
        var mute: Byte = 0x00
        for (index, element) in sourceMutes.enumerated() {
            if !element {
                mute.setBit(index)
            }
        }
        data.append(mute)  // src_mute_1
        
        data.append(Byte(amplitudeModulation.index!))
        data.append(contentsOf: effectControl.asData())
        data.append(isPortamentoActive ? 1 : 0)
        data.append(Byte(portamentoSpeed))
        
        // Pick out the destinations and depths as the SysEx spec wants them.
        assert(macros.count == SingleCommon.macroCount)
        for macro in macros {
            data.append(Byte(macro.destination1.index!))
            data.append(Byte(macro.destination2.index!))
        }

        for macro in macros {
            data.append(Byte(macro.depth1 + 64))  // -31(33)~+31(95)
            data.append(Byte(macro.depth2 + 64))  // -31(33)~+31(95)
        }
        
        data.append(contentsOf: switches.asData())
        
        return data
    }
}

extension SingleCommon: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Name = '\(name)' Volume = \(volume) Polyphony = \(polyphony.rawValue)\n"
        let portamentoStatus = isPortamentoActive ? "ON" : "OFF"
        s += "Portamento = \(portamentoStatus), speed = \(portamentoSpeed)\n"
        s += "AM = \(amplitudeModulation.rawValue)\n"
        s += "\(effects)\n"
        
        s += "GEQ: "
        for band in geq {
            s += "\(band) "
        }
        s += "\n"
        
        s += "\(effectControl)"
        
        for (index, element) in macros.enumerated() {
            s += "User \(index + 1):\n\(element)\n"
        }
        
        s += "Switch1=\(switches.switch1.rawValue)\n"
        s += "Switch2=\(switches.switch2.rawValue)\n"
        s += "FootSwitch1=\(switches.footSwitch1.rawValue)\n"
        s += "FootSwitch2=\(switches.footSwitch2.rawValue)\n"

        s += "\n"
        return s
    }
}

// Additive kits keyed by source ("s1": ... etc.)
public typealias AdditiveKitDictionary = [String: AdditiveKit]

/// A Kawai K5000 single patch.
public struct SinglePatch: Codable {
    public var common: SingleCommon
    public var sources: [Source]
    public var additiveKits: AdditiveKitDictionary
    
    static let maxSourceCount = 6

    /// Initializes a single patch.
    public init() {
        common = SingleCommon()
        sources = [Source]()
        sources.append(Source())
        sources.append(Source())
        
        // The default sources are PCM, so the additive kit dictionary is empty
        additiveKits = AdditiveKitDictionary()
    }
    
    /// Initializes a single patch from MIDI System Exclusive data.
    /// - Parameter d: A byte array with the System Exclusive data.
    public init(data d: ByteArray) {
        var offset: Int = 0
        
        common = SingleCommon(data: d)
        offset += SingleCommon.dataSize
        
        sources = [Source]()
        for _ in 0..<common.sourceCount {
            let source = Source(data: d.slice(from: offset, length: Source.dataLength))
            sources.append(source)
            offset += Source.dataLength
        }
        
        additiveKits = AdditiveKitDictionary()
        
        // How many additive kits should we expect then?
        let additiveKitCount = sources.filter{ $0.oscillator.waveType == .additive }.count
        var kitIndex = 0
        while kitIndex < additiveKitCount {
            let kit = AdditiveKit(data: d.slice(from: offset, length: AdditiveKit.dataLength))
            offset += AdditiveKit.dataLength

            additiveKits["s\(kitIndex + 1)"] = kit
            kitIndex += 1
        }
        
        //print("Got \(additiveKits.count) ADD kits")
    }
    
    /// Gets the single patch as MIDI System Exclusive data.
    /// Collects and arranges the data for the various components of the patch.
    /// - Returns: A byte array with the patch data, without the System Exclusive header.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(checksum)

        let commonData = common.asData()
        data.append(contentsOf: commonData)

        for (_, source) in sources.enumerated() {
            let sourceData = source.asData()
            data.append(contentsOf: sourceData)
        }
        
        // Sort the additive kits by source
        let sortedKits = additiveKits.sorted(by: { $0.0 < $1.0 })
        
        for kit in sortedKits {
            let kitData = kit.1.asData()
            data.append(contentsOf: kitData)
        }
        
        return data
    }
    
    public func asSystemExclusiveMessage(channel: Byte, bank: String) -> ByteArray {
        var data = ByteArray()
        
        var header = SystemExclusiveHeader(
            manufacturerIdentifier: 0x40,
            channel: channel,
            function: SystemExclusiveFunction.oneBlockDump.rawValue,
            group: 0x00,
            machineIdentifier: 0x0a,
            substatus1: 0x00, substatus2: 0x00)

        switch bank {
        case "a":
            header.substatus2 = 0x00
        case "d":
            header.substatus2 = 0x02
        case "e":
            header.substatus2 = 0x03
        case "f":
            header.substatus2 = 0x04
        default:
            header.substatus2 = 0x00
        }

        data.append(contentsOf: header.asData())
        data.append(contentsOf: self.asData())
        data.append(SystemExclusiveHeader.terminator)
        
        return data
    }
    
    /// Computes the checksum for this patch.
    public var checksum: Byte {
        // Bank A,D,E,F: check sum = {(common sum) + (source1 sum) [+ (source2~6 sum)] + 0xa5} & 0x7f
        
        var totalSum: Int = 0
        var byteCount = 0
        
        let commonData = common.asData()
        var commonSum: Int = 0
        for d in commonData {
            commonSum += Int(d) & 0xff
            byteCount += 1
        }
        //print("checksum: added common data (\(commonData.count) bytes), total = \(byteCount)")
        
        totalSum += commonSum & 0xff
        
        for (_, source) in sources.enumerated() {
            var sourceSum: Int = 0
            let sourceData = source.asData()
            for d in sourceData {
                sourceSum += Int(d) & 0xff
                byteCount += 1
            }
            //print("checksum: added source \(index + 1) data (\(sourceData.count) bytes), total = \(byteCount)")

            totalSum += sourceSum & 0xff
            //print("checksum: total sum is now \(totalSum)")
        }
        
        totalSum += 0xA5
        //print("checksum: final total sum = \(totalSum)")
        
        let result = Byte(totalSum & 0x7F)
        //print("checksum: result = 0x\(String(result, radix: 16))")

        return result
    }
}

// MARK: - CustomStringConvertible

extension SinglePatch: CustomStringConvertible {
    /// Provides a printable description for this patch.
    public var description: String {
        var s = ""
        
        s += "\(common)\n"
        for (index, element) in sources.enumerated() {
            let sourceNumber = index + 1
            s += "SOURCE \(sourceNumber):\n\(element)\n"
        }
        
        s += "ADD Wave Kits:\n"
        // Sort the additive kits by source
        let kits = additiveKits.sorted(by: { $0.0 < $1.0 })
        
        for kit in kits {
            let kitData = kit.1.asData()
            s += "ADD kit: \(kitData.count) bytes\n"
            s += "\(kit.1)"
        }
        
        return s
    }
}
