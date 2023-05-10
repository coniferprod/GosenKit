import SyxPack

/// Amplifier (DCA)
public struct Amplifier: Codable {
    /// Amplifier envelope
    public struct Envelope: Codable, Equatable {
        // All values are 0...127
        public var attackTime: Int
        public var decay1Time: Int
        public var decay1Level: Int
        public var decay2Time: Int
        public var decay2Level: Int
        public var releaseTime: Int
        
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
            self.attackTime = attackTime
            self.decay1Time = decay1Time
            self.decay1Level = decay1Level
            self.decay2Time = decay2Time
            self.decay2Level = decay2Level
            self.releaseTime = releaseTime
        }
        
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
    public struct Modulation: Codable {
        /// Key scaling control for amplifier modulation.
        public struct KeyScalingControl: Codable {
            // All values are -63...+63
            public var level: Int
            public var attackTime: Int
            public var decay1Time: Int
            public var release: Int
            
            public init() {
                level = 0
                attackTime = 0
                decay1Time = 0
                release = 0
            }
            
            public init(level: Int, attackTime: Int, decay1Time: Int, release: Int) {
                self.level = level
                self.attackTime = attackTime
                self.decay1Time = decay1Time
                self.release = release
            }
            
            public static func parse(from data: ByteArray) -> Result<KeyScalingControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                
                var temp = KeyScalingControl()
                
                b = data.next(&offset)
                temp.level = Int(b) - 64
                
                b = data.next(&offset)
                temp.attackTime = Int(b) - 64
            
                b = data.next(&offset)
                temp.decay1Time = Int(b) - 64
                
                b = data.next(&offset)
                temp.release = Int(b) - 64
                
                return .success(temp)
            }
        }

        /// Velocity control for amplifier modulation.
        public struct VelocityControl: Codable {
            // Almost the same as KeyScalingControl, but level is positive only (0...63),
            // others are -63...+63.
            public var level: Int
            public var attackTime: Int
            public var decay1Time: Int
            public var release: Int
            
            public init() {
                level = 0
                attackTime = 0
                decay1Time = 0
                release = 0
            }
            
            public init(level: Int, attackTime: Int, decay1Time: Int, release: Int) {
                self.level = level
                self.attackTime = attackTime
                self.decay1Time = decay1Time
                self.release = release
            }
            
            public static func parse(from data: ByteArray) -> Result<VelocityControl, ParseError> {
                var offset: Int = 0
                var b: Byte = 0
                
                var temp = VelocityControl()
                
                b = data.next(&offset)
                temp.level = Int(b)
                
                b = data.next(&offset)
                temp.attackTime = Int(b) - 64
                
                b = data.next(&offset)
                temp.decay1Time = Int(b) - 64
                
                b = data.next(&offset)
                temp.release = Int(b) - 64
                
                return .success(temp)
            }
        }

        public var keyScalingToEnvelope: KeyScalingControl
        public var velocityToEnvelope: VelocityControl

        public init() {
            keyScalingToEnvelope = KeyScalingControl()
            velocityToEnvelope = VelocityControl()
        }
        
        public static func parse(from data: ByteArray) -> Result<Modulation, ParseError> {
            var offset: Int = 0
            
            var temp = Modulation()
            
            switch KeyScalingControl.parse(from: data.slice(from: offset, length: KeyScalingControl.dataSize)) {
            case .success(let control):
                temp.keyScalingToEnvelope = control
            case .failure(let error):
                return .failure(error)
            }
            
            offset += KeyScalingControl.dataSize
            
            switch VelocityControl.parse(from: data.slice(from: offset, length: VelocityControl.dataSize)) {
            case .success(let control):
                temp.velocityToEnvelope = control
            case .failure(let error):
                return .failure(error)
            }
            
            return .success(temp)
        }
    }

    public var velocityCurve: Int  // store as 1~12
    public var envelope: Envelope
    public var modulation: Modulation
    
    public init() {
        velocityCurve = 1
        envelope = Envelope()
        modulation = Modulation()
    }

    public static func parse(from data: ByteArray) -> Result<Amplifier, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = Amplifier()
        
        b = data.next(&offset)
        temp.velocityCurve = Int(b) + 1  // 0~11 to 1~12

        switch Envelope.parse(from: data.slice(from: offset, length: Envelope.dataSize)) {
        case .success(let env):
            temp.envelope = env
        case .failure(let error):
            return .failure(error)
        }
        offset += Envelope.dataSize

        switch Modulation.parse(from: data.slice(from: offset, length: Modulation.dataSize)) {
        case .success(let mod):
            temp.modulation = mod
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
}

// MARK: - SystemExclusiveData

extension Amplifier.Envelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [attackTime, decay1Time, decay1Level, decay2Time, decay2Level, releaseTime].forEach {
            data.append(Byte($0))
        }
        return data
    }
    
    public var dataLength: Int { return Amplifier.Envelope.dataSize }
    
    public static let dataSize = 6
}

extension Amplifier: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(velocityCurve - 1)) // 0~11
        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: modulation.asData())
        
        return data
    }
    
    public var dataLength: Int { return Amplifier.dataSize }
    
    public static let dataSize = 15
}

extension Amplifier.Modulation: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: keyScalingToEnvelope.asData())
        data.append(contentsOf: velocityToEnvelope.asData())

        return data
    }
    
    public var dataLength: Int {
        return Amplifier.Modulation.dataSize
    }
    
    public static let dataSize = KeyScalingControl.dataSize + VelocityControl.dataSize
}

extension Amplifier.Modulation.KeyScalingControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [level, attackTime, decay1Time, release].forEach {
            data.append(Byte($0 + 64))
        }
        return data
    }
    
    public var dataLength: Int { 4 }
    
    public static let dataSize = 4
}

extension Amplifier.Modulation.VelocityControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        [level, attackTime + 64, decay1Time + 64, release + 64].forEach {
            data.append(Byte($0))
        }
        return data
    }
    
    public var dataLength: Int { 4 }

    public static let dataSize = 4
}

// MARK: - CustomStringConvertible

extension Amplifier: CustomStringConvertible {
    public var description: String {
        var result = ""
        
        result += "Velocity Curve = \(self.velocityCurve)\n"
        result += "Envelope = \(self.envelope)\n"
        result += "Modulation = \(self.modulation)"
        
        return result
    }
}

extension Amplifier.Envelope: CustomStringConvertible {
    public var description: String {
        var s = ""
        s += "AttackTime=\(attackTime) Decay1Time=\(decay1Time) Decay1Level=\(decay1Level)\n"
        s += "Decay2Time=\(decay2Time) Decay2Level=\(decay2Level) ReleaseTime=\(releaseTime)\n"
        return s
    }
}

extension Amplifier.Modulation: CustomStringConvertible {
    public var description: String {
        var result = ""
        
        result += "Key Scaling To Env = \(self.keyScalingToEnvelope)\n"
        result += "Velocity To Env = \(self.velocityToEnvelope)\n"
        
        return result
    }
}

extension Amplifier.Modulation.KeyScalingControl: CustomStringConvertible {
    public var description: String {
        var result = ""
        
        result += "Level=\(self.level) AttackTime=\(self.attackTime) Decay1Time=\(self.decay1Time) Release=\(self.release)"
        
        return result
    }
}

extension Amplifier.Modulation.VelocityControl: CustomStringConvertible {
    public var description: String {
        var result = ""
        
        result += "Level=\(self.level) AttackTime=\(self.attackTime) Decay1Time=\(self.decay1Time) Release=\(self.release)"
        
        return result
    }
}
