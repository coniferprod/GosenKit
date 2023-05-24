import Foundation

import SyxPack


/// A Kawai K5000 multi patch (combi on the K5000W).
public struct MultiPatch: Codable {
    public static let sectionCount = 4
    
    /// Common settings for multi patch.
    public struct Common: Codable {
        public static let geqBandCount = 7

        public var effects: EffectSettings
        public var geq: [Int]  // all 0...127
        public var name: PatchName
        public var volume: UInt
        public var sectionMutes: [Bool]
        public var effectControl1: EffectControl
        public var effectControl2: EffectControl

        /// Initialize common settings with defaults.
        public init() {
            effects = EffectSettings()
            geq = [Int](repeating: 0, count: Common.geqBandCount)
            name = PatchName("NewMulti")
            volume = 127
            sectionMutes = [Bool](repeating: false, count: MultiPatch.sectionCount)
            effectControl1 = EffectControl()
            effectControl2 = EffectControl()
        }
        
        public static func parse(from data: ByteArray) -> Result<Common, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = Common()  // initialize with defaults, then fill in
            
            let effectData = data.slice(from: offset, length: EffectSettings.dataSize)
            switch EffectSettings.parse(from: effectData) {
            case .success(let effects):
                temp.effects = effects
            case .failure(let error):
                return .failure(error)
            }
            offset += EffectSettings.dataSize
            
            temp.geq = [Int]()
            for _ in 0..<SinglePatch.Common.geqBandCount {
                b = data.next(&offset)
                let v: Int = Int(b) - 64  // 58(-6) ~ 70(+6), so 64 is zero
                //print("GEQ band \(i + 1): \(b) --> \(v)")
                temp.geq.append(Int(v))
            }
            offset += Common.geqBandCount
            
            temp.name = PatchName(data: data.slice(from: offset, length: PatchName.length))
            offset += PatchName.length

            b = data.next(&offset)
            temp.volume = UInt(b)

            b = data.next(&offset)
            // Unpack the section mutes into a Bool array. Spec says "0:mute".
            temp.sectionMutes = [
                !(b.isBitSet(0)),
                !(b.isBitSet(1)),
                !(b.isBitSet(2)),
                !(b.isBitSet(3))
            ]

            let effectControl1Data = data.slice(from: offset, length: EffectControl.dataSize)
            switch EffectControl.parse(from: effectControl1Data) {
            case .success(let control):
                temp.effectControl1 = control
            case .failure(let error):
                return .failure(error)
            }
            offset += EffectControl.dataSize
            
            let effectControl2Data = data.slice(from: offset, length: EffectControl.dataSize)
            switch EffectControl.parse(from: effectControl2Data) {
            case .success(let control):
                temp.effectControl2 = control
            case .failure(let error):
                return .failure(error)
            }
            
