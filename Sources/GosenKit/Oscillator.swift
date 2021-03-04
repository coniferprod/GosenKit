import Foundation

enum WaveType: String, Codable, CaseIterable {
    case additive
    case pcm
}

enum KeyScalingType: String, Codable, CaseIterable {
    case zeroCent
    case twentyFiveCent
    case thirtyTreeCent
    case fiftyCent
    
    init?(index: Int) {
        switch index {
        case 0: self = .zeroCent
        case 1: self = .twentyFiveCent
        case 2: self = .thirtyTreeCent
        case 3: self = .fiftyCent
        default: return nil
        }
    }
}

struct PitchEnvelope: Codable {
    var start: Int
    var attackTime: Int
    var attackLevel: Int
    var decayTime: Int
    var timeVelocitySensitivity: Int
    var levelVelocitySensitivity: Int
    
    static let dataLength = 6
    
    init() {
        start = 0
        attackTime = 0
        attackLevel = 127
        decayTime = 0
        timeVelocitySensitivity = 0
        levelVelocitySensitivity = 0
    }
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        start = Int(b) - 64
        offset += 1
        
        b = d[offset]
        attackTime = Int(b)
        offset += 1
        
        b = d[offset]
        attackLevel = Int(b) - 64
        offset += 1
        
        b = d[offset]
        decayTime = Int(b)
        offset += 1
        
        b = d[offset]
        timeVelocitySensitivity = Int(b) - 64
        offset += 1
        
        b = d[offset]
        levelVelocitySensitivity = Int(b) - 64
        offset += 1
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
     
        data.append(Byte(start + 64))
        data.append(Byte(attackTime))
        data.append(Byte(attackLevel + 64))
        data.append(Byte(decayTime))
        data.append(Byte(timeVelocitySensitivity + 64))
        data.append(Byte(levelVelocitySensitivity + 64))

        return data
    }
}

extension PitchEnvelope: CustomStringConvertible {
    var description: String {
        var s = ""
        s += "start=\(start), attackTime=\(attackTime), attackLevel=\(attackLevel), decayTime=\(decayTime)\n"
        s += "timeVelSens=\(timeVelocitySensitivity) levelVelSens=\(levelVelocitySensitivity)\n"
        return s
    }
}

struct Oscillator: Codable {
    var waveType: WaveType  // TODO: is this necessary? Maybe just use the wave number?
    var waveNumber: Int
    var coarse: Int
    var fine: Int
    var keyScalingToPitch: KeyScalingType
    var fixedKey: Int  // TODO: OFF / MIDI note
    var pitchEnvelope: PitchEnvelope
    
    static let dataLength = 12
    
    init() {
        waveType = .pcm
        waveNumber = 412
        coarse = 0
        fine = 0
        keyScalingToPitch = .zeroCent
        fixedKey = 0
        pitchEnvelope = PitchEnvelope()
    }
    
    init(data d: ByteArray) {
        var offset: Int = 0
        var b: Byte = 0
        
        b = d[offset]
        let waveMSB = b
        offset += 1
        b = d[offset]
        let waveLSB = b
        offset += 1

        let waveMSBString = String(waveMSB, radix: 2).pad(with: "0", toLength: 3)
        let waveLSBString = String(waveLSB, radix: 2).pad(with: "0", toLength: 7)
        let waveString = waveMSBString + waveLSBString
        // now we should have a 10-bit binary string, convert it to a decimal number
        waveNumber = Int(waveString, radix: 2) ?? 412

        b = d[offset]
        coarse = Int(b) - 24
        offset += 1

        b = d[offset]
        fine = Int(b) - 64
        offset += 1

        b = d[offset]
        fixedKey = Int(b)
        offset += 1

        b = d[offset]
        keyScalingToPitch = KeyScalingType(index: Int(b))!
        offset += 1

        pitchEnvelope = PitchEnvelope(data: ByteArray(d[offset ..< offset + PitchEnvelope.dataLength]))
        
        if waveNumber == 512 {
            waveType = .additive
        }
        else {
            waveType = .pcm
        }
    }
    
    func asData() -> ByteArray {
        var data = ByteArray()
        
        // Wave type is not emitted in System Exclusive
        
        // Convert wave kit number to binary string with 10 digits
        // using a String extension (see Helpers.swift).
        let waveBitString = String(waveNumber, radix: 2).pad(with: "0", toLength: 10)
        
        // Take the first three bits and convert them to a number
        let msbBitString = waveBitString.prefix(3)
        let msb = Byte(msbBitString, radix: 2)
        data.append(msb!)
        
        // Take the last seven bits and convert them to a number
        let lsbBitString = waveBitString.suffix(7)
        let lsb = Byte(lsbBitString, radix: 2)
        data.append(lsb!)

        data.append(Byte(coarse + 24))
        data.append(Byte(fine + 64))
        data.append(Byte(fixedKey))
        data.append(Byte(keyScalingToPitch.index!))
        data.append(contentsOf: pitchEnvelope.asData())
        
        return data
    }
}

extension Oscillator: CustomStringConvertible {
    var description: String {
        var s = ""
        if waveType == .pcm {
            s += "PCM"
        }
        else if waveType == .additive {
            s += "ADD"
        }
        else {  // shouldn't happen since waveType is an enum
            s += "???"
        }
        s += " Wave=\(waveNumber) Coarse=\(coarse) Fine=\(fine) KStoPitch=\(keyScalingToPitch.rawValue) FixedKey=\(fixedKey)\n"
        s += "Pitch Envelope:\n\(pitchEnvelope)\n"
        return s
    }
}
