import Foundation

public struct Morf: Codable {
    public struct CopyParameters: Codable {
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
        
            b = d.next(&offset)
            patchNumber = Int(b)
            
            b = d.next(&offset)
            sourceNumber = Int(b)
        }
        
        public func asData() -> ByteArray {
            return ByteArray(arrayLiteral: Byte(patchNumber), Byte(sourceNumber))
        }
    }

    public struct Envelope: Codable {
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
        
            b = d.next(&offset)
            time1 = Int(b)
            
            b = d.next(&offset)
            time2 = Int(b)

            b = d.next(&offset)
            time3 = Int(b)
            
            b = d.next(&offset)
            time4 = Int(b)

            b = d.next(&offset)
            loopType = EnvelopeLoopType(index: Int(b))!
        }
        
        public func asData() -> ByteArray {
            var data = ByteArray()
            [time1, time2, time3, time4, loopType.index!].forEach {
                data.append(Byte($0))
            }
            return data
        }
    }


    public var copy1: CopyParameters
    public var copy2: CopyParameters
    public var copy3: CopyParameters
    public var copy4: CopyParameters
    public var envelope: Envelope
    
    static let dataLength = 13
    
    public init() {
        copy1 = CopyParameters()
        copy2 = CopyParameters()
        copy3 = CopyParameters()
        copy4 = CopyParameters()
        envelope = Envelope()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        
        var length = CopyParameters.dataLength
        copy1 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        copy2 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        copy3 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        copy4 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        length = Envelope.dataLength
        envelope = Envelope(data: d.slice(from: offset, length: length))
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
