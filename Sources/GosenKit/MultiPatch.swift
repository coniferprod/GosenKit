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
        
        /// Initializes the common part of a multi patch from MIDI System Exclusive data.
        /// - Parameter d: A byte array with the System Exclusive data.
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            let effectData = d.slice(from: offset, length: EffectSettings.dataSize)
            effects = EffectSettings(data: effectData)
            offset += EffectSettings.dataSize
            
            geq = [Int]()
            for _ in 0..<SinglePatch.Common.geqBandCount {
                b = d.next(&offset)
                let v: Int = Int(b) - 64  // 58(-6) ~ 70(+6), so 64 is zero
                //print("GEQ band \(i + 1): \(b) --> \(v)")
                geq.append(Int(v))
            }
            offset += Common.geqBandCount
            
            name = PatchName(data: d.slice(from: offset, length: PatchName.length))
            offset += PatchName.length

            b = d.next(&offset)
            volume = UInt(b)

            b = d.next(&offset)
            // Unpack the section mutes into a Bool array. Spec says "0:mute".
            sectionMutes = [Bool]()
            sectionMutes.append(b.isBitSet(0) ? false : true)
            sectionMutes.append(b.isBitSet(1) ? false : true)
            sectionMutes.append(b.isBitSet(2) ? false : true)
            sectionMutes.append(b.isBitSet(3) ? false : true)

            let effectControl1Data = d.slice(from: offset, length: EffectControl.dataSize)
            effectControl1 = EffectControl(data: effectControl1Data)
            offset += EffectControl.dataSize
            
            let effectControl2Data = d.slice(from: offset, length: EffectControl.dataSize)
            effectControl2 = EffectControl(data: effectControl2Data)
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
        
        /// Initializes a multi section from MIDI System Exclusive data.
        /// - Parameter d: A byte array with the System Exclusive data.
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            b = d.next(&offset)
            let instrumentMSB = b
            b = d.next(&offset)
            let instrumentLSB = b
            
            single = InstrumentNumber(msb: instrumentMSB, lsb: instrumentLSB)
            
            b = d.next(&offset)
            volume = UInt(b)
            
            b = d.next(&offset)
            pan = Int(b)

            b = d.next(&offset)
            effectPath = UInt(b)
            
            b = d.next(&offset)
            transpose = Int(b) - 64  // SysEx 40~88 to -24~+24

            b = d.next(&offset)
            tune = Int(b) - 64  // SysEx 1~127 to -63...+63
            
            b = d.next(&offset)
            let zoneLow = b
            b = d.next(&offset)
            let zoneHigh = b
            zone = Zone(high: Key(note: Int(zoneHigh)), low: Key(note: Int(zoneLow)))

            var velocitySwitchBytes = ByteArray()
            b = d.next(&offset)
            velocitySwitchBytes.append(b)
            b = d.next(&offset)
            velocitySwitchBytes.append(b)
            
            velocitySwitch = VelocitySwitch(data: velocitySwitchBytes)
            
            b = d.next(&offset)
            receiveChannel = b
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
    public init(data d: ByteArray) {
        var offset: Int = 0
        
        common = Common(data: d)
        offset += Common.dataSize
        
        sections = [Section]()
        for _ in 0..<MultiPatch.sectionCount {
            let section = Section(data: d.slice(from: offset, length: Section.dataSize))
            sections.append(section)
            offset += Section.dataSize
        }
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
