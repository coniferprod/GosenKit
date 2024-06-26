import SyxPack
import ByteKit

/// Additive kit.
public struct AdditiveKit {
    /// The number of harmonics in the additive kit.
    public static let harmonicCount = 64
    
    public var common: HarmonicCommon
    public var morf: Morf
    public var formantFilter: FormantFilter
    public var levels: HarmonicLevels
    public var bands: FormantFilter.Bands
    public var envelopes: [HarmonicEnvelope]
    
    /// Initializes an additive kit with default values.
    public init() {
        common = HarmonicCommon()
        morf = Morf()
        formantFilter = FormantFilter()
        levels = HarmonicLevels()
        bands = FormantFilter.Bands()
        
        // Initialize the envelopes with default values.
        envelopes = [HarmonicEnvelope]()
        for _ in 0..<AdditiveKit.harmonicCount {
            envelopes.append(HarmonicEnvelope())
        }
    }
    
    /// Parses an additive kit from MIDI System Exclusive data.
    /// Returns `AdditiveKit` if parsing succeeds, `ParseError` if it fails.
    public static func parse(from data: ByteArray) -> Result<AdditiveKit, ParseError> {
        var offset: Int = 0

        var temp = AdditiveKit()
        
        let _ = data.next(&offset)
        
        var size = HarmonicCommon.dataSize
        switch HarmonicCommon.parse(from: data.slice(from: offset, length: size)) {
        case .success(let common):
            temp.common = common
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = Morf.dataSize
        switch Morf.parse(from: data.slice(from: offset, length: size)) {
        case .success(let morf):
            temp.morf = morf
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        size = FormantFilter.dataSize
        switch FormantFilter.parse(from: data.slice(from: offset, length: size)) {
        case .success(let ff):
            temp.formantFilter = ff
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = HarmonicLevels.dataSize
        switch HarmonicLevels.parse(from: data.slice(from: offset, length: size)) {
        case .success(let levels):
            temp.levels = levels
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = FormantFilter.Bands.dataSize
        switch FormantFilter.Bands.parse(from: data.slice(from: offset, length: size)) {
        case .success(let bands):
            temp.bands = bands
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = HarmonicEnvelope.dataSize
        temp.envelopes = [HarmonicEnvelope]()
        for _ in 0 ..< AdditiveKit.harmonicCount {
            let envelopeData = data.slice(from: offset, length: size)

            switch HarmonicEnvelope.parse(from: envelopeData) {
            case .success(let envelope):
                temp.envelopes.append(envelope)
            case .failure(let error):
                return .failure(error)
            }

            offset += size
        }

        return .success(temp)
    }

    /// The checksum of the additive kit.
    public var checksum: Byte {
        // Additive kit checksum (as found in Section 3.1.3):
        // {(HCKIT sum) + (HCcode1 sum) + (HCcode2 sum) + (FF sum) + (HCenv sum) + (loud sense select) + 0xA5} & 0x7F

        var totalSum: Int = 0
        var byteCount = 0
        
        // HCKIT sum:
        let commonData = common.asData()
        var commonSum: Int = 0
        for d in commonData {
            commonSum += Int(d) & 0xFF
            byteCount += 1
        }
        let morfData = morf.asData()
        for d in morfData {
            commonSum += Int(d) & 0xFF
            byteCount += 1
        }
        let formantData = formantFilter.asData()
        for d in formantData {
            commonSum += Int(d) & 0xFF
            byteCount += 1
        }
        //print("checksum: added common data (\(commonData.count) bytes), MORF data (\(morfData.count) bytes) and formant data (\(formantData.count) bytes), total = \(byteCount)")
        //print("checksum: common sum = \(commonSum)")
        totalSum += commonSum & 0xFF
        
        // HCcode1 sum:
        var hc1Sum = 0
        for h in levels.soft {
            hc1Sum += h.value & 0xFF
            byteCount += 1
        }
        totalSum += hc1Sum & 0xFF
        //print("checksum: added soft harmonic data (\(levels.soft.count) bytes), total = \(byteCount)")

        // HCcode2 sum:
        var hc2Sum = 0
        for h in levels.loud {
            hc2Sum += h.value & 0xFF
            byteCount += 1
        }
        totalSum += hc2Sum & 0xFF
        //print("checksum: added loud harmonic data (\(levels.loud.count) bytes), total = \(byteCount)")

        // FF sum:
        var ffSum = 0
        for f in bands.levels {
            ffSum += f.value & 0xFF
            byteCount += 1
        }
        totalSum += ffSum & 0xFF
        //print("checksum: added formant filter data (\(formantFilter.bands.levels.count) bytes), total = \(byteCount)")

        // HCenv sum:
        var hcEnvSum = 0
        var envByteCount = 0
        for env in envelopes {
            let ed = env.asData()
            for e in ed {
                hcEnvSum += Int(e) & 0xFF
                byteCount += 1
                envByteCount += 1
            }
        }
        //print("checksum: added harmonic envelope data (\(envByteCount) bytes), total = \(byteCount)")

        totalSum += hcEnvSum & 0xFF

        // The "loud sens select" value does not affect the checksum
        // when it is zero as specified in Section 3.1.3.
        
        totalSum += 0xA5
        byteCount += 1
        //print("checksum: added 0xA5, total = \(byteCount)")
        
        let result = Byte(totalSum & 0x7F)
        //print("debug: checksum: byteCount = \(byteCount), result = 0x\(String(result, radix: 16))", to: &standardError)

        return result
    }
}

// MARK: - SystemExclusiveData

extension AdditiveKit: SystemExclusiveData {
    /// Gets the additive kit as MIDI System Exclusive data.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(checksum)
        
        data.append(contentsOf: common.asData())
        data.append(contentsOf: morf.asData())
        data.append(contentsOf: formantFilter.asData())
        data.append(contentsOf: levels.asData())
        data.append(contentsOf: bands.asData())
        
        for env in envelopes {
            data.append(contentsOf: env.asData())
        }

        // The last byte is shown as "dummy" = 0 in Section 3.1.3.
        // In the checksum calculation it is referred to as
        // "LS select" or "loud sence select".
        data.append(0)

        assert(data.count == AdditiveKit.dataSize)
        return data
    }
    
    /// Gets the MIDI System Exclusive data length of the additive kit.
    public var dataLength: Int { AdditiveKit.dataSize }
    
    public static let dataSize = 806
}

// MARK: - CustomStringComvertible

extension AdditiveKit: CustomStringConvertible {
    /// Gets a printable representation of this additive kit.
    public var description: String {
        var s = ""
        s += "Common:\n\(common)\n"
        s += "MORF:\n\(morf)\n"
        s += "Formant filter: \(formantFilter)\n"
        s += "Harmonic levels:\n\(levels)\n"
        
        s += "Harmonic envelopes:\n"
        for (index, e) in envelopes.enumerated() {
            s += "\(index + 1): \(e)\n"
        }
        
        return s
    }
}