            return .success(temp)
        }
    }
    
    /// One section of a multi patch.
    public struct Section: Codable {
        public var single: InstrumentNumber
        public var volume: UInt
        public var pan: Int
        public var effectPath: UInt
        public var transpose: Int
        public var tune: Int
        public var zone: Zone
        public var velocitySwitch: VelocitySwitch
        public var receiveChannel: UInt8
        
        /// Initializes a multi section with defaults.
        public init() {
            single = InstrumentNumber(number: 0)
            volume = 127
            pan = 0
            effectPath = 0
            transpose = 0
            tune = 0
            zone = Zone(high: Key(note: 0), low: Key(note: 127))
            velocitySwitch = VelocitySwitch(kind: .off, threshold: 0)  // TODO: check these
            receiveChannel = 1
        }
        
        public static func parse(from data: ByteArray) -> Result<Section, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = Section()
            
            b = data.next(&offset)
            let instrumentMSB = b
            b = data.next(&offset)
            let instrumentLSB = b
            
            temp.single = InstrumentNumber(msb: instrumentMSB, lsb: instrumentLSB)
            
            b = data.next(&offset)
            temp.volume = UInt(b)
            
            b = data.next(&offset)
            temp.pan = Int(b)

            b = data.next(&offset)
            temp.effectPath = UInt(b)
            
            b = data.next(&offset)
            temp.transpose = Int(b) - 64  // SysEx 40~88 to -24~+24

            b = data.next(&offset)
            temp.tune = Int(b) - 64  // SysEx 1~127 to -63...+63
            
            b = data.next(&offset)
            let zoneLow = b
            b = data.next(&offset)
            let zoneHigh = b
            temp.zone = Zone(high: Key(note: Int(zoneHigh)), low: Key(note: Int(zoneLow)))

            var velocitySwitchBytes = ByteArray()
            b = data.next(&offset)
            velocitySwitchBytes.append(b)
            b = data.next(&offset)
            velocitySwitchBytes.append(b)
            
            switch VelocitySwitch.parse(from: velocitySwitchBytes) {
            case .success(let vs):
                temp.velocitySwitch = vs
            case .failure(let error):
                return .failure(error)
            }
            
            b = data.next(&offset)
            temp.receiveChannel = b
            
            return .success(temp)
        }
    }
    
    /// Multi patch common settings.
    public var common: Common
    
    /// Multi patch sections.
    public var sections: [Section]
    
    /// Initializes a default multi patch.
    public init() {
        common = Common()
        sections = [Section](repeating: Section(), count: MultiPatch.sectionCount)
    }
    
    /// Initializes a multi patch from MIDI System Exclusive data.
    /// - Parameter d: A byte array with the System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<MultiPatch, ParseError> {
        var offset: Int = 0

        _ = data.next(&offset)  // checksum is the first byte
        
        var temp = MultiPatch()
        
        switch Common.parse(from: data.slice(from: offset, length: Common.dataSize)) {
        case .success(let common):
            temp.common = common
        case .failure(let error):
            return .failure(error)
        }
        offset += Common.dataSize
        
        temp.sections = [Section]()
        for _ in 0..<MultiPatch.sectionCount {
            switch Section.parse(from: data.slice(from: offset, length: Section.dataSize)) {
            case .success(let section):
                temp.sections.append(section)
            case .failure(let error):
                return .failure(error)
            }
            offset += Section.dataSize
        }
        
        return .success(temp)
    }
    
    /// Multi patch checksum.
    public var checksum: Byte {
        var totalSum: Int = 0
        
        let commonData = common.asData()
        var commonSum: Int = 0
        for d in commonData {
            commonSum += Int(d) & 0xFF
        }
        totalSum += commonSum

        var sectionSum: Int = 0
        for section in sections {
            for b in section.asData() {
                sectionSum += Int(b) & 0xFF
            }
        }
        totalSum += sectionSum
        
        totalSum += 0xA5

        return Byte(totalSum & 0x7F)
    }
    
    /// Generates a MIDI System Exclusive message from this patch.
    /// - Parameter channel: the MIDI channel to use
    /// - Parameter instrument: 00...3F
    public func asSystemExclusiveMessage(channel: Byte, instrument: Byte) -> ByteArray {
        var data = ByteArray()
        
        let header = SystemExclusive.Header(
            channel: channel,
            function: .oneBlockDump,
            group: 0x00,
            machineIdentifier: 0x0a,
            substatus1: 0x20,
            substatus2: instrument)

        data.append(contentsOf: header.asData())
        data.append(contentsOf: self.asData())
        
        return data
    }
}

// MARK: - SystemExclusiveData

extension MultiPatch: SystemExclusiveData {
    /// Gets the multi patch as MIDI System Exclusive data.
    /// Collects and arranges the data for the various components of the patch.
    /// - Returns: A byte array with the patch data, without the System Exclusive header.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(self.checksum)
        
        data.append(contentsOf: common.asData())
        
        for section in sections {
            data.append(contentsOf: section.asData())
        }
        
        return data
    }
    
    public var dataLength: Int {
        return 1 + Common.dataSize + 4 * Section.dataSize
    }
}

extension MultiPatch.Common: SystemExclusiveData {
    /// Gets the common part as MIDI System Exclusive data.
    /// - Returns: A byte array with the common part data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: effects.asData())
        
        geq.forEach { data.append(Byte($0 + 64)) } // 58(-6)~70(+6)
        
        data.append(contentsOf: name.asData())

        data.append(Byte(volume))
                
        return data
    }
    
    public var dataLength: Int { return MultiPatch.Common.dataSize }
    
    public static let dataSize = 54
}

extension MultiPatch.Section: SystemExclusiveData {
    /// Gets a multi section as MIDI System Exclusive data.
    /// - Returns: A byte array with the section SysEx data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: single.asData())
        
        data.append(Byte(volume))
        data.append(Byte(pan))
        data.append(Byte(effectPath))
        data.append(Byte(transpose + 64))
        data.append(Byte(tune + 64))
        data.append(Byte(zone.low.note))
        data.append(Byte(zone.high.note))
        data.append(contentsOf: velocitySwitch.asData())
        data.append(receiveChannel)
        
        return data
    }
    
    public var dataLength: Int { return MultiPatch.Section.dataSize }
    
    public static let dataSize = 12
}
