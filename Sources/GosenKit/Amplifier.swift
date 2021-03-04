import Foundation

public struct AmplifierEnvelope: Codable {
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
        
        b = d[offset]
        attackTime = Int(b)
        offset += 1
        
        b = d[offset]
        decay1Time = Int(b)
        offset += 1
        
        b = d[offset]
        decay1Level = Int(b)
        offset += 1
        
        b = d[offset]
        decay2Time = Int(b)
        offset += 1
        
        b = d[offset]
        decay2Level = Int(b)
        offset += 1
        
        b = d[offset]
        releaseTime = Int(b)
        offset += 1
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(attackTime))
        data.append(Byte(decay1Time))
        data.append(Byte(decay1Level))
        data.append(Byte(decay2Time))
        data.append(Byte(decay2Level))
        data.append(Byte(releaseTime))

        return data
    }
}

let organAmplifierEnvelope = AmplifierEnvelope(attackTime: 0, decay1Time: 0, decay1Level: 127, decay2Time: 0, decay2Level: 127, releaseTime: 0)

public struct AmplifierKeyScalingControl: Codable {
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
    
    public init(data d: ByteArray) {
        //print("Amplifier key scaling control data (\(d.count) bytes): \(d.hexDump)")
        
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        level = Int(b) - 64
        offset += 1
        
        b = d[offset]
        attackTime = Int(b) - 64
        offset += 1
    
        b = d[offset]
        decay1Time = Int(b) - 64
        offset += 1
        
        b = d[offset]
        release = Int(b) - 64
        offset += 1
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(level + 64))
        data.append(Byte(attackTime + 64))
        data.append(Byte(decay1Time + 64))
        data.append(Byte(release + 64))
        
        return data
    }
}

// Almost the same as AmplifierKeyScalingControl, but level is positive only (0...63)
public struct AmplifierVelocityControl: Codable {
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
    
    public init(data d: ByteArray) {
        //print("Amplifier velocity control data (\(d.count) bytes): \(d.hexDump)")
        
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        level = Int(b)
        offset += 1
        
        b = d[offset]
        attackTime = Int(b) - 64
        offset += 1
        
        b = d[offset]
        decay1Time = Int(b) - 64
        offset += 1
        
        b = d[offset]
        release = Int(b) - 64
        offset += 1
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(level))
        data.append(Byte(attackTime + 64))
        data.append(Byte(decay1Time + 64))
        data.append(Byte(release + 64))
        
        return data
    }
}

public struct AmplifierModulationSettings: Codable {
    public var keyScalingToEnvelope: AmplifierKeyScalingControl
    public var velocityToEnvelope: AmplifierVelocityControl

    static let dataLength = AmplifierKeyScalingControl.dataLength + AmplifierVelocityControl.dataLength
    
    public init() {
        keyScalingToEnvelope = AmplifierKeyScalingControl()
        velocityToEnvelope = AmplifierVelocityControl()
    }
    
    public init(data d: ByteArray) {
        //print("Amplifier modulation data (\(d.count) bytes): \(d.hexDump)")
        
        var offset: Int = 0
        
        keyScalingToEnvelope = AmplifierKeyScalingControl(data: ByteArray(d[offset ..< offset + AmplifierKeyScalingControl.dataLength]))
        offset += AmplifierKeyScalingControl.dataLength
        
        velocityToEnvelope = AmplifierVelocityControl(data: ByteArray(d[offset ..< offset + AmplifierVelocityControl.dataLength]))
    }
    
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: keyScalingToEnvelope.asData())
        data.append(contentsOf: velocityToEnvelope.asData())

        return data
    }
}

public struct Amplifier: Codable {
    public var velocityCurve: Int  // store as 1~12
    public var envelope: AmplifierEnvelope
    public var modulation: AmplifierModulationSettings
    
    static let dataLength = 15
    
    public init() {
        velocityCurve = 1
        envelope = AmplifierEnvelope()
        modulation = AmplifierModulationSettings()
    }

    public init(data d: ByteArray) {
        //print("Amplifier data (\(d.count) bytes): \(d.hexDump)")
        
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        velocityCurve = Int(b) + 1  // 0~11 to 1~12
        offset += 1
        
        print("Start amplifier envelope, offset = \(offset)")
        envelope = AmplifierEnvelope(data: ByteArray(d[offset ..< offset + AmplifierEnvelope.dataLength]))
        offset += AmplifierEnvelope.dataLength
        
        print("Start amplifier envelope modulation, offset = \(offset)")
        modulation = AmplifierModulationSettings(data: ByteArray(d[offset ..< offset + AmplifierModulationSettings.dataLength]))
    }

    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(velocityCurve - 1)) // 0~11
        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: modulation.asData())
        
        return data
    }
}
