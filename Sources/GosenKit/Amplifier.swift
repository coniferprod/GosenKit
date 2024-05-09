import SyxPack
import ByteKit

/// Amplifier (DCA)
public struct Amplifier {
    /// Amplifier envelope
    public struct Envelope: Equatable {
        /// Amplifier envelope time
        public struct Time {
            private var _value: Int
        }
        
        /// Amplifier envelope level
        public struct Level {
            private var _value: Int
        }

        // All values are 0...127
        public var attackTime: Time
        public var decay1Time: Time
        public var decay1Level: Level
        public var decay2Time: Time
        public var decay2Level: Level
        public var releaseTime: Time
        
        /// Initialize amplifier envelope with default values.
        public init() {
            attackTime = 0
            decay1Time = 0
            decay1Level = 127
            decay2Time = 0
            decay2Level = 127
            releaseTime = 0
        }
        
        /// Initialize amplifier envelope with explicit values.
        public init(attackTime: Int, decay1Time: Int, decay1Level: Int, decay2Time: Int, decay2Level: Int, releaseTime: Int) {
            self.attackTime = Time(attackTime)
            self.decay1Time = Time(decay1Time)
            self.decay1Level = Level(decay1Level)
            self.decay2Time = Time(decay2Time)
            self.decay2Level = Level(decay2Level)
            self.releaseTime = Time(releaseTime)
        }
        
        /// Parse the amplifier envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<Envelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0

            var temp = Envelope()
            
            b = data.next(&offset)
            temp.attackTime = Time(Int(b))
            
            b = data.next(&offset)
            temp.decay1Time = Time(Int(b))
            
            b = data.next(&offset)
            temp.decay1Level = Level(Int(b))
            
            b = data.next(&offset)
            temp.decay2Time = Time(Int(b))
            
            b = data.next(&offset)
            temp.decay2Level = Level(Int(b))
            
            b = data.next(&offset)
            temp.releaseTime = Time(Int(b))
            
            return .success(temp)
        }
        
        /// Compares two amplifier envelopes.
        public static func == (lhs: Amplifier.Envelope, rhs: Amplifier.Envelope) -> Bool {
            return 
                lhs.attackTime == rhs.attackTime
                && lhs.decay1Time == rhs.decay1Time
                && lhs.decay1Level == rhs.decay1Level
                && lhs.decay2Time == rhs.decay2Time
                && lhs.decay2Level == rhs.decay2Level
                && lhs.releaseTime == rhs.releaseTime
        }
    }

    /// Amplifier modulation settings.
    public struct Modulation {
        /// Key scaling control for amplifier modulation.
        public struct KeyScalingControl {
            public struct Level {
                private var _value: Int
            }

            public struct Time {
                private var _value: Int
            }

            // All values are -63...+63
            public var level: Level
            public var attackTime: Time
            public var decay1Time: Time
            public var release: Time
            
            public init() {
                level = 0
                attackTime = 0
                decay1Time = 0
                release = 0
            }
            
            public init(level: Int, attackTime: Int, decay1Time: Int, release: Int) {
                self.level = Level(level)
                self.attackTime = Time(attackTime)
                self.decay1Time = Time(decay1Time)
                self.release = Time(release)
            }
            
            /// Parse the key scaling control value from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<KeyScalingControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                
                var temp = KeyScalingControl()
                
                b = data.next(&offset)
                temp.level = Level(Int(b) - 64)
                
                b = data.next(&offset)
                temp.attackTime = Time(Int(b) - 64)
            
                b = data.next(&offset)
                temp.decay1Time = Time(Int(b) - 64)
                
                b = data.next(&offset)
                temp.release = Time(Int(b) - 64)
                
                return .success(temp)
            }
        }

        /// Velocity control for amplifier modulation.
        public struct VelocityControl {
            public struct Level {
                private var _value: Int
            }

            public struct Time {
                private var _value: Int
            }

            // Almost the same as KeyScalingControl, but the level
            // is positive only (0...63), others are -63...+63.
            // So these are types defined inside this struct,
            // not top-level package types.
            public var level: Level
            public var attackTime: Time
            public var decay1Time: Time
            public var release: Time
            
            public init() {
                level = 0
                attackTime = 0
                decay1Time = 0
                release = 0
            }
            
            public init(level: Int, attackTime: Int, decay1Time: Int, release: Int) {
                self.level = Level(level)
                self.attackTime = Time(attackTime)
                self.decay1Time = Time(decay1Time)
                self.release = Time(release)
            }
            
            /// Parse the velocity control from MIDI System Exclusive data.
            public static func parse(from data: ByteArray) -> Result<VelocityControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                
                var temp = VelocityControl()
                
                b = data.next(&offset)
                temp.level = Level(Int(b))
                
                b = data.next(&offset)
                temp.attackTime = Time(Int(b) - 64)
                
                b = data.next(&offset)
                temp.decay1Time = Time(Int(b) - 64)
                
                b = data.next(&offset)
                temp.release = Time(Int(b) - 64)
                
                return .success(temp)
            }
        }

        public var keyScalingToEnvelope: KeyScalingControl
        public var velocityToEnvelope: VelocityControl

        public init() {
            keyScalingToEnvelope = KeyScalingControl()
            velocityToEnvelope = VelocityControl()
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

    public var velocityCurve: VelocityCurve
    public var envelope: Envelope
    public var modulation: Modulation
    
    public init() {
        velocityCurve = 1
        envelope = Envelope()
        modulation = Modulation()
    }

    /// Parse the amplifier from MIDI System Exclusive data.
    public static func parse(from data: ByteArray) -> Result<Amplifier, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = Amplifier()
        
        b = data.next(&offset)
        temp.velocityCurve = VelocityCurve(Int(b) + 1)  // 0~11 to 1~12

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
        var data = ByteArray()
        
        [
            attackTime.value,
            decay1Time.value,
            decay1Level.value,
            decay2Time.value, 
            decay2Level.value,
            releaseTime.value
        ]
        .forEach {
            data.append(Byte($0))
        }
        
        return data
    }
    
    public var dataLength: Int { Amplifier.Envelope.dataSize }
    
    public static let dataSize = 6
}

