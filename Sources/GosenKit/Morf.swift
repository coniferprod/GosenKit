import Foundation

public struct MorfHarmonicEnvelope: Codable {
    public var time1: Int  // all times 0~127
    public var time2: Int
    public var time3: Int
    public var time4: Int
    public var loopType: EnvelopeLoopType
    
    static let dataLength = 5
    
    public init() {
        time1 = 0
        time2 = 0
        time3 = 0
        time4 = 0
        loopType = .off
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d[offset]
        time1 = Int(b)
        offset += 1
        
        b = d[offset]
        time2 = Int(b)
        offset += 1

        b = d[offset]
        time3 = Int(b)
        offset += 1
        
        b = d[offset]
        time4 = Int(b)
        offset += 1

        b = d[offset]
        loopType = EnvelopeLoopType(index: Int(b))!
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(time1))
        data.append(Byte(time2))
        data.append(Byte(time3))
        data.append(Byte(time4))
        data.append(Byte(loopType.index!))

        return data
    }
}

public struct MorfHarmonicCopyParameters: Codable {
    public var patchNumber: Int  // 0~127
    public var sourceNumber: Int  // 0~11 (0~5:soft, 6~11:loud)
    
    static let dataLength = 2
    
    public init() {
        patchNumber = 0
        sourceNumber = 0
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
    
        b = d[offset]
        patchNumber = Int(b)
        offset += 1
        
        b = d[offset]
        sourceNumber = Int(b)
        offset += 1
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(patchNumber))
        data.append(Byte(sourceNumber))

        return data
    }
}

public struct MorfHarmonicSettings: Codable {
    public var copy1: MorfHarmonicCopyParameters
    public var copy2: MorfHarmonicCopyParameters
    public var copy3: MorfHarmonicCopyParameters
    public var copy4: MorfHarmonicCopyParameters
    public var envelope: MorfHarmonicEnvelope
    
    static let dataLength = 13
    
    public init() {
        copy1 = MorfHarmonicCopyParameters()
        copy2 = MorfHarmonicCopyParameters()
        copy3 = MorfHarmonicCopyParameters()
        copy4 = MorfHarmonicCopyParameters()
        envelope = MorfHarmonicEnvelope()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        copy1 = MorfHarmonicCopyParameters(data: ByteArray(d[offset ..< offset + MorfHarmonicCopyParameters.dataLength]))
        offset += MorfHarmonicCopyParameters.dataLength

        copy2 = MorfHarmonicCopyParameters(data: ByteArray(d[offset ..< offset + MorfHarmonicCopyParameters.dataLength]))
        offset += MorfHarmonicCopyParameters.dataLength

        copy3 = MorfHarmonicCopyParameters(data: ByteArray(d[offset ..< offset + MorfHarmonicCopyParameters.dataLength]))
        offset += MorfHarmonicCopyParameters.dataLength

        copy4 = MorfHarmonicCopyParameters(data: ByteArray(d[offset ..< offset + MorfHarmonicCopyParameters.dataLength]))
        offset += MorfHarmonicCopyParameters.dataLength

        envelope = MorfHarmonicEnvelope(data: ByteArray(d[offset ..< offset + MorfHarmonicEnvelope.dataLength]))
        offset += MorfHarmonicEnvelope.dataLength
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: copy1.asData())
        data.append(contentsOf: copy2.asData())
        data.append(contentsOf: copy3.asData())
        data.append(contentsOf: copy4.asData())
        data.append(contentsOf: envelope.asData())

        return data
    }
}
