import Foundation

struct AmplifierEnvelope: Codable {
    var attackTime: Int
    var decay1Time: Int
    var decay1Level: Int
    var decay2Time: Int
    var decay2Level: Int
    var releaseTime: Int
    
    static let dataLength = 6
    
    init() {
        attackTime = 0
        decay1Time = 0
        decay1Level = 127
        decay2Time = 0
        decay2Level = 127
        releaseTime = 0
    }
    
    init(attackTime: Int, decay1Time: Int, decay1Level: Int, decay2Time: Int, decay2Level: Int, releaseTime: Int) {
        self.attackTime = attackTime
        self.decay1Time = decay1Time
        self.decay1Level = decay1Level
        self.decay2Time = decay2Time
        self.decay2Level = decay2Level
        self.releaseTime = releaseTime
    }
    
    init(data d: ByteArray) {
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
    
    func asData() -> ByteArray {
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

struct AmplifierKeyScalingControl: Codable {
    var level: Int
    var attackTime: Int
    var decay1Time: Int
    var release: Int
    
    static let dataLength = 4

    init() {
        level = 0
        attackTime = 0
        decay1Time = 0
        release = 0
    }
    
    init(data d: ByteArray) {
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
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(level + 64))
        data.append(Byte(attackTime + 64))
        data.append(Byte(decay1Time + 64))
        data.append(Byte(release + 64))
        
        return data
    }
}

// Almost the same as AmplifierKeyScalingControl, but level is positive only (0...63)
struct AmplifierVelocityControl: Codable {
    var level: Int
    var attackTime: Int
    var decay1Time: Int
    var release: Int
    
    static let dataLength = 4
    
    init() {
        level = 0
        attackTime = 0
        decay1Time = 0
        release = 0
    }
    
    init(data d: ByteArray) {
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
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(level))
        data.append(Byte(attackTime + 64))
        data.append(Byte(decay1Time + 64))
        data.append(Byte(release + 64))
        
        return data
    }
}

struct AmplifierModulationSettings: Codable {
    var keyScalingToEnvelope: AmplifierKeyScalingControl
    var velocityToEnvelope: AmplifierVelocityControl

    static let dataLength = AmplifierKeyScalingControl.dataLength + AmplifierVelocityControl.dataLength
    
    init() {
        keyScalingToEnvelope = AmplifierKeyScalingControl()
        velocityToEnvelope = AmplifierVelocityControl()
    }
    
    init(data d: ByteArray) {
        //print("Amplifier modulation data (\(d.count) bytes): \(d.hexDump)")
        
        var offset: Int = 0
        
        keyScalingToEnvelope = AmplifierKeyScalingControl(data: ByteArray(d[offset ..< offset + AmplifierKeyScalingControl.dataLength]))
        offset += AmplifierKeyScalingControl.dataLength
        
        velocityToEnvelope = AmplifierVelocityControl(data: ByteArray(d[offset ..< offset + AmplifierVelocityControl.dataLength]))
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: keyScalingToEnvelope.asData())
        data.append(contentsOf: velocityToEnvelope.asData())

        return data
    }
}

struct Amplifier: Codable {
    var velocityCurve: Int  // store as 1~12
    var envelope: AmplifierEnvelope
    var modulation: AmplifierModulationSettings
    
    static let dataLength = 15
    
    init() {
        velocityCurve = 1
        envelope = AmplifierEnvelope()
        modulation = AmplifierModulationSettings()
    }

    init(data d: ByteArray) {
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
    

    func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(velocityCurve - 1)) // 0~11
        data.append(contentsOf: envelope.asData())
        data.append(contentsOf: modulation.asData())
        
        return data
    }
}
