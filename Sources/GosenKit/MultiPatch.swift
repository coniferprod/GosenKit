import Foundation

import SyxPack
import ByteKit


/// A Kawai K5000 multi patch (combi on the K5000W).
public struct MultiPatch {
    public static let sectionCount = 4
    
    /// Common settings for multi patch.
    public struct Common {
        public var effects: EffectSettings
        public var geq: GEQ
        public var name: PatchName
        public var volume: Int // 0...127
        public var sectionMutes: [Bool]
        public var effectControl: EffectControl

        /// Initialize common settings with defaults.
        public init() {
            self.effects = EffectSettings()
            self.geq = GEQ(levels: [Int](repeating: 0, count: GEQ.bandCount))
            self.name = PatchName("NewMulti")
            self.volume = 127
            self.sectionMutes = [Bool](repeating: false, count: MultiPatch.sectionCount)
            self.effectControl = EffectControl()
        }
        
        /// Parses the common part of a multi patch from System Exclusive data.
        /// - Parameter data: The System Exclusive data bytes.
        /// - Returns: A `Result` type with either the parsed `Common`, or a `ParseError` with more details.
        public static func parse(from data: ByteArray) -> Result<Common, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            //print("Starting to parse multi/combi patch common data from \(data.count) bytes")
            
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

            //print("After effects parsed, offset = \(String(format: "%d", offset)) (data length = \(data.count))")

            size = GEQ.bandCount
            switch GEQ.parse(from: data.slice(from: offset, length: size)) {
            case .success(let geq):
                temp.geq = geq
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            // Don't adjust offset, it has already been adjusted in the loop above.

            //print("After GEQ parsed, offset = \(String(format: "%d", offset)) (data length = \(data.count))")

            size = PatchName.length
            let patchNameData = data.slice(from: offset, length: size)
            //print("patch name data (\(size) bytes): \(patchNameData.hexDump())")
            switch PatchName.parse(from: patchNameData) {
            case .success(let name):
                temp.name = name
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            //print("After name parsed, offset = \(String(format: "%d", offset)) (data length = \(data.count))")

            b = data.next(&offset)
            temp.volume = Int(b)
            
            //print("After volume parsed, offset = \(String(format: "%d", offset)) (data length = \(data.count))")

            b = data.next(&offset)
            // Unpack the section mutes into a Bool array. Spec says "0:mute".
            // bits 0~3 = section 1~4
            temp.sectionMutes = [
                !(b.isBitSet(0)),
                !(b.isBitSet(1)),
                !(b.isBitSet(2)),
                !(b.isBitSet(3))
            ]

            size = EffectControl.dataSize
            let effectControlData = data.slice(from: offset, length: size)
            switch EffectControl.parse(from: effectControlData) {
            case .success(let control):
                temp.effectControl = control
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            //print("After Effect Control parsed, offset = \(String(format: "%d", offset)) (data length = \(data.count))")

            return .success(temp)
        }
    }
    
    /// One section of a multi patch.
    public struct Section {
        public var single: InstrumentNumber
        public var volume: Int  // 0~127
        public var pan: Int  // 0~127  // *really?*
        public var effectPath: Int  // 0~3 in SysEx, store as 1~4
        public var transpose: Int  // SysEx 40~88 = -24~+24
        public var tune: Int  // SysEx 1~127 = -63~+63
        public var zone: Zone
        public var velocitySwitch: VelocitySwitch
        public var receiveChannel: Int  // SysEx 0~15 = 1~16
        
        /// Initializes a multi section with defaults.
        public init() {
            self.single = InstrumentNumber(number: 0)
            self.volume = 127
            self.pan = 0
            self.effectPath = 1
            self.transpose = 0
            self.tune = 0
            self.zone = Zone(low: Key(note: 0), high: Key(note: 127))
            self.velocitySwitch = VelocitySwitch(kind: .off, threshold: 0)  // TODO: check these
            self.receiveChannel = 1
        }
        
        /// Parses one section of a multi patch from System Exclusive data.
        /// - Parameter data: The System Exclusive data bytes.
        /// - Returns: A `Result` type with either the parsed `Section`, or a `ParseError` with more details.
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
            temp.volume = Int(b)
            
            b = data.next(&offset)
            temp.pan = Int(b)

            b = data.next(&offset)
            temp.effectPath = Int(b) + descriptors[.effectPath]!.incomingOffset
            
            b = data.next(&offset)
            temp.transpose = Int(b) + descriptors[.transpose]!.incomingOffset  // SysEx 40~88 to -24~+24

            b = data.next(&offset)
            temp.tune = Int(b) + descriptors[.depth]!.incomingOffset  // SysEx 1~127 to -63...+63  // offset 1?
            
            b = data.next(&offset)
            let zoneLow = b
            b = data.next(&offset)
            let zoneHigh = b
            temp.zone = Zone(
                low: Key(note: Int(zoneLow)),
                high: Key(note: Int(zoneHigh))
            )

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
            temp.receiveChannel = Int(b) + descriptors[.midiChannel]!.incomingOffset // adjust channel to 1~16
            
            return .success(temp)
        }
    }
    
    /// Multi patch common settings.
    public var common: Common
    
    /// Multi patch sections.
    public var sections: [Section]
    
    /// Initializes a default multi patch.
    public init() {
        self.common = Common()
        self.sections = [Section](repeating: Section(), count: MultiPatch.sectionCount)
    }
    
