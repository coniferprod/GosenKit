import SyxPack
import ByteKit

public enum EnvelopeLevelDomain: IntegerDomain {
    public static let first = 0
    public static let last = 127
    public static let defaultValue = 0
}

public enum EnvelopeTimeDomain: IntegerDomain {
    public static let first = 0
    public static let last = 127
    public static let defaultValue = 0
}

public enum VelocityCurveDomain: IntegerDomain {
    public static let first = 1
    public static let last = 12
    public static let defaultValue = 1
}

public typealias EnvelopeLevel = Integer<EnvelopeLevelDomain>
public typealias EnvelopeTime = Integer<EnvelopeTimeDomain>
public typealias VelocityCurve = Integer<VelocityCurveDomain>

/// Amplifier (DCA)
public struct Amplifier {
    /// Amplifier envelope
    public struct Envelope: Equatable {
        // All values are 0...127
        public var attackTime: EnvelopeTime
        public var decay1Time: EnvelopeTime
        public var decay1Level: EnvelopeLevel
        public var decay2Time: EnvelopeTime
        public var decay2Level: EnvelopeLevel
        public var releaseTime: EnvelopeTime
        
        /// Initialize amplifier envelope with default values.
        public init() {
            attackTime = EnvelopeTime()
            decay1Time = EnvelopeTime()
            decay1Level = EnvelopeLevel(127)
            decay2Time = EnvelopeTime()
            decay2Level = EnvelopeLevel(127)
            releaseTime = EnvelopeTime()
        }
        
        /// Initialize amplifier envelope with explicit values.
        public init(attackTime: Int, decay1Time: Int, decay1Level: Int, decay2Time: Int, decay2Level: Int, releaseTime: Int) {
            self.attackTime = EnvelopeTime(attackTime)
            self.decay1Time = EnvelopeTime(decay1Time)
            self.decay1Level = EnvelopeLevel(decay1Level)
            self.decay2Time = EnvelopeTime(decay2Time)
            self.decay2Level = EnvelopeLevel(decay2Level)
            self.releaseTime = EnvelopeTime(releaseTime)
        }
        
        /// Parse the amplifier envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attackTime = EnvelopeTime(Int(b))
            
            b = data.next(&offset)
            temp.decay1Time = EnvelopeTime(Int(b))
            
            b = data.next(&offset)
            temp.decay1Level = EnvelopeLevel(Int(b))
            
            b = data.next(&offset)
            temp.decay2Time = EnvelopeTime(Int(b))
            
            b = data.next(&offset)
            temp.decay2Level = EnvelopeLevel(Int(b))
            
            b = data.next(&offset)
            temp.releaseTime = EnvelopeTime(Int(b))
            