extension Amplifier: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this amplifier.
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(velocityCurve.value - 1)) // 0~11
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
        var data = ByteArray()
        [
            level.value,
            attackTime.value,
            decay1Time.value,
            release.value
        ]
        .forEach {
            data.append(Byte($0 + 64))
        }
        return data
    }
    
    public var dataLength: Int { 4 }
    
    public static let dataSize = 4
}

extension Amplifier.Modulation.VelocityControl: SystemExclusiveData {
    /// Gets the MIDI System Exclusive data for this modulation velocity control.
    public func asData() -> ByteArray {
        var data = ByteArray()
        [
            level.value,
            attackTime.value + 64,
            decay1Time.value + 64,
            release.value + 64
        ]
        .forEach {
            data.append(Byte($0))
        }
        return data
    }
    
    public var dataLength: Int { 4 }

    public static let dataSize = 4
}

// MARK: - CustomStringConvertible conformance

extension Amplifier: CustomStringConvertible {
    /// Gets a printable description of this amplifier.
    public var description: String {
        var result = ""
        
        result += "Velocity Curve = \(self.velocityCurve.value)\n"
        result += "Envelope = \(self.envelope)\n"
        result += "Modulation:\n\(self.modulation)"
        
        return result
    }
}

extension Amplifier.Envelope: CustomStringConvertible {
    /// Gets a printable description of this amplifier envelope.
    public var description: String {
        var s = ""
        s += "AttackTime=\(attackTime.value) Decay1Time=\(decay1Time.value) Decay1Level=\(decay1Level.value)\n"
        s += "Decay2Time=\(decay2Time.value) Decay2Level=\(decay2Level.value) ReleaseTime=\(releaseTime.value)\n"
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
        
        result += "Level=\(self.level.value) AttackTime=\(self.attackTime.value) Decay1Time=\(self.decay1Time.value) Release=\(self.release.value)"
        
        return result
    }
}

extension Amplifier.Modulation.VelocityControl: CustomStringConvertible {
    /// Gets a printable description of this amplifier modulation velocity control.
    public var description: String {
        var result = ""
        
        result += "Level=\(self.level.value) AttackTime=\(self.attackTime.value) Decay1Time=\(self.decay1Time.value) Release=\(self.release.value)"
        
        return result
    }
}

// MARK: - RangedInt conformance

extension Amplifier.Envelope.Time: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Envelope.Level: RangedInt {
    public static let range: ClosedRange<Int> = 0...127

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Envelope.Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Envelope.Time: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.KeyScalingControl.Time: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.KeyScalingControl.Time: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.KeyScalingControl.Level: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.KeyScalingControl.Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.VelocityControl.Time: RangedInt {
    public static let range: ClosedRange<Int> = -63...63

    public static let defaultValue = 0

    public var value: Int {
        return _value
    }

    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.VelocityControl.Time: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.VelocityControl.Level: RangedInt {
    public static let range: ClosedRange<Int> = 0...63

    public static let defaultValue = 0

    public var value: Int {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range")

        return _value
    }

    public init() {
        _value = Self.defaultValue
    }

    public init(_ value: Int) {
        _value = Self.range.clamp(value)
    }
}

extension Amplifier.Modulation.VelocityControl.Level: ExpressibleByIntegerLiteral {
    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        _value = Self.range.clamp(value)
    }
}
