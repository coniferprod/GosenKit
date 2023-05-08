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
        
        /// Initialize amplifier envelope from MIDI System Exclusive data bytes.
        public init(data d: ByteArray) {
            //print("Amplifier envelope data (\(d.count) bytes): \(d.hexDump)")

            var offset: Int = 0
            var b: Byte = 0
            
            b = d.next(&offset)
            attackTime = Int(b)
            
            b = d.next(&offset)
            decay1Time = Int(b)
            
            b = d.next(&offset)
            decay1Level = Int(b)
            
            b = d.next(&offset)
            decay2Time = Int(b)
            
            b = d.next(&offset)
            decay2Level = Int(b)
            
            b = d.next(&offset)
            releaseTime = Int(b)
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
            
            public init(data d: ByteArray) {
                //print("Amplifier key scaling control data (\(d.count) bytes): \(d.hexDump)")
                
                var offset: Int = 0
                var b: Byte = 0
                
                b = d.next(&offset)
                level = Int(b) - 64
                
                b = d.next(&offset)
                attackTime = Int(b) - 64
            
                b = d.next(&offset)
                decay1Time = Int(b) - 64
                
                b = d.next(&offset)
                release = Int(b) - 64
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
            
            public init(data d: ByteArray) {
                //print("Amplifier velocity control data (\(d.count) bytes): \(d.hexDump)")
                
                var offset: Int = 0
                var b: Byte = 0
                
                b = d.next(&offset)
                level = Int(b)
                
                b = d.next(&offset)
                attackTime = Int(b) - 64
                
                b = d.next(&offset)
                decay1Time = Int(b) - 64
                
                b = d.next(&offset)
                release = Int(b) - 64
            }
        }

        public var keyScalingToEnvelope: KeyScalingControl
        public var velocityToEnvelope: VelocityControl

        public init() {
            keyScalingToEnvelope = KeyScalingControl()
            velocityToEnvelope = VelocityControl()
        }
        
        public init(data d: ByteArray) {
            //print("Amplifier modulation data (\(d.count) bytes): \(d.hexDump)")
            
            var offset: Int = 0
            
            keyScalingToEnvelope = KeyScalingControl(data: d.slice(from: offset, length: KeyScalingControl.dataSize))
            offset += KeyScalingControl.dataSize
            
            velocityToEnvelope = VelocityControl(data: d.slice(from: offset, length: VelocityControl.dataSize))
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

    public init(data d: ByteArray) {
        //print("Amplifier data (\(d.count) bytes): \(d.hexDump)")
        
        var offset: Int = 0
        var b: Byte = 0
        
        b = d.next(&offset)
        velocityCurve = Int(b) + 1  // 0~11 to 1~12
        
        //print("Start amplifier envelope, offset = \(offset)")
        envelope = Envelope(data: d.slice(from: offset, length: Envelope.dataSize))
        offset += Envelope.dataSize
        
        //print("Start amplifier envelope modulation, offset = \(offset)")
        modulation = Modulation(data: d.slice(from: offset, length: Modulation.dataSize))
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
