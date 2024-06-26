import Foundation

import SyxPack
import ByteKit


/// Additive kits keyed by source ("s1": ... etc.)
public typealias AdditiveKitDictionary = [String: AdditiveKit]

/// A Kawai K5000 single patch.
public struct SinglePatch {
    
    /// Polyphony mode.
    public enum Polyphony: String, CaseIterable {
        case poly
        case solo1
        case solo2
        
        /// Initializes a polyphony mode from data.
        public init?(index: Int) {
            switch index {
            case 0: self = .poly
            case 1: self = .solo1
            case 2: self = .solo2
            default: return nil
            }
        }
    }

    /// Amplitude modulation.
    public enum AmplitudeModulation: String, CaseIterable {
        case off
        case source2
        case source3
        case source4
        case source5
        case source6

        /// Initializes an amplitude modulation setting from data.
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

    /// Portamento setting.
    public enum Portamento {
        case off
        case on(speed: Level)
    }
    
    /// Single patch common settings.
    public struct Common {
        public var name: PatchName
        public var volume: Volume
        public var polyphony: Polyphony
        public var sourceCount: Int
        public var sourceMutes: [Bool]
        public var portamento: Portamento
        public var amplitudeModulation: AmplitudeModulation
        public var macros: [MacroController]
        public var switches: SwitchControl
        public var effects: EffectSettings
        public var geq: GEQ
        public var effectControl: EffectControl
        
        static let sourceCountOffset = 50
        static let macroCount = 4
        
        /// Initializes the common part with default values.
        public init() {
            name = PatchName("NewSound")
            volume = 115  // conforms to ExpressibleByIntegerLiteral
            polyphony = .poly
            
            sourceCount = 2
            sourceMutes = [true, true, false, false, false, false]
            
            portamento = .off
            amplitudeModulation = .off
            
            macros = [MacroController]()
            macros.append(MacroController())
            macros.append(MacroController())
            macros.append(MacroController())
            macros.append(MacroController())
            
            switches = SwitchControl(switch1: .off, switch2: .off, footSwitch1: .off, footSwitch2: .off)
            effects = EffectSettings()
            geq = GEQ(levels: [2, 1, 0, 0, -1, -2, 1])
            effectControl = EffectControl()
        }
        
        /// Parse from binary data.
        public static func parse(from data: ByteArray) -> Result<Common, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = Common()  // initialize with defaults, then fill in
            
            var size = EffectSettings.dataSize
            let effectData = data.slice(from: offset, length: size)
            switch EffectSettings.parse(from: effectData) {
            case .success(let effects):
                temp.effects = effects
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            size = GEQ.bandCount
            switch GEQ.parse(from: data.slice(from: offset, length: size)) {
            case .success(let geq):
                temp.geq = geq
            case .failure(let error):
                return .failure(error)
            }
            offset += size
            
            // Eat the drum mark (39)
            offset += 1

            size = PatchName.length
            switch PatchName.parse(from: data.slice(from: offset, length: size)) {
            case .success(let name):
                temp.name = name
            case .failure(let error):
                return .failure(error)
            }
            offset += size
            
            b = data.next(&offset)
            temp.volume = Volume(Int(b))
            
            b = data.next(&offset)
            temp.polyphony = Polyphony(index: Int(b))!

            // Eat the "no use" byte (50)
            offset += 1
            
            b = data.next(&offset)
            temp.sourceCount = Int(b)
            
            b = data.next(&offset)
            
            // Unpack the source mutes into a Bool array. Spec says "0:mute, bit 0~5 = source 1~6".
            temp.sourceMutes = [
                !(b.isBitSet(0)),
                !(b.isBitSet(1)),
                !(b.isBitSet(2)),
                !(b.isBitSet(3)),
                !(b.isBitSet(4)),
                !(b.isBitSet(5)),
            ]

            b = data.next(&offset)
            temp.amplitudeModulation = AmplitudeModulation(index: Int(b))!

            size = EffectControl.dataSize
            switch EffectControl.parse(from: data.slice(from: offset, length: size)) {
            case .success(let control):
                temp.effectControl = control
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            b = data.next(&offset)
            let isPortamentoActive = (b == 1)
            
            b = data.next(&offset)
            let portamentoSpeed = Int(b)

            temp.portamento = isPortamentoActive ? .on(speed: Level(portamentoSpeed)) : .off
            
            var macroDestinations = [Int]()
            for _ in 0..<8 {
                b = data.next(&offset)
                macroDestinations.append(Int(b))
            }
            
            var macroDepths = [Int]()
            for _ in 0..<8 {
                b = data.next(&offset)
                macroDepths.append(Int(b) - 64)
            }

            temp.macros = [MacroController]()
            for i in stride(from: 0, to: 8, by: 2) {
                temp.macros.append(MacroController(
                    destination1: ControlDestination(index: macroDestinations[i])!,
                    depth1: macroDepths[i + 1],
                    destination2: ControlDestination(index: macroDestinations[i])!,
                    depth2: macroDepths[i + 1]))
            }
            
            b = data.next(&offset)
            let sw1t = SwitchControl.Kind(index: Int(b))!

            b = data.next(&offset)
            let sw2t = SwitchControl.Kind(index: Int(b))!
            
            b = data.next(&offset)
            let fsw1t = SwitchControl.Kind(index: Int(b))!
            
            b = data.next(&offset)
            let fsw2t = SwitchControl.Kind(index: Int(b))!

            temp.switches = SwitchControl(switch1: sw1t, switch2: sw2t, footSwitch1: fsw1t, footSwitch2: fsw2t)

            return .success(temp)
        }
    }

