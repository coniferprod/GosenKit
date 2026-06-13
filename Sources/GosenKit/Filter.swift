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
            attackTime = 0
            decay1Time = 0
            decay1Level = 0
            decay2Time = 0
            decay2Level = 0
            releaseTime = 0
            keyScalingToAttack = 0
            keyScalingToDecay1 = 0
            velocityToEnvelope = 0
            velocityToAttack = 0
            velocityToDecay1 = 0
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
        isActive = false
        cutoff = 127
        resonance = 0
        mode = .lowPass
        velocityCurve = 1
        level = 7
        keyScalingToCutoff = 0
        velocityToCutoff = 0
        envelopeDepth = 0
        envelope = Envelope()
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
            isActive ? 0 : 1,
            mode.index,
            velocityCurve + velocityCurveOffset,
            resonance,
            level,
            cutoff,
            keyScalingToCutoff + offset,
            velocityToCutoff + offset,
            envelopeDepth + offset,
        ]
        .forEach {
            data.append(Byte($0))
        }

        data.append(contentsOf: envelope.asData())
        
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
            attackTime,
            decay1Time,
            decay1Level + offset,
            decay2Time,
            decay2Level + offset,
            releaseTime,
            keyScalingToAttack + offset,
            keyScalingToDecay1 + offset,
            velocityToEnvelope + offset,
            velocityToAttack + offset,
            velocityToDecay1 + offset,
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
        s += "Active=" + (isActive ? "YES" : "NO") + " Mode=\(mode)\n"
        s += "Cutoff=\(cutoff) Resonance=\(resonance) Level=\(level)\n"
        s += "Vel.Curve=\(velocityCurve) KStoCut=\(keyScalingToCutoff) VelToCut=\(velocityToCutoff)\n"
        s += "Env.Depth=\(envelopeDepth)\n"
        s += "\nFilter Envelope:\n\(envelope)\n"
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
        s += "attackTime=\(attackTime) decay1Time=\(decay1Time) decay1Level=\(decay1Level)\n"
        s += "decay2Time=\(decay2Time) decay2Level=\(decay2Level) releaseTime=\(releaseTime)\n"
        s += "KSToAttack=\(keyScalingToAttack) KSToDecay=\(keyScalingToDecay1)\n"
        s += "VelToEnv=\(velocityToEnvelope) VelToAttack=\(velocityToAttack) VelToDecay1=\(velocityToDecay1)"
        return s
    }
}

// MARK: - XML output

extension Filter {
    public var xml: String {
        "<filter mode=\"\(mode.xml)\" cutoff=\"\(cutoff)\" resonance=\"\(resonance)\" level=\"\(level)\">\(envelope.xml)</filter>"
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
