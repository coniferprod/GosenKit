import SyxPack
import ByteKit

/// Filter (DCF).
public struct Filter {
    /// Filter mode.
    public enum Mode: Int, CaseIterable {
        case lowPass
        case highPass
        
        /// Initializes filter mode from SysEx byte.
        public init?(index: Int) {
            switch index {
            case 0: self = .lowPass
            case 1: self = .highPass
            default: return nil
            }
        }
    }

    /// Filter envelope. The times for attack, decay1, and decay2 are
    /// package-level Time values (0...127), but level is -63...63.
    public struct Envelope {
        public var attackTime: Int  // 0...127
        public var decay1Time: Int
        public var decay1Level: Int  // -63...63
        public var decay2Time: Int
        public var decay2Level: Int
        public var releaseTime: Int
        public var keyScalingToAttack: Int  // -63...63
        public var keyScalingToDecay1: Int
        public var velocityToEnvelope: Int
        public var velocityToAttack: Int
        public var velocityToDecay1: Int

        /// Initialize filter envelope with default values.
        public init() {
            self.attackTime = 0
            self.decay1Time = 0
            self.decay1Level = 0
            self.decay2Time = 0
            self.decay2Level = 0
            self.releaseTime = 0
            self.keyScalingToAttack = 0
            self.keyScalingToDecay1 = 0
            self.velocityToEnvelope = 0
            self.velocityToAttack = 0
            self.velocityToDecay1 = 0
        }
        
        /// Parse the filter envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
        
            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attackTime = Int(b)

            b = data.next(&offset)
            temp.decay1Time = Int(b)
            
            let descriptor = descriptors[.filterEnvelopeLevel]!
            
            b = data.next(&offset)
            temp.decay1Level = Int(b) + descriptor.incomingOffset
            
            b = data.next(&offset)
            temp.decay2Time = Int(b)
            
            b = data.next(&offset)
            temp.decay2Level = Int(b) + descriptor.incomingOffset
            
            b = data.next(&offset)
            temp.releaseTime = Int(b)
            
            b = data.next(&offset)
            temp.keyScalingToAttack = Int(b) + descriptor.incomingOffset
            
            b = data.next(&offset)
            temp.keyScalingToDecay1 = Int(b) + descriptor.incomingOffset
            
            b = data.next(&offset)
            temp.velocityToEnvelope = Int(b) + descriptor.incomingOffset

            b = data.next(&offset)
            temp.velocityToAttack = Int(b) + descriptor.incomingOffset

            b = data.next(&offset)
            temp.velocityToDecay1 = Int(b) + descriptor.incomingOffset

            return .success(temp)
        }
    }

    public var isActive: Bool
    public var cutoff: Int // 0...127
    public var resonance: Int  // 0...31
    public var mode: Mode
    public var velocityCurve: Int  // 1...12
    public var level: Int // 0...127
    public var keyScalingToCutoff: Int // -63...63
    public var velocityToCutoff: Int // -63...63
    public var envelopeDepth: Int  // -63...63
    public var envelope: Envelope
    
    public init() {
        self.isActive = false
        self.cutoff = 127
        self.resonance = 0
        self.mode = .lowPass
        self.velocityCurve = 1
        self.level = 7
        self.keyScalingToCutoff = 0
        self.velocityToCutoff = 0
        self.envelopeDepth = 0
        self.envelope = Envelope()
    }
    
    /// Parse the filter from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<Filter, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
    
        var temp = Filter()
        
        b = data.next(&offset)
        temp.isActive = b == 1 ? false : true  // value of 1 means filter is bypassed
        
        b = data.next(&offset)
        temp.mode = Mode(index: Int(b))!
        
        b = data.next(&offset)
        temp.velocityCurve = Int(b) + descriptors[.velocityCurve]!.incomingOffset  // from 0 ~ 11 to  1 ~ 12

        b = data.next(&offset)
        temp.resonance = Int(b)

        b = data.next(&offset)
        temp.level = Int(b)
        
        b = data.next(&offset)
        temp.cutoff = Int(b)

        b = data.next(&offset)
        let descriptor = descriptors[.depth]!
        temp.keyScalingToCutoff = Int(b) + descriptor.incomingOffset
        
        b = data.next(&offset)
        temp.velocityToCutoff = Int(b) + descriptor.incomingOffset
        
        b = data.next(&offset)
        temp.envelopeDepth = Int(b) + descriptor.incomingOffset
        
        switch Envelope.parse(from: data.slice(from: offset, length: Envelope.dataSize)) {
        case .success(let env):
            temp.envelope = env
        case .failure(let error):
            return .failure(error)
        }

        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Filter: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        let descriptor = descriptors[.depth]!
        let offset = descriptor.outgoingOffset
        
        let velocityCurveOffset = descriptors[.velocityCurve]!.outgoingOffset
        
        [
            self.isActive ? 0 : 1,
            self.mode.index,
            self.velocityCurve + velocityCurveOffset,
            self.resonance,
            self.level,
            self.cutoff,
            self.keyScalingToCutoff + offset,
            self.velocityToCutoff + offset,
            self.envelopeDepth + offset,
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: self.envelope.asData())
        
        return data
    }
    
    public var dataLength: Int { Filter.dataSize }
    
    public static let dataSize = 20
}

