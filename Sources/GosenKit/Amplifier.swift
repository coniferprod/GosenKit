import SyxPack
import ByteKit

/// Amplifier (DCA)
public struct Amplifier {
    /// Amplifier envelope
    public struct Envelope: Equatable {
        // All values are 0...127
        public var attackTime: Int
        public var decay1Time: Int
        public var decay1Level: Int
        public var decay2Time: Int
        public var decay2Level: Int
        public var releaseTime: Int
        
        /// Initialize amplifier envelope with explicit values.
        public init(attackTime: Int = 0, decay1Time: Int = 0, decay1Level: Int = 127, decay2Time: Int = 0, decay2Level: Int = 127, releaseTime: Int = 0) {
            self.attackTime = attackTime
            self.decay1Time = decay1Time
            self.decay1Level = decay1Level
            self.decay2Time = decay2Time
            self.decay2Level = decay2Level
            self.releaseTime = releaseTime
        }
        
        /// Parse the amplifier envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attackTime = Int(b)
            
            b = data.next(&offset)
            temp.decay1Time = Int(b)
            
            b = data.next(&offset)
            temp.decay1Level = Int(b)
            
            b = data.next(&offset)
            temp.decay2Time = Int(b)
            
            b = data.next(&offset)
            temp.decay2Level = Int(b)
            
            b = data.next(&offset)
            temp.releaseTime = Int(b)
            
            return .success(temp)
        }
    }

    /// Amplifier modulation settings.
    public struct Modulation {
        /// Key scaling control for amplifier modulation.
        public struct KeyScalingControl {
            // All values are -63...+63
            public var level: Int
            public var attackTime: Int
            public var decay1Time: Int
            public var release: Int
            
            /// Initializes key scaling control with specific `Int` values.
            public init(level: Int = 0, attackTime: Int = 0, decay1Time: Int = 0, release: Int = 0) {
                self.level = level
                self.attackTime = attackTime
                self.decay1Time = decay1Time
                self.release = release
            }
            
            /// Parse the key scaling control value from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<KeyScalingControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                let descriptor = descriptors[.keyScalingControl]!
                
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
            public var level: Int
            
            // Times are -63...63
            public var attackTime: Int
            public var decay1Time: Int
            public var release: Int
            
            /// Initializes a velocity control with specific `Int` values.
            public init(level: Int = 0, attackTime: Int = 0, decay1Time: Int = 0, release: Int = 0) {
                self.level = level
                self.attackTime = attackTime
                self.decay1Time = decay1Time
                self.release = release
            }
            
            /// Parse the velocity control from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<VelocityControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                let descriptor = descriptors[.velocityControlTime]!
                
                var temp = VelocityControl()
                
                b = data.next(&offset)
                temp.level = Int(b)
                
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

    public var velocityCurve: Int  // 1...12
    public var envelope: Envelope
    public var modulation: Modulation
    
    public init() {
        self.velocityCurve = 1
        self.envelope = Envelope()
        self.modulation = Modulation()
    }

    /// Parse the amplifier from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<Amplifier, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        let descriptor = descriptors[.velocityCurve]!
        
        var temp = Amplifier()
        
        b = data.next(&offset)
        temp.velocityCurve = Int(b) + descriptor.incomingOffset  // 0~11 to 1~12

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
            self.attackTime,
            self.decay1Time,
            self.decay1Level,
            self.decay2Time,
            self.decay2Level,
            self.releaseTime,
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
        data.append(contentsOf: self.envelope.asData())
        data.append(contentsOf: self.modulation.asData())
        
        return data
    }
    
    public var dataLength: Int { Amplifier.dataSize }
    
    public static let dataSize = 15
}

extension Amplifier.Modulation: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.keyScalingToEnvelope.asData())
        data.append(contentsOf: self.velocityToEnvelope.asData())

        return data
    }
    
    public var dataLength: Int { Amplifier.Modulation.dataSize }
    
    public static let dataSize = KeyScalingControl.dataSize + VelocityControl.dataSize
}

extension Amplifier.Modulation.KeyScalingControl: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation key scaling control.
    public func asData() -> ByteArray {
        let descriptor = descriptors[.keyScalingControl]!
        let offset = descriptor.outgoingOffset

        return [
            self.level + offset,
            self.attackTime + offset,
            self.decay1Time + offset,
            self.release + offset,
        ].map {
            Byte($0)
        }
    }
    
    public var dataLength: Int { 4 }
    
    public static let dataSize = 4
}

extension Amplifier.Modulation.VelocityControl: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation velocity control.
    public func asData() -> ByteArray {
        let descriptor = descriptors[.velocityControlTime]!
        let offset = descriptor.outgoingOffset
        return [
            self.level,
            self.attackTime + offset,
            self.decay1Time + offset,
            self.release + offset,
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
        s += "AttackTime=\(self.attackTime) Decay1Time=\(self.decay1Time) Decay1Level=\(self.decay1Level)\n"
        s += "Decay2Time=\(self.decay2Time) Decay2Level=\(self.decay2Level) ReleaseTime=\(self.releaseTime)\n"
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