            return .success(temp)
        }
    }

    /// Amplifier modulation settings.
    public struct Modulation {
        /// Key scaling control for amplifier modulation.
        public struct KeyScalingControl {
            // All values are -63...+63
            public var level: SignedLevel
            public var attackTime: SignedLevel
            public var decay1Time: SignedLevel
            public var release: SignedLevel
            
            /// Initializes key scaling control with default values.
            public init() {
                level = SignedLevel(0)
                attackTime = SignedLevel(0)
                decay1Time = SignedLevel(0)
                release = SignedLevel(0)
            }
            
            /// Initializes key scaling control with specific `Int` values.
            public init(level: Int, attackTime: Int, decay1Time: Int, release: Int) {
                self.level = SignedLevel(level)
                self.attackTime = SignedLevel(attackTime)
                self.decay1Time = SignedLevel(decay1Time)
                self.release = SignedLevel(release)
            }
            
            /// Parse the key scaling control value from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<KeyScalingControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                var value: Int = 0
                var descriptor = descriptors[.keyScalingControl]!
                
                var temp = KeyScalingControl()
                
                b = data.next(&offset)
                temp.level = Int(b) + descriptor.incomingOffset
                
                b = data.next(&offset)
                temp.attackTime = Int(b) + descriptor.incomingOffset

                b = data.next(&offset)
                temp.decay1Time = Int(b) + descriptor.incomingOffset
                
                b = data.next(&offset)
                temp.release = Int(b) + descriptor.incomingOffset
                
                return .success(temp)
            }
        }

        /// Velocity control for amplifier modulation.
        /// Almost the same as KeyScalingControl, but the level
        /// is positive only (0...63), and times are -63...+63.
        /// Therefore these types are defined inside this struct,
        /// not as top-level package types.
        public struct VelocityControl {
            // Level is 0...63
            public var level: UnsignedLevel
            
            // Times are -63...63
            public var attackTime: SignedLevel
            public var decay1Time: SignedLevel
            public var release: SignedLevel
            
            /// Initializes a velocity control with default values.
            public init() {
                self.level = UnsignedLevel(0)
                self.attackTime = SignedLevel(0)
                self.decay1Time = SignedLevel(0)
                self.release = SignedLevel(0)
            }
            
            /// Initializes a velocity control with specific `Int` values.
            public init(level: Int, attackTime: Int, decay1Time: Int, release: Int) {
                self.level = UnsignedLevel(level)
                self.attackTime = SignedLevel(attackTime)
                self.decay1Time = SignedLevel(decay1Time)
                self.release = SignedLevel(release)
            }
            
            /// Parse the velocity control from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<VelocityControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                var value: Int = 0
                let descriptor = descriptors[.velocityControlTime]!
                
                var temp = VelocityControl()
                
                b = data.next(&offset)
                temp.level = UnsignedLevel(Int(b))
                
                b = data.next(&offset)
                temp.attackTime = Int(b) + descriptor.incomingOffset
                
                b = data.next(&offset)
                temp.decay1Time = Int(b) + descriptor.incomingOffset

                b = data.next(&offset)
                temp.release = Int(b) + descriptor.incomingOffset

                return .success(temp)
            }
        }

        public var keyScalingToEnvelope: KeyScalingControl
        public var velocityToEnvelope: VelocityControl

        public init() {
            self.keyScalingToEnvelope = KeyScalingControl()
            self.velocityToEnvelope = VelocityControl()
        }
        
        /// Parse the modulation from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Modulation, ParseError> {
            var offset: Int = 0
            
            var temp = Modulation()
            
            var size = KeyScalingControl.dataSize
            switch KeyScalingControl.parse(from: data.slice(from: offset, length: size)) {
            case .success(let control):
                temp.keyScalingToEnvelope = control
            case .failure(let error):
                return .failure(error)
            }
            
            offset += size
            
            size = VelocityControl.dataSize
            switch VelocityControl.parse(from: data.slice(from: offset, length: size)) {
            case .success(let control):
                temp.velocityToEnvelope = control
            case .failure(let error):
                return .failure(error)
            }
            
            return .success(temp)
        }
    }

    public var velocityCurve: VelocityCurve  // 1...12
    public var envelope: Envelope
    public var modulation: Modulation
    
    public init() {
        velocityCurve = VelocityCurve(1)
        envelope = Envelope()
        modulation = Modulation()
    }

    /// Parse the amplifier from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<Amplifier, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        var descriptor = descriptors[.velocityCurve]!
        
        var temp = Amplifier()
        
        b = data.next(&offset)
        temp.velocityCurve = VelocityCurve(Int(b) + 1) // 0~11 to 1~12

        var size = Envelope.dataSize
        switch Envelope.parse(from: data.slice(from: offset, length: size)) {
        case .success(let env):
            temp.envelope = env
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        size = Modulation.dataSize
        switch Modulation.parse(from: data.slice(from: offset, length: size)) {
        case .success(let mod):
            temp.modulation = mod
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData conformance

extension Amplifier.Envelope: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this amplifier envelope.
    public func asData() -> ByteArray {
        // All values appear as themselves in SysEx,
        // no need for adjustment. Just convert them
        // all to Byte.
        [
            attackTime,
            decay1Time,
            decay1Level,
            decay2Time,
            decay2Level,
            releaseTime,
        ]
        .map { Byte($0) }
    }
    
    public var dataLength: Int { Amplifier.Envelope.dataSize }
    
    public static let dataSize = 6
}

extension Amplifier: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this amplifier.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        let descriptor = descriptors[.velocityCurve]!
        data.append(Byte(self.velocityCurve + descriptor.outgoingOffset)) // 0~11
        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: modulation.asData())
        
        return data
    }
    
    public var dataLength: Int { Amplifier.dataSize }
    
    public static let dataSize = 15
}

extension Amplifier.Modulation: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: keyScalingToEnvelope.asData())
        data.append(contentsOf: velocityToEnvelope.asData())

        return data
    }
    
    public var dataLength: Int { Amplifier.Modulation.dataSize }
    
    public static let dataSize = KeyScalingControl.dataSize + VelocityControl.dataSize
}

