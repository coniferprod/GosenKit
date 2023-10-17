import SyxPack


public struct Morf {
    public struct CopyParameters: Codable {
        public var patchNumber: Int  // 0~127
        public var sourceNumber: Int  // 0~11 (0~5:soft, 6~11:loud)
        
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
        
        public static func parse(from data: ByteArray) -> Result<CopyParameters, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
        
            var temp = CopyParameters()
            
            b = data.next(&offset)
            temp.patchNumber = Int(b)
            
            b = data.next(&offset)
            temp.sourceNumber = Int(b)
            
            return .success(temp)
        }
    }

    public struct Envelope {
        public var time1: Level  // all times 0~127
        public var time2: Level
        public var time3: Level
        public var time4: Level
        public var loopKind: HarmonicEnvelope.LoopKind
        
        public init() {
            time1 = Level(0)
            time2 = Level(0)
            time3 = Level(0)
            time4 = Level(0)
            loopKind = .off
        }
        
        public init(data d: ByteArray) {
            var offset: Int = 0
            var b: Byte = 0
        
            b = d.next(&offset)
            time1 = Level(Int(b))
            
            b = d.next(&offset)
            time2 = Level(Int(b))

            b = d.next(&offset)
            time3 = Level(Int(b))
            
            b = d.next(&offset)
            time4 = Level(Int(b))

            b = d.next(&offset)
            loopKind = HarmonicEnvelope.LoopKind(index: Int(b))!
        }
        
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Envelope()
            
            b = data.next(&offset)
            temp.time1 = Level(Int(b))
            
            b = data.next(&offset)
            temp.time2 = Level(Int(b))

            b = data.next(&offset)
            temp.time3 = Level(Int(b))
            
            b = data.next(&offset)
            temp.time4 = Level(Int(b))

            b = data.next(&offset)
            temp.loopKind = HarmonicEnvelope.LoopKind(index: Int(b))!

            return .success(temp)
        }
    }

    public var copy1: CopyParameters
    public var copy2: CopyParameters
    public var copy3: CopyParameters
    public var copy4: CopyParameters
    public var envelope: Envelope
    
    public init() {
        copy1 = CopyParameters()
        copy2 = CopyParameters()
        copy3 = CopyParameters()
        copy4 = CopyParameters()
        envelope = Envelope()
    }
    
    public init(data d: ByteArray) {
        var offset: Int = 0
        
        var length = CopyParameters.dataSize
        copy1 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        copy2 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        copy3 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        copy4 = CopyParameters(data: d.slice(from: offset, length: length))
        offset += length

        length = Envelope.dataSize
        envelope = Envelope(data: d.slice(from: offset, length: length))
    }
}

// MARK: - SystemExclusiveData

extension Morf.CopyParameters: SystemExclusiveData {
    public func asData() -> ByteArray {
        return [Byte(patchNumber), Byte(sourceNumber)]
    }
    
    public var dataLength: Int { Morf.CopyParameters.dataSize }
    
    public static let dataSize = 2
}

extension Morf: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [ copy1, copy2, copy3, copy4 ].forEach {
            data.append(contentsOf: $0.asData())
        }
        
        data.append(contentsOf: envelope.asData())
        
        return data
    }

    public var dataLength: Int { Morf.dataSize }

    public static let dataSize = 13
}

extension Morf.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            time1.value,
            time2.value,
            time3.value,
            time4.value,
            loopKind.index
        ].forEach {
            data.append(Byte($0))
        }
        
        return data
    }
    
    public var dataLength: Int { Morf.Envelope.dataSize }
    
    public static let dataSize = 5
}