    public var common: Common
    public var sources: [Source]
    public var additiveKits: AdditiveKitDictionary
    
    public static let maxSourceCount = 6

    /// Initializes a single patch.
    public init() {
        common = Common()
        sources = [Source]()
        
        // Single patches always have at least two sources
        sources.append(Source())
        sources.append(Source())
        
        // The default sources are PCM, so the additive kit dictionary is empty
        additiveKits = AdditiveKitDictionary()
    }
    
    /// Parse the SinglePatch from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<SinglePatch, ParseError> {
        var offset: Int = 0
        
        _ = data.next(&offset)  // checksum is the first byte

        var temp = SinglePatch()  // initialize with defaults, then fill in
        
        var size = Common.dataSize
        switch Common.parse(from: data.slice(from: offset, length: size)) {
        case .success(let common):
            temp.common = common
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = Source.dataSize
        temp.sources.removeAll()  // empty the source list first!
        for _ in 0..<temp.common.sourceCount {
            switch Source.parse(from: data.slice(from: offset, length: size)) {
            case .success(let source):
                temp.sources.append(source)
            case .failure(let error):
                return .failure(error)
            }
            offset += size
        }
        
        temp.additiveKits = AdditiveKitDictionary()
        
        // How many additive kits should we expect then?
        let additiveKitCount = temp.sources.filter{ $0.oscillator.wave == .additive }.count
        var kitIndex = 0
        size = AdditiveKit.dataSize
        while kitIndex < additiveKitCount {
            switch AdditiveKit.parse(from: data.slice(from: offset, length: size)) {
            case .success(let kit):
                temp.additiveKits["s\(kitIndex + 1)"] = kit
                kitIndex += 1
                offset += size
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(temp)
    }
    
    /// Generates a MIDI System Exclusive message from this patch.
    /// - Parameter channel: the MIDI channel to use
    /// - Parameter bank: the K5000 bank identifier
    public func asSystemExclusiveMessage(channel: MIDIChannel, bank: BankIdentifier) -> ByteArray {
        var data = ByteArray()
        
        let header = SystemExclusive.Header(
            channel: channel,
            function: .oneBlockDump,
            substatus1: 0x00,
            substatus2: bank.rawValue)

        data.append(contentsOf: header.asData())
        data.append(contentsOf: self.asData())
        
        return data
    }
    
    /// The checksum for this patch.
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

// MARK: - SystemExclusiveData

extension SinglePatch: SystemExclusiveData {
    /// Gets the single patch as MIDI System Exclusive data.
    /// Collects and arranges the data for the various components of the patch.
    /// - Returns: A byte array with the patch data, without the System Exclusive header.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(checksum)

        let commonData = self.common.asData()
        data.append(contentsOf: commonData)

        for (_, source) in self.sources.enumerated() {
            let sourceData = source.asData()
            data.append(contentsOf: sourceData)
        }
        
        // Sort the additive kits by source
        let sortedKits = self.additiveKits.sorted(by: { $0.0 < $1.0 })
        
        for kit in sortedKits {
            let kitData = kit.1.asData()
            data.append(contentsOf: kitData)
        }
        
        return data
    }

    /// The length of single patch System Exclusive data.
    public var dataLength: Int {
        1 + Common.dataSize + self.sources.count * Source.dataSize
    }
}

extension SinglePatch.Common: SystemExclusiveData {
    /// Gets the common part as MIDI System Exclusive data.
    /// - Returns: A byte array with the common part data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        // The MIDI System Exclusive specification determines the order and format.
        
        data.append(contentsOf: effects.asData())
        data.append(contentsOf: geq.asData())
        data.append(0)  // drum_mark
        data.append(contentsOf: name.asData())

        [volume.value, polyphony.index, 0, sourceCount].forEach {
            data.append(Byte($0))
        }
        
        var mute: Byte = 0x00
        for (index, element) in sourceMutes.enumerated() {
            if !element {
                mute.setBit(index)
            }
        }
        data.append(mute)  // src_mute_1
        
        data.append(Byte(amplitudeModulation.index))
        data.append(contentsOf: effectControl.asData())
        
        switch portamento {
        case .on(let speed):
            data.append(1)
            data.append(Byte(speed.value))
        case .off:
            data.append(0)
            data.append(0)
        }
        
        // Pick out the destinations and depths as the SysEx spec wants them.
        assert(macros.count == SinglePatch.Common.macroCount)
        for macro in macros {
            data.append(Byte(macro.destination1.index))
            data.append(Byte(macro.destination2.index))
        }

        for macro in macros {
            data.append(Byte(macro.depth1.value + 64))  // -31(33)~+31(95)
            data.append(Byte(macro.depth2.value + 64))  // -31(33)~+31(95)
        }
        
        data.append(contentsOf: switches.asData())
        
        return data
    }

    /// The number of bytes in the single patch common data.
    public var dataLength: Int { SinglePatch.Common.dataSize }

    public static let dataSize = 81
}

// MARK: - CustomStringConvertible

extension SinglePatch: CustomStringConvertible {
    /// Printable description of this patch.
    public var description: String {
        var s = ""
        
        s += "\(self.common)\n"
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

extension SinglePatch.Common: CustomStringConvertible {
    /// Printable description of the patch common settings.
    public var description: String {
        var s = ""
        s += "Name = '\(name.value)' Volume = \(volume.value) Polyphony = \(polyphony)\n"
        
        s += "Portamento: "
        switch portamento {
        case .on(let speed):
            s += "ON, speed \(speed.value)"
        case .off:
            s += "OFF"
        }
        
        s += "\nAM = \(amplitudeModulation)\n"
        s += "\(effects)\n"
        
        s += "GEQ: "
        for band in geq.levels {
            s += "\(band.value) "
        }
        s += "\n"
        
        s += "Effect control:\n\(effectControl)\n"
        
        for (index, element) in macros.enumerated() {
            s += "User \(index + 1):\n\(element)\n"
        }
        
        s += "Switch1=\(switches.switch1)\n"
        s += "Switch2=\(switches.switch2)\n"
        s += "FootSwitch1=\(switches.footSwitch1)\n"
        s += "FootSwitch2=\(switches.footSwitch2)\n"

        s += "\n"
        return s
    }
}

extension SinglePatch.Polyphony: CustomStringConvertible {
    /// Printable description of the polyphony setting.
    public var description: String {
        self.rawValue.uppercased()
    }
}

extension SinglePatch.AmplitudeModulation: CustomStringConvertible {
    /// Printable description of the Amplitude Modulation setting.
    public var description: String {
        switch self {
        case .off:
            return "OFF"
        case .source2:
            return "1->2"
        case .source3:
            return "2->3"
        case .source4:
            return "3->4"
        case .source5:
            return "4->5"
        case .source6:
            return "5->6"
        }
    }
}
