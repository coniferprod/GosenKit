import SyxPack
import ByteKit

public struct Morf {
    public struct CopyParameters {
        public var patchNumber: Int  // 0~127
        public var sourceNumber: Int  // 0~11 (0~5:soft, 6~11:loud)
        
        public init() {
            self.patchNumber = 0
            self.sourceNumber = 0
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
        public var time1: Int  // all times 0~127
        public var time2: Int
        public var time3: Int
        public var time4: Int
        public var loopKind: HarmonicEnvelope.LoopKind
        
        public init() {
            self.time1 = 0
            self.time2 = 0
            self.time3 = 0
            self.time4 = 0
            self.loopKind = .off
        }
        
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Envelope()
            
            b = data.next(&offset)
            temp.time1 = Int(b)
            
            b = data.next(&offset)
            temp.time2 = Int(b)

            b = data.next(&offset)
            temp.time3 = Int(b)
            
            b = data.next(&offset)
            temp.time4 = Int(b)

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
        self.copy1 = CopyParameters()
        self.copy2 = CopyParameters()
        self.copy3 = CopyParameters()
        self.copy4 = CopyParameters()
        self.envelope = Envelope()
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
        [
            Byte(self.patchNumber),
            Byte(self.sourceNumber)
        ]
    }
    
    public var dataLength: Int { Morf.CopyParameters.dataSize }
    
    public static let dataSize = 2
}

extension Morf: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [ 
            self.copy1,
            self.copy2,
            self.copy3,
            self.copy4
        ]
        .forEach {
            data.append(contentsOf: $0.asData())
        }
        
        data.append(contentsOf: self.envelope.asData())
        
        return data
    }

    public var dataLength: Int { Morf.dataSize }

    public static let dataSize = 13
}

extension Morf.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [
            self.time1,
            self.time2,
            self.time3,
            self.time4,
            self.loopKind.index
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
