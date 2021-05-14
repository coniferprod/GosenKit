import Foundation

public struct Amplifier: Codable {
    public struct Envelope: Codable {
        // All values are 0...127
        public var attackTime: Int
        public var decay1Time: Int
        public var decay1Level: Int
        public var decay2Time: Int
        public var decay2Level: Int
        public var releaseTime: Int
        
        static let dataLength = 6
        
        public init() {
            attackTime = 0
            decay1Time = 0
            decay1Level = 127
            decay2Time = 0
            decay2Level = 127
            releaseTime = 0
        }
        
        public init(attackTime: Int, decay1Time: Int, decay1Level: Int, decay2Time: Int, decay2Level: Int, releaseTime: Int) {
            self.attackTime = attackTime
            self.decay1Time = decay1Time
            self.decay1Level = decay1Level
            self.decay2Time = decay2Time
            self.decay2Level = decay2Level
            self.releaseTime = releaseTime
        }
        
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
        
        public func asData() -> ByteArray {
            var data = ByteArray()
            [attackTime, decay1Time, decay1Level, decay2Time, decay2Level, releaseTime].forEach {
                data.append(Byte($0))
            }
            return data
        }
    }

    public struct Modulation: Codable {
        public struct KeyScalingControl: Codable {
            // All values are -63...+63
            public var level: Int
            public var attackTime: Int
            public var decay1Time: Int
            public var release: Int
            
            static let dataLength = 4

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
            
            public func asData() -> ByteArray {
                var data = ByteArray()
                [level, attackTime, decay1Time, release].forEach {
                    data.append(Byte($0 + 64))
                }
                return data
            }
        }

        public struct VelocityControl: Codable {
            // Almost the same as KeyScalingControl, but level is positive only (0...63),
            // others are -63...+63.
            public var level: Int
            public var attackTime: Int
            public var decay1Time: Int
            public var release: Int
            
            static let dataLength = 4
            
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
            
            public func asData() -> ByteArray {
                var data = ByteArray()
                [level, attackTime + 64, decay1Time + 64, release + 64].forEach {
                    data.append(Byte($0))
                }
                return data
            }
        }

        public var keyScalingToEnvelope: KeyScalingControl
        public var velocityToEnvelope: VelocityControl

        static let dataLength = KeyScalingControl.dataLength + VelocityControl.dataLength
        
        public init() {
            keyScalingToEnvelope = KeyScalingControl()
            velocityToEnvelope = VelocityControl()
        }
        
        public init(data d: ByteArray) {
            //print("Amplifier modulation data (\(d.count) bytes): \(d.hexDump)")
            
            var offset: Int = 0
            
            keyScalingToEnvelope = KeyScalingControl(data: d.slice(from: offset, length: KeyScalingControl.dataLength))
            offset += KeyScalingControl.dataLength
            
            velocityToEnvelope = VelocityControl(data: d.slice(from: offset, length: VelocityControl.dataLength))
        }
        
        public func asData() -> ByteArray {
            var data = ByteArray()
            
            data.append(contentsOf: keyScalingToEnvelope.asData())
            data.append(contentsOf: velocityToEnvelope.asData())

            return data
        }
    }


    public var velocityCurve: Int  // store as 1~12
    public var envelope: Envelope
    public var modulation: Modulation
    
    static let dataLength = 15
    
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
        envelope = Envelope(data: d.slice(from: offset, length: Envelope.dataLength))
        offset += Envelope.dataLength
        
        //print("Start amplifier envelope modulation, offset = \(offset)")
        modulation = Modulation(data: d.slice(from: offset, length: Modulation.dataLength))
    }

    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(velocityCurve - 1)) // 0~11
        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: modulation.asData())
        
        return data
    }
}