extension Amplifier.Modulation.KeyScalingControl: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation key scaling control.
    public func asData() -> ByteArray {
        var descriptor = descriptors[.keyScalingControl]!

        return [
            self.level + descriptor.outgoingOffset,
            self.attackTime + descriptor.outgoingOffset,
            self.decay1Time + descriptor.outgoingOffset,
            self.release + descriptor.outgoingOffset,
        ].map { Byte($0) }
    }
    
    public var dataLength: Int { 4 }
    
    public static let dataSize = 4
}

extension Amplifier.Modulation.VelocityControl: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation velocity control.
    public func asData() -> ByteArray {
        let descriptor = descriptors[.velocityControlTime]!
        return [
            self.level,
            self.attackTime + descriptor.outgoingOffset,
            self.decay1Time + descriptor.outgoingOffset,
            self.release + descriptor.outgoingOffset,
        ].map { Byte($0) }
    }
    
    public var dataLength: Int { Self.dataSize }

    public static let dataSize = 4
}

// MARK: - CustomStringConvertible conformance

extension Amplifier: CustomStringConvertible {
    /// Gets a printable description of this amplifier.
    public var description: String {
        var result = ""
        
        result += "Velocity Curve = \(self.velocityCurve)\n"
        result += "Envelope = \(self.envelope)\n"
        result += "Modulation:\n\(self.modulation)"
        
        return result
    }
}

extension Amplifier.Envelope: CustomStringConvertible {
    /// Gets a printable description of this amplifier envelope.
    public var description: String {
        var s = ""
        s += "AttackTime=\(attackTime) Decay1Time=\(decay1Time) Decay1Level=\(decay1Level)\n"
        s += "Decay2Time=\(decay2Time) Decay2Level=\(decay2Level) ReleaseTime=\(releaseTime)\n"
        return s
    }
}

extension Amplifier.Modulation: CustomStringConvertible {
    /// Gets a printable description of this amplifier modulation.
    public var description: String {
        var result = ""
        
        result += "KS To Env = \(self.keyScalingToEnvelope)\n"
        result += "Vel To Env = \(self.velocityToEnvelope)\n"
        
        return result
    }
}

extension Amplifier.Modulation.KeyScalingControl: CustomStringConvertible {
    /// Gets a printable description of this amplifier modulation key scaling control.
    public var description: String {
        var result = ""
        
        result += "Level=\(self.level) AttackTime=\(self.attackTime) Decay1Time=\(self.decay1Time) Release=\(self.release)"
        
        return result
    }
}

extension Amplifier.Modulation.VelocityControl: CustomStringConvertible {
    /// Gets a printable description of this amplifier modulation velocity control.
    public var description: String {
        var result = ""
        
        result += "Level=\(self.level) AttackTime=\(self.attackTime) Decay1Time=\(self.decay1Time) Release=\(self.release)"
        
        return result
    }
}

// MARK: - XML output

extension Amplifier {
    public var xml: String {
"""
<amplifier>
    <velocity-curve>\(self.velocityCurve)</velocity-curve>
    \(self.envelope.xml)
    \(self.modulation.xml)
</amplifier>
"""
    }
}

extension Amplifier.Envelope {
    public var xml: String {
"""
<envelope>
    <attack-time>\(self.attackTime)</attack-time>
    <decay1-time>\(self.decay1Time)</decay1-time>
    <decay1-level>\(self.decay1Level)</decay1-level>
    <decay2-time>\(self.decay2Time)</decay2-time>
    <decay2-level>\(self.decay2Level)</decay2-level>
    <release-time>\(self.releaseTime)</release-time>
</envelope>
"""
    }
}

extension Amplifier.Modulation {
    public var xml: String {
        "<modulation>\(self.keyScalingToEnvelope.xml)\(self.velocityToEnvelope.xml)</modulation>"
    }
}

extension Amplifier.Modulation.KeyScalingControl {
    public var xml: String {
"""
<key-scaling>
    <level>\(self.level)</level>
    <attack-time>\(self.attackTime)</attack-time>
    <decay1-time>\(self.decay1Time)</decay1-time>
    <release-time>\(self.release)</release-time>
</key-scaling>
"""
    }
}

extension Amplifier.Modulation.VelocityControl {
    public var xml: String {
"""
<velocity>
    <level>\(self.level)</level>
    <attack-time>\(self.attackTime)</attack-time>
    <decay1-time>\(self.decay1Time)</decay1-time>
    <release-time>\(self.release)</release-time>
</velocity>
"""
    }
}