    /// Parses a multi patch from MIDI System Exclusive data.
    /// - Parameter data: The System Exclusive data bytes.
    /// - Returns: A `Result` type with either the parsed `MultiPatch`, or a `ParseError` with more details.
    public static func parse(from data: ByteArray) -> Result<MultiPatch, ParseError> {
        var offset: Int = 0

        _ = data.next(&offset)  // checksum is the first byte
        
        var temp = MultiPatch()
        
        var size = Common.dataSize
        switch Common.parse(from: data.slice(from: offset, length: size)) {
        case .success(let common):
            temp.common = common
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = Section.dataSize
        temp.sections = [Section]()
        for _ in 0..<MultiPatch.sectionCount {
            switch Section.parse(from: data.slice(from: offset, length: size)) {
            case .success(let section):
                temp.sections.append(section)
            case .failure(let error):
                return .failure(error)
            }
            offset += size
        }
        
        return .success(temp)
    }
    
    /// Multi patch checksum.
    public var checksum: Byte {
        var totalSum: Int = 0
        
        let commonData = self.common.asData()
        var commonSum: Int = 0
        for d in commonData {
            commonSum += Int(d) & 0xFF
        }
        totalSum += commonSum

        var sectionSum: Int = 0
        for section in self.sections {
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
    public func asSystemExclusiveMessage(channel: Int, instrument: Byte) -> ByteArray {
        var data = ByteArray()
        
        let header = SystemExclusive.Header(
            channel: channel,
            function: .oneBlockDump,
            substatus1: 0x20,
            substatus2: instrument)

        data.append(contentsOf: header.asData())
        data.append(contentsOf: self.asData())
        
        return data
    }
}

// MARK: - CustomStringConvertible

extension MultiPatch: CustomStringConvertible {
    /// String representation of this multi patch.
    public var description: String {
        var result = ""
        
        result += "\(self.common)\n"
        
        for (index, section) in self.sections.enumerated() {
            result += "Section \(index + 1):\n"
            result += "\(section)\n\n"
        }
        
        return result
    }
}

extension MultiPatch.Common: CustomStringConvertible {
    /// String representation of this common part of a multi patch.
    public var description: String {
        var result = ""
        
        result += "Name: \(self.name.value)\n"
        result += "Volume: \(self.volume)\n"
        result += "\(self.effects)\n"
        
        result += "GEQ: "
        for band in self.geq.levels {
            result += "\(band) "
        }
        result += "\n"
        
        result += "Effect Control:\n\(self.effectControl)\n"

        var muteValues = ["-", "-", "-", "-"]
        for (index, mute) in self.sectionMutes.enumerated() {
            muteValues[index] = mute ? "-" : String(format: "%d", index + 1)
        }
        result += "Sections: \(muteValues.joined(separator: ""))\n"
        
        return result
    }
}

extension MultiPatch.Section: CustomStringConvertible {
    /// String representation of this section of a multi patch.
    public var description: String {
        var result = ""
        
        result += "Instrument: \(self.single)\n"
        result += "Volume: \(self.volume)\n"
        result += "Pan: \(self.pan)\n"
        result += "Effect path: \(self.effectPath)\n"
        result += "Transpose: \(self.transpose)\n"
        result += "Tune: \(self.tune)\n"
        result += "Zone: \(self.zone)\n"
        result += "Vel SW: \(self.velocitySwitch)\n"
        result += "Receive Ch: \(self.receiveChannel)"
        
        return result
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
        
        data.append(contentsOf: self.common.asData())
        
        for section in self.sections {
            data.append(contentsOf: section.asData())
        }
        
        return data
    }
    
    /// The length of multi patch System Exclusive data.
    public var dataLength: Int { MultiPatch.dataSize }
    
    public static let dataSize =
        1
        + Common.dataSize
        + 4 * Section.dataSize
}

extension MultiPatch.Common: SystemExclusiveData {
    /// Gets the common part as MIDI System Exclusive data.
    /// - Returns: A byte array with the common part data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.effects.asData())
        data.append(contentsOf: self.geq.asData())
        data.append(contentsOf: self.name.asData())
        data.append(Byte(self.volume))
                
        return data
    }
    
    /// The length of multi patch common part System Exclusive data.
    public var dataLength: Int { MultiPatch.Common.dataSize }
    
    public static let dataSize = 54
}

extension MultiPatch.Section: SystemExclusiveData {
    /// Gets a multi section as MIDI System Exclusive data.
    /// - Returns: A byte array with the section SysEx data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.single.asData())
        
        let effectPathOffset = descriptors[.effectPath]!.outgoingOffset
        let transposeOffset = descriptors[.transpose]!.outgoingOffset
        let tuneOffset = descriptors[.depth]!.outgoingOffset
        
        [
            self.volume,
            self.pan,
            self.effectPath + effectPathOffset,  // adjust to 0~3
            self.transpose + transposeOffset,
            self.tune + tuneOffset,
            self.zone.low.note,
            self.zone.high.note
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        data.append(contentsOf: self.velocitySwitch.asData())
        data.append(Byte(self.receiveChannel + descriptors[.midiChannel]!.outgoingOffset))  // adjust to 0~15
        
        return data
    }
    
    /// The length of multi patch section data.
    public var dataLength: Int { MultiPatch.Section.dataSize }
    
    public static let dataSize = 12
}