extension Filter.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        let descriptor = descriptors[.depth]!
        let offset = descriptor.outgoingOffset
        
        [
            self.attackTime,
            self.decay1Time,
            self.decay1Level + offset,
            self.decay2Time,
            self.decay2Level + offset,
            self.releaseTime,
            self.keyScalingToAttack + offset,
            self.keyScalingToDecay1 + offset,
            self.velocityToEnvelope + offset,
            self.velocityToAttack + offset,
            self.velocityToDecay1 + offset,
        ]
        .forEach {
            data.append(Byte($0))
        }

        return data
    }
    
    public var dataLength: Int { Filter.Envelope.dataSize }
    
    public static let dataSize = 11
}

// MARK: - CustomStringConvertible

extension Filter: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "Active=" + (self.isActive ? "YES" : "NO") + " Mode=\(self.mode)\n"
        s += "Cutoff=\(self.cutoff) Resonance=\(self.resonance) Level=\(self.level)\n"
        s += "Vel.Curve=\(self.velocityCurve) KStoCut=\(self.keyScalingToCutoff) VelToCut=\(self.velocityToCutoff)\n"
        s += "Env.Depth=\(self.envelopeDepth)\n"
        s += "\nFilter Envelope:\n\(self.envelope)\n"
        return s
    }
}

extension Filter.Mode: CustomStringConvertible {
    public var description: String {
        var s = ""
        switch self {
        case .lowPass:
            s = "LP"
        case .highPass:
            s = "HP"
        }
        return s
    }
}

extension Filter.Envelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "attackTime=\(self.attackTime) decay1Time=\(self.decay1Time) decay1Level=\(self.decay1Level)\n"
        s += "decay2Time=\(self.decay2Time) decay2Level=\(self.decay2Level) releaseTime=\(self.releaseTime)\n"
        s += "KSToAttack=\(self.keyScalingToAttack) KSToDecay=\(self.keyScalingToDecay1)\n"
        s += "VelToEnv=\(self.velocityToEnvelope) VelToAttack=\(self.velocityToAttack) VelToDecay1=\(self.velocityToDecay1)"
        return s
    }
}

// MARK: - XML output

extension Filter {
    public var xml: String {
        "<filter mode=\"\(self.mode.xml)\" cutoff=\"\(self.cutoff)\" resonance=\"\(self.resonance)\" level=\"\(self.level)\">\(self.envelope.xml)</filter>"
    }
}

extension Filter.Mode {
    public var xml: String {
        switch self {
        case .lowPass:
            return "low-pass"
        case .highPass:
            return "high-pass"
        }
    }
}

extension Filter.Envelope {
    public var xml: String {
        """
<envelope>
    <attack-time>\(self.attackTime)</attack-time>
    <decay1>
        <time>\(self.decay1Time)</time>
        <level>\(self.decay1Level)</level>
    </decay1>
    <decay2>
        <time>\(self.decay2Time)</time>
        <level>\(self.decay2Level)</level>
    </decay2>
    <release-time>\(self.releaseTime)</release-time>
    <key-scaling-to-attack>\(self.keyScalingToAttack)</key-scaling-to-attack>
    <key-scaling-to-decay1>\(self.keyScalingToDecay1)</key-scaling-to-decay1>
    <velocity-to-envelope>\(self.velocityToEnvelope)</velocity-to-envelope>
    <velocity-to-attack>\(self.velocityToAttack)</velocity-to-attack>
    <velocity-to-decay1>\(self.velocityToDecay1)</velocity-to-decay1>
</envelope>
"""
    }
}
