import Foundation

enum PolyphonyType: String, Codable, CaseIterable {
    case poly
    case solo1
    case solo2
    
    init?(index: Int) {
        switch index {
        case 0: self = .poly
        case 1: self = .solo1
        case 2: self = .solo2
        default: return nil
        }
    }
}

enum AmplitudeModulationType: String, Codable, CaseIterable {
    case off
    case source2
    case source3
    case source4
    case source5
    case source6

    init?(index: Int) {
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

struct SingleCommon: Codable {
    var name: String
    var volume: Int
    var polyphony: PolyphonyType
    var sourceCount: Int
    var sourceMutes: [Bool]
    var isPortamentoActive: Bool
    var portamentoSpeed: Int
    var amplitudeModulation: AmplitudeModulationType
    var macros: [MacroController]
    var switches: SwitchControl
    var effects: EffectSettings
    var geq: [Int]  // 58(-6) ~ 70(+6), so 64 is zero
    var effectControl: EffectControlSettings
    
    static let sourceCountOffset = 50
    static let geqBandCount = 7
    static let nameLength = 8
    static let macroCount = 4
    
    static let dataSize = 82
    
    init() {
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
    
    /// Initializes a single patch from system exclusive data.
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        let checksum = d[offset]
        offset += 1
        
        print("Original checksum = \(String(checksum, radix: 16))")
        
        effects = EffectSettings(data: ByteArray(d[offset ..< offset + EffectSettings.dataLength]))
        offset += EffectSettings.dataLength

        geq = [Int]()
        for i in 0..<SingleCommon.geqBandCount {
            b = d[offset]
            let v: Int = Int(b) - 64  // 58(-6) ~ 70(+6), so 64 is zero
            //print("GEQ band \(i + 1): \(b) --> \(v)")
            geq.append(Int(v))
            offset += 1
        }
        
        // Eat the drum mark (39)
        offset += 1
        
        print("Start name, offset = \(offset)")

        name = String(data: Data(d[offset ..< offset + SingleCommon.nameLength]), encoding: .ascii) ?? "--------"
        offset += SingleCommon.nameLength
        
        volume = Int(d[offset])
        offset += 1
        
        b = d[offset]
        polyphony = PolyphonyType(index: Int(b))!
        offset += 1

        // Eat the "no use" byte (50)
        offset += 1
        
        b = d[offset]
        sourceCount = Int(b)
        offset += 1
        
        print("Start source mutes, offset = \(offset)")

        b = d[offset]
        // Unpack the source mutes into a Bool array. Spec says "0:mute".
        sourceMutes = [Bool]()
        sourceMutes.append(b.isBitSet(0) ? false : true)
        sourceMutes.append(b.isBitSet(1) ? false : true)
        sourceMutes.append(b.isBitSet(2) ? false : true)
        sourceMutes.append(b.isBitSet(3) ? false : true)
        sourceMutes.append(b.isBitSet(4) ? false : true)
        sourceMutes.append(b.isBitSet(5) ? false : true)
        offset += 1

        b = d[offset]
        amplitudeModulation = AmplitudeModulationType(index: Int(b))!
        offset += 1

        effectControl = EffectControlSettings(data: ByteArray(d[offset ..< offset + EffectControlSettings.dataLength]))
        offset += EffectControlSettings.dataLength

        b = d[offset]
        isPortamentoActive = (b == 1) ? true : false
        offset += 1
        
        b = d[offset]
        portamentoSpeed = Int(b)
        offset += 1

        print("Start macros, offset = \(offset)")
        
        var macroDestinations = [Int]()
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 0: Macro1 Destination1
        offset += 1
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 1: Macro1 Destination2
        offset += 1
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 2: Macro2 Destination1
        offset += 1
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 3: Macro2 Destination2
        offset += 1
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 4: Macro3 Destination1
        offset += 1
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 5: Macro3 Destination2
        offset += 1

        b = d[offset]
        macroDestinations.append(Int(b))  // 6: Macro4 Destination1
        offset += 1
        
        b = d[offset]
        macroDestinations.append(Int(b))  // 7: Macro4 Destination2
        offset += 1

        var macroDepths = [Int]()

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 0: Macro1 Depth1
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 1: Macro1 Depth2
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 2: Macro2 Depth1
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 3: Macro2 Depth2
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 4: Macro3 Depth1
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 5: Macro3 Depth2
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 6: Macro4 Depth1
        offset += 1

        b = d[offset]
        macroDepths.append(Int(b) - 64)  // 7: Macro4 Depth2
        offset += 1

        macros = [MacroController]()
        
        let macro1 = MacroController(
            destination1: ControlDestination(index: macroDestinations[0])!,
            depth1: macroDepths[0],
            destination2: ControlDestination(index: macroDestinations[1])!,
            depth2: macroDepths[1])
        macros.append(macro1)
        
        let macro2 = MacroController(
            destination1: ControlDestination(index: macroDestinations[2])!,
            depth1: macroDepths[2],
            destination2: ControlDestination(index: macroDestinations[3])!,
            depth2: macroDepths[3])
        macros.append(macro2)

        let macro3 = MacroController(
            destination1: ControlDestination(index: macroDestinations[4])!,
            depth1: macroDepths[4],
            destination2: ControlDestination(index: macroDestinations[5])!,
            depth2: macroDepths[5])
        macros.append(macro3)

        let macro4 = MacroController(
            destination1: ControlDestination(index: macroDestinations[6])!,
            depth1: macroDepths[6],
            destination2: ControlDestination(index: macroDestinations[7])!,
            depth2: macroDepths[7])
        macros.append(macro4)
        
        print("Start switches, offset = \(offset)")
        
        b = d[offset]
        let sw1t = SwitchType(index: Int(b))!
        offset += 1

        b = d[offset]
        let sw2t = SwitchType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        let fsw1t = SwitchType(index: Int(b))!
        offset += 1
        
        b = d[offset]
        let fsw2t = SwitchType(index: Int(b))!
        offset += 1

        switches = SwitchControl(switch1: sw1t, switch2: sw2t, footSwitch1: fsw1t, footSwitch2: fsw2t)
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        // The MIDI System Exclusive specification determines the order and format.
        
        data.append(contentsOf: self.effects.asData())
        
        for freq in geq {
            data.append(Byte(freq + 64))  // 58(-6)~70(+6)
        }
        
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

        data.append(Byte(volume))
        data.append(Byte(polyphony.index!))
        data.append(0) // no use
        
        data.append(Byte(sourceCount))
        
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
        // Surely this could be made much more elegant.
        data.append(Byte(macros[0].destination1.index!))
        data.append(Byte(macros[0].destination2.index!))

        data.append(Byte(macros[1].destination1.index!))
        data.append(Byte(macros[1].destination2.index!))

        data.append(Byte(macros[2].destination1.index!))
        data.append(Byte(macros[2].destination2.index!))

        data.append(Byte(macros[3].destination1.index!))
        data.append(Byte(macros[3].destination2.index!))

        data.append(Byte(macros[0].depth1 + 64))  // -31(33)~+31(95)
        data.append(Byte(macros[0].depth2 + 64))  // -31(33)~+31(95)

        data.append(Byte(macros[1].depth1 + 64))  // -31(33)~+31(95)
        data.append(Byte(macros[1].depth2 + 64))  // -31(33)~+31(95)

        data.append(Byte(macros[2].depth1 + 64))  // -31(33)~+31(95)
        data.append(Byte(macros[2].depth2 + 64))  // -31(33)~+31(95)

        data.append(Byte(macros[3].depth1 + 64))  // -31(33)~+31(95)
        data.append(Byte(macros[3].depth2 + 64))  // -31(33)~+31(95)
        
        data.append(contentsOf: switches.asData())
        
        return data
    }
}

extension SingleCommon: CustomStringConvertible {
    var description: String {
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
typealias AdditiveKitDictionary = [String: AdditiveKit]

public struct SinglePatch: Codable {
    var common: SingleCommon
    var sources: [Source]
    var additiveKits: AdditiveKitDictionary
    
    static let maxSourceCount = 6
    
    init() {
        common = SingleCommon()
        sources = [Source]()
        sources.append(Source())
        sources.append(Source())
        
        // The default sources are PCM, so the additive kit dictionary is empty
        additiveKits = AdditiveKitDictionary()
    }
    
    /// Initializes a single patch from system exclusive data.
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        common = SingleCommon(data: d)
        offset += SingleCommon.dataSize
        
        sources = [Source]()
        for _ in 0..<common.sourceCount {
            let source = Source(data: ByteArray(d[offset ..< offset + Source.dataLength]))
            sources.append(source)
            offset += Source.dataLength
        }
        
        additiveKits = AdditiveKitDictionary()
        
        // How many additive kits should we expect then?
        let additiveKitCount = sources.filter{ $0.oscillator.waveType == .additive }.count
        var kitIndex = 0
        while kitIndex < additiveKitCount {
            let kit = AdditiveKit(data: ByteArray(d[offset ..< offset + AdditiveKit.dataLength]))
            additiveKits["s\(kitIndex + 1)"] = kit
            kitIndex += 1
            offset += AdditiveKit.dataLength
        }
        
        print("Got \(additiveKits.count) ADD kits")
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        print("SINGLE PATCH DATA:")
        data.append(checksum)
        print("checksum = 0x\(String(checksum, radix: 16))")
        let commonData = common.asData()
        data.append(contentsOf: commonData)
        print("single patch: common: \(commonData.count) bytes")
        print(Data(commonData).hexDump)

        for (index, source) in sources.enumerated() {
            let sourceData = source.asData()
            data.append(contentsOf: sourceData)
            print("single patch: source \(index + 1): \(sourceData.count) bytes")
            print(Data(sourceData).hexDump)
        }
        
        // Sort the additive kits by source
        let sortedKits = additiveKits.sorted(by: { $0.0 < $1.0 })
        
        for kit in sortedKits {
            let kitData = kit.1.asData()
            print("single patch: ADD kit for \(kit.0.uppercased()): \(kitData.count) bytes")
            print(Data(kitData).hexDump)
            data.append(contentsOf: kitData)
        }
        
        return data
    }
    
    var checksum: Byte {
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
        
        for (index, source) in sources.enumerated() {
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
        print("checksum: result = 0x\(String(result, radix: 16))")

        return result
    }
}

extension SinglePatch: CustomStringConvertible {
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
