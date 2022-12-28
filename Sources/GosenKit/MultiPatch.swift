import Foundation

import SyxPack


/// A Kawai K5000 multi patch (combi on the K5000W).
public struct MultiPatch: Codable {
    public static let sectionCount = 4
    
    /// Common settings for multi patch.
    public struct Common: Codable {
        static let geqBandCount = 7

        public var effects: EffectSettings
        public var geq: [Int]  // all 0...127
        @PatchName public var name: String // 8 characters
        public var volume: UInt
        public var sectionMutes: [Bool]
        public var effectControl1: EffectControl
        public var effectControl2: EffectControl

        /// Initializes the common part of a multi patch from MIDI System Exclusive data.
        /// - Parameter d: A byte array with the System Exclusive data.
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            let effectData = d.slice(from: offset, length: EffectSettings.dataLength)
            effects = EffectSettings(data: effectData)
            offset += EffectSettings.dataLength
            
            geq = [Int]()
            for _ in 0..<SinglePatch.Common.geqBandCount {
                b = d.next(&offset)
                let v: Int = Int(b) - 64  // 58(-6) ~ 70(+6), so 64 is zero
                //print("GEQ band \(i + 1): \(b) --> \(v)")
                geq.append(Int(v))
            }
            offset += Common.geqBandCount
            
            name = String(data: Data(d.slice(from: offset, length: PatchName.length)), encoding: .ascii) ?? "--------"
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

            let effectControl1Data = d.slice(from: offset, length: EffectControl.dataLength)
            effectControl1 = EffectControl(data: effectControl1Data)
            offset += EffectControl.dataLength
            
            let effectControl2Data = d.slice(from: offset, length: EffectControl.dataLength)
            effectControl2 = EffectControl(data: effectControl2Data)
        }
    }
    
    /// One section of a multi patch.
    public struct Section: Codable {
        public var singlePatchNumber: UInt
        public var volume: UInt
        public var pan: Int
        public var effectPath: UInt
        public var transpose: Int
        public var tune: Int
        public var zone: Zone
        public var velocitySwitch: VelocitySwitch
        public var receiveChannel: UInt8
        
        /// Initializes a multi section from MIDI System Exclusive data.
        /// - Parameter d: A byte array with the System Exclusive data.
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
            
            b = d.next(&offset)
            let instrumentMSB = b
            b = d.next(&offset)
            let instrumentLSB = b
            
            let instrumentMSBString = String(instrumentMSB, radix: 2).pad(with: "0", toLength: 2)
            let instrumentLSBString = String(instrumentLSB, radix: 2).pad(with: "0", toLength: 7)
            let bitString = instrumentMSBString + instrumentLSBString
            // now we should have a 9-bit binary string, convert it to a decimal number
            singlePatchNumber = UInt(bitString, radix: 2)!

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
        
        public func asBytes() -> (msb: Byte, lsb: Byte) {
            // Convert wave kit number to binary string with 10 digits
            // using a String extension (see Helpers.swift).
            let waveBitString = String(self.singlePatchNumber, radix: 2).pad(with: "0", toLength: 9)
            
            // Take the first two bits and convert them to a number
            let msbBitString = waveBitString.prefix(2)
            let msb = Byte(msbBitString, radix: 2)!
            
            // Take the last seven bits and convert them to a number
            let lsbBitString = waveBitString.suffix(7)
            let lsb = Byte(lsbBitString, radix: 2)!

            return (msb, lsb)
        }
    }
    
    /// Multi patch common settings.
    public var common: Common
    
    /// Multi patch sections.
    public var sections: [Section]
    
    /// Initializes a multi patch from MIDI System Exclusive data.
    /// - Parameter d: A byte array with the System Exclusive data.
    public init(data d: ByteArray) {
        var offset: Int = 0
        
        common = Common(data: d)
        offset += Common.dataLength
        
        sections = [Section]()
        for _ in 0..<MultiPatch.sectionCount {
            let section = Section(data: d.slice(from: offset, length: Section.dataLength))
            sections.append(section)
            offset += Section.dataLength
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
    
    public static var dataLength: Int {
        return 1 + Common.dataLength + 4 * Section.dataLength
    }
}

extension MultiPatch.Common: SystemExclusiveData {
    /// Gets the common part as MIDI System Exclusive data.
    /// - Returns: A byte array with the common part data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: effects.asData())
        
        geq.forEach { data.append(Byte($0 + 64)) } // 58(-6)~70(+6)
        
        let nameBuffer: ByteArray = Array(name.utf8)
        data.append(contentsOf: nameBuffer)
        
        data.append(Byte(volume))
                
        return data
    }
    
    public static var dataLength = 54
}

extension MultiPatch.Section: SystemExclusiveData {
    /// Gets a multi section as MIDI System Exclusive data.
    /// - Returns: A byte array with the section SysEx data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        let (instrumentMSB, instrumentLSB) = self.asBytes()
        data.append(instrumentMSB)
        data.append(instrumentLSB)
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
    
    public static var dataLength = 12
}
