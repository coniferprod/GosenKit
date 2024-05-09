import SyxPack
import ByteKit

public struct Morf {
    public struct CopyParameters {
        public var patchNumber: PatchNumber  // 0~127
        public var sourceNumber: Int  // 0~11 (0~5:soft, 6~11:loud)
        
        public init() {
            patchNumber = 0
            sourceNumber = 0
        }
        
        public static func parse(from data: ByteArray) -> Result<CopyParameters, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
        
            var temp = CopyParameters()
            
            b = data.next(&offset)
            temp.patchNumber = PatchNumber(Int(b))
            
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
            time1 = 0
            time2 = 0
            time3 = 0
            time4 = 0
            loopKind = .off
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
    
    public static func parse(from data: ByteArray) -> Result<Morf, ParseError> {
        var temp = Morf()
        
        var offset: Int = 0
        var size = CopyParameters.dataSize
        switch CopyParameters.parse(from: data.slice(from: offset, length: size)) {
        case .success(let copy):
            temp.copy1 = copy
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        switch CopyParameters.parse(from: data.slice(from: offset, length: size)) {
        case .success(let copy):
            temp.copy2 = copy
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        switch CopyParameters.parse(from: data.slice(from: offset, length: size)) {
        case .success(let copy):
            temp.copy3 = copy
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        switch CopyParameters.parse(from: data.slice(from: offset, length: size)) {
        case .success(let copy):
            temp.copy4 = copy
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = Envelope.dataSize
        switch Envelope.parse(from: data.slice(from: offset, length: size)) {
        case .success(let envelope):
            temp.envelope = envelope
        case .failure(let error):
            return .failure(error)
        }

        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Morf.CopyParameters: SystemExclusiveData {
    public func asData() -> ByteArray {
        return [Byte(patchNumber.value), Byte(sourceNumber)]
    }
    
    public var dataLength: Int { Morf.CopyParameters.dataSize }
    
    public static let dataSize = 2
}

extension Morf: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [ 
            copy1,
            copy2,
            copy3,
            copy4
        ]
        .forEach {
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
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        return data
    }
    
    public var dataLength: Int { Morf.Envelope.dataSize }
    
    public static let dataSize = 5
}

// MARK: - CustomStringConvertible

extension Morf: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "  Copy1: \(self.copy1)\n"
        s += "  Copy2: \(self.copy2)\n"
        s += "  Copy3: \(self.copy3)\n"
        s += "  Copy4: \(self.copy4)\n"
        s += "  Envelope: \(self.envelope)"
        return s
    }
}

extension Morf.Envelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Time1 = \(self.time1) "
        s += "Time2 = \(self.time2) "
        s += "Time3 = \(self.time3) "
        s += "Time4 = \(self.time4) "
        s += "Loop = \(self.loopKind)"
        return s
    }
}

extension Morf.CopyParameters: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Patch = \(self.patchNumber) "
        s += "Source = \(self.sourceNumber)"
        return s
    }
}
