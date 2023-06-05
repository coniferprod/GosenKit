import SyxPack

/// Drum waveform.
public struct DrumWave {
    private(set) var number: Int  // wave number 0~224 (9 bits)
    
    /// Initialize drum wave with number.
    public init(number: Int) {
        self.number = number
    }
    
    /// Initialize drum wave from two bytes.
    public init(msb: Byte, lsb: Byte) {
        self.number = DrumWave.numberFromBytes(msb, lsb)!
    }
    
    /// Gets the name of this drum wave.
    public var name: String {
        return DrumWave.names[Int(self.number)]
    }
    
    /// Gets the drum wave number from `msb` and ` lsb`.
    public static func numberFromBytes(_ msb: Byte, _ lsb: Byte) -> Int? {
        let waveMSBString = String(msb, radix: 2).padded(with: "0", to: 2, from: .left)
        let waveLSBString = String(lsb, radix: 2).padded(with: "0", to: 7, from: .left)
        let waveString = waveMSBString + waveLSBString
        // Now we should have a 9-bit binary string, convert it to a decimal number.
        // The wave number is zero-based in the SysEx file, but treated as one-based.
        if let number = Int(waveString, radix: 2) {
            return number + 1
        }
        return nil
    }
    
    private func asBytes() -> (msb: Byte, lsb: Byte) {
        let num = self.number - 1  // make wave number zero-based
        
        // Convert wave kit number to binary string with 9 digits
        // using a String extension (see Helpers.swift).
        let waveBitString = String(num, radix: 2).padded(with: "0", to: 9, from: .left)
        
        // Take the first two bits and convert them to a number
        let msbBitString = waveBitString.prefix(2)
        let msb = Byte(msbBitString, radix: 2)!
        
        // Take the last seven bits and convert them to a number
        let lsbBitString = waveBitString.suffix(7)
        let lsb = Byte(lsbBitString, radix: 2)!

        return (msb, lsb)
    }
    
    static let names = [
        "N/A",  // to align with one-based numbering
        
        // BD group
        /*  1 */ "Std1 BD1",
        /*  2 */ "Std1 BD2",
        /*  3 */ "Std2 BD1",
        /*  4 */ "Std2 BD2",
        /*  5 */ "Room BD1",
        /*  6 */ "Room BD2",
        /*  7 */ "Power BD1",
        /*  8 */ "Power BD2",
        /*  9 */ "Elect BD1",
        /*  10 */ "Elect BD2",
        /*  11 */ "Bob BD1",
        /*  12 */ "Bob BD2",
        /*  13 */ "Dance BD1",
        /*  14 */ "Dance BD2",
        /*  15 */ "Jazz BD1",
        /*  16 */ "Jazz BD2",
        /*  17 */ "Brush BD1",
        /*  18 */ "Brush BD2",
        /*  19 */ "Orch BD1",
        /*  20 */ "Orch BD2",
        /*  21 */ "Techno BD1",
        /*  22 */ "Techno BD2",
        
        // Snare group
        /*  23 */ "Rim",
        /*  24 */ "Std1 SD1",
        /*  25 */ "Std1 SD2",
        /*  26 */ "Std2 SD1",
        /*  27 */ "Std2 SD2",
        /*  28 */ "Room SD1",
        /*  29 */ "Room SD2",
        /*  30 */ "Power SD1",
        /*  31 */ "Power SD2",
        /*  32 */ "Elect SD1",
        /*  33 */ "Elect SD2",
        /*  34 */ "Bob Rim",
        /*  35 */ "Bob SD1",
        /*  36 */ "Bob SD2",
        /*  37 */ "Dance SD11",
        /*  38 */ "Dance SD2",
        /*  39 */ "Jazz SD1",
        /*  40 */ "Jazz SD2",
        /*  41 */ "Brush Tap",
        /*  42 */ "Brush Slap",
        /*  43 */ "Brush Swirl",
        /*  44 */ "Orch SD1",
        /*  45 */ "Techno SD1",
        /*  46 */ "Techno SD2",
        
        // HH group
        /*  47 */ "Std1 HHC",
        /*  48 */ "Std1 HHP",
        /*  49 */ "Std1 HHO",
        /*  50 */ "Std2 HHC",
        /*  51 */ "Std2 HHO",
        /*  52 */ "Room HHC",
        /*  53 */ "Room HHO",
        /*  54 */ "Power HHC",
        /*  55 */ "Power HHO",
        /*  56 */ "Elect HHC",
        /*  57 */ "Elect HHO",
        /*  58 */ "Bob HHC",
        /*  59 */ "Bob HHP",
        /*  60 */ "Bob HHO",
        /*  61 */ "Dance HHC",
        /*  62 */ "Dance HHP",
        /*  63 */ "Dance HHO",
        /*  64 */ "Jazz HHC",
        /*  65 */ "Jazz HHP",
        /*  66 */ "Jazz HHO",
        /*  67 */ "Brush HHC",
        /*  68 */ "Brush HHO",
        /*  69 */ "Orch HHC",
        /*  70 */ "Orch HHP",
        /*  71 */ "Orch HHO",
        /*  72 */ "Techno HHC",
        /*  73 */ "Techno HHP",
        /*  74 */ "Techno HHO",
        
        // Tom group
        /*  75 */ "Std1 Hi Tom1",
        /*  76 */ "Std1 Hi Tom2",
        /*  77 */ "Std1 Mid Tom1",
        /*  78 */ "Std1 Mid Tom2",
        /*  79 */ "Std1 Low Tom1",
        /*  80 */ "Std1 Low Tom 2",
        /*  81 */ "RoomHiTom1",
        /*  82 */ "RoomHiTom2",
        /*  83 */ "RoomMidTom1",
        /*  84 */ "RoomMidTom2",
        /*  85 */ "RoomLowTom1",
        /*  86 */ "RoomLowTom2",
        /*  87 */ "Power Hi Tom1",
        /*  88 */ "Power Hi Tom2",
        /*  89 */ "PowerMidTom1",
        /*  90 */ "PowerMidTom2",
        /*  91 */ "PowerLowTom1",
        /*  92 */ "PowerLowTom2",
        /*  93 */ "Elect Hi Tom1",
        /*  94 */ "Elect Hi Tom2",
        /*  95 */ "Elect Mid Tom1",
        /*  96 */ "Elect Mid Tom2",
        /*  97 */ "Elect Low Tom1",
        /*  98 */ "Elect Low Tom2",
        /*  99 */ "Bob Hi Tom1",
        /* 100 */ "Bob Hi Tom2",
        /* 101 */ "Bob Mid Tom1",
        /* 102 */ "Bob Mid Tom2",
        /* 103 */ "Bob Low Tom1",
        /* 104 */ "Bob Low Tom2",
        /* 105 */ "DanceHiTom1",
        /* 106 */ "DanceHiTom2",
        /* 107 */ "DanceMidTom1",
        /* 108 */ "DanceMidTom2",
        /* 109 */ "DanceLowTom1",
        /* 110 */ "DanceLowTom2",
        /* 111 */ "Jazz Hi Tom 1",
        /* 112 */ "Jazz Hi Tom 2",
        /* 113 */ "Jazz Mid Tom 1",
        /* 114 */ "Jazz Mid Tom 2",
        /* 115 */ "Jazz Low Tom 1",
        /* 116 */ "Jazz Low Tom 2",
        /* 117 */ "Brush Hi Tom 1",
        /* 118 */ "Brush Hi Tom 2",
        /* 119 */ "Brush Mid Tom 1",
        /* 120 */ "Brush Mid Tom 2",
        /* 121 */ "Brush Low Tom 1",
        /* 122 */ "Brush Low Tom 2",
        
        // Cymbal group
        /* 123 */ "Std1 Crash1",
        /* 124 */ "Crash2",  // maybe should be "Std1 Crash 2"?
        /* 125 */ "Bob Crash1",
        /* 126 */ "Jazz Crash1",
        /* 127 */ "Jazz Crash2",
        /* 128 */ "Brush Crash1",
        /* 129 */ "Brush Crash2",
        /* 130 */ "Orch Cymbal2",
        /* 131 */ "Orch Cymbal1",  // ATTN: wrong way around?
        /* 132 */ "Techno Crash",
        /* 133 */ "Std1 Ride 1",
        /* 134 */ "Ride 2",  // maybe should be "Std1 Ride 2"?
        /* 135 */ "Cup",
        /* 136 */ "Jazz Ride 1",
        /* 137 */ "Jazz Ride 2",
        /* 138 */ "Jazz Cup 1",
        /* 139 */ "Brush Ride 1",
        /* 140 */ "Brush Ride 2",
        /* 141 */ "Brush Cup1",
        /* 142 */ "Orch Ride",
        /* 143 */ "Techno Ride",
        /* 144 */ "China",
        /* 145 */ "Splash",
        /* 146 */ "Reverse Cymbal 1",
        
        // Perc group
        /* 147 */ "Tambourine",
        /* 148 */ "Cowbell",
        /* 149 */ "Bob Cowbell",
        /* 150 */ "Cabasa",
        /* 151 */ "Maracas",
        /* 152 */ "Bob Maracas",
        /* 153 */ "Shaker",
        /* 154 */ "Mute Triangle",
        /* 155 */ "Open Triangle",
        /* 156 */ "Elec Mute Tri",
        /* 157 */ "Elec Open Tri",
        /* 158 */ "Bell Tree",
        /* 159 */ "Wind Chime",
        /* 160 */ "Mute Hi Conga",
        /* 161 */ "Hi Conga",
        /* 162 */ "Low Conga",
        /* 163 */ "Bob Hi Conga",
        /* 164 */ "Bob Mid Conga",
        /* 165 */ "Bob Low Conga",
        /* 166 */ "Vibra Slap",
        /* 167 */ "Hi Bongo",
        /* 168 */ "Low Bongo",
        /* 169 */ "Hi Timbale",
        /* 170 */ "Low Timbale",
        /* 171 */ "Hi Agogo",
        /* 172 */ "Low Agogo",
        /* 173 */ "Short Whistle",
        /* 174 */ "Long Whistle",
        /* 175 */ "Short Guiro",
        /* 176 */ "Long Guiro",
        /* 177 */ "Claves",
        /* 178 */ "Bob Claves",
        /* 179 */ "Hi Wood Blk",
        /* 180 */ "Low Wood Blk",
        /* 181 */ "Mute Cuica",
        /* 182 */ "Open Cuica",
        /* 183 */ "Hi Hoo",
        /* 184 */ "Low Hoo",
        /* 185 */ "Mute Surdo",
        /* 186 */ "Open Surdo",
        /* 187 */ "Jingle Bell",
        /* 188 */ "Castanets",
        /* 189 */ "Orche Casta",
        /* 190 */ "Timpani F",
        /* 191 */ "Timpani F#",
        /* 192 */ "Timpani G",
        /* 193 */ "Timpani G#",
        /* 194 */ "Timpani A",
        /* 195 */ "Timpani A#",
        /* 196 */ "Timpani B",
        /* 197 */ "Timpani c",
        /* 198 */ "Timpani c#",
        /* 199 */ "Timpani d",
        /* 200 */ "Timpani d#",
        /* 201 */ "Timpani e",
        /* 202 */ "Timpani f",
        /* 203 */ "Snare Roll",
        /* 204 */ "Finger Snap",
        /* 205 */ "High Q",
        /* 206 */ "Slap",
        /* 207 */ "Scratch Push",
        /* 208 */ "Scratch Pull",
        /* 209 */ "Scratch",
        /* 210 */ "Sticks",
        /* 211 */ "Square Click",
        /* 212 */ "Metronome Click",
        /* 213 */ "Metronome Bell",
        /* 214 */ "Hand Clap",
        /* 215 */ "Guitar Fret Noise",
        /* 216 */ "Gtr. Cut Up",
        /* 217 */ "Gtr. Cut Down",
        /* 218 */ "Bass Slap",
        /* 219 */ "Fl. Key Click",
        
        // SFX group
        /* 220 */ "Laughing",
        /* 221 */ "Scream",
        /* 222 */ "Punch",
        /* 223 */ "Heart Beat",
        /* 224 */ "Footsteps 1",
        /* 225 */ "Footsteps 2",
        /* 226 */ "Door Creaking",
        /* 227 */ "Door",
        /* 228 */ "Car-Engine",
        /* 229 */ "Car-Stop",
        /* 230 */ "Car-Pass",
        /* 231 */ "Car-Crash",
        /* 232 */ "Siren",
        /* 233 */ "Train",
        /* 234 */ "Jetplane",
        /* 235 */ "Starship",
        /* 236 */ "Gun Shot",
        /* 237 */ "Mashine Gun",
        /* 238 */ "Lasergun",
        /* 239 */ "Explosion",
        /* 240 */ "Dog",
        /* 241 */ "Horse-Gallop",
        /* 242 */ "Rain",
        /* 243 */ "Thunder",
        /* 244 */ "Bubble",
        /* 245 */ "Applause",
        /* 246 */ "EFF Clap",
        /* 247 */ "Echo Glas",
        /* 248 */ "Applause",
        /* 249 */ "Helicopter",
        /* 250 */ "Birds",
        /* 251 */ "Wind",
        /* 252 */ "Seashore",
        /* 253 */ "Stream",
    ]
}

/// Drum source data.
public struct DrumSource {
    public var volume: Int  // 0~127
    public var pan: Int  // (63L)1 ~ (63R)127
    public var wave: DrumWave  // 0~224
    public var coarse: Int  // (-24)40~(+24)88
    public var fine: Int  // (-63)1~(+63)127
    
    public struct PitchEnvelope {
        var startLevel: Int
        var attackTime: Int
        var levelVelocitySensitivity: Int
    }
    
    /// Velocity control for drum source DCA.
    public struct VelocityControl: Codable {
        public var level: Int  // 0~63
        public var attackTime: Int  // (-63)1~(+63)127
        public var decay1Time: Int  // (-63)1~(+63)127
        
        public init() {
            level = 0
            attackTime = 0
            decay1Time = 0
        }
        
        public init(level: Int, attackTime: Int, decay1Time: Int) {
            self.level = level
            self.attackTime = attackTime
            self.decay1Time = decay1Time
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
            
            return .success(temp)
        }
    }
    
    public struct AmplifierEnvelope {
        var attackTime: Int   // 0~127
        var deacy1Time: Int   // 0~127
        var decay1Level: Int  // 0~127
        var releaseTime: Int  // 0~127
    }
    
    public var pitchEnvelope: PitchEnvelope
    public var filterCutoff: Int  // 0~127
    public var filterCutoffVelocityDepth: Int  // (-63)1~(+63)127
    public var amplifierEnvelope: AmplifierEnvelope
    public var amplifierVelocitySensitivity: VelocityControl
}

/// Represents a K5000W drum instrument.
public struct DrumInstrument {
    public enum Gate {
        case off
        case on(Int)  // 1~32
    }
    
    public enum ExclusionGroup {
        case off
        case on(Int)  // group number 1~8
    }
    
    /// Drum instrument common data.
    public struct Common {
        public var volume: Int  // 0~127
        public var gate: Gate
        public var exclusionGroup: ExclusionGroup
        public var effectPath: Int  // 1~4 (in SysEx 0~3)
        public var sourceMutes: [Bool]  // "=01(fix)" WAT
    }
        
    public var common: Common
    public var source: DrumSource
    
    /// Drum instrument checksum.
    public var checksum: Byte {
        var totalSum: Int = 0
        
        let commonData = common.asData()
        var commonSum: Int = 0
        for d in commonData {
            commonSum += Int(d) & 0xFF
        }
        totalSum += commonSum

        var sourceSum: Int = 0
        for b in self.source.asData() {
            sourceSum += Int(b) & 0xFF
        }
        totalSum += sourceSum
        
        totalSum += 0xA5

        return Byte(totalSum & 0x7F)
    }
}

// MARK: - SystemExclusiveData

extension DrumInstrument.Common: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(0)  // dummy
        data.append(Byte(self.volume))
        
        switch self.gate {
        case .off:
            data.append(0)
        case .on(let n):
            data.append(Byte(n))
        }
        
        switch self.exclusionGroup {
        case .off:
            data.append(0)
        case .on(let g):
            data.append(Byte(g))
        }
        
        return data
    }
    
    public var dataLength: Int { return DrumInstrument.Common.dataSize }
    
    public static let dataSize = 6
}

extension DrumSource.PitchEnvelope {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(self.startLevel + 64))
        data.append(Byte(self.attackTime))
        data.append(Byte(self.levelVelocitySensitivity + 64))
        
        return data
    }
    
    public var dataLength: Int { return DrumSource.PitchEnvelope.dataSize }
    
    public static let dataSize = 3
}

extension DrumWave: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        let (msb, lsb) = self.asBytes()
        data.append(msb)
        data.append(lsb)
        
        return data
    }
    
    public var dataLength: Int { 2 }
}

extension DrumSource {
    public func asData() -> ByteArray {
        var data = ByteArray()

        data.append(Byte(self.volume))
        data.append(Byte(self.pan))
        data.append(contentsOf: self.wave.asData())
        data.append(Byte(self.coarse + 64))
        data.append(Byte(self.fine + 64))
        data.append(contentsOf: self.pitchEnvelope.asData())
        data.append(Byte(self.filterCutoff))
        data.append(Byte(self.filterCutoffVelocityDepth + 64))
        
        return data
    }
    
    public var dataLength: Int { return DrumSource.dataSize }
    
    public static let dataSize = 18
}


extension DrumInstrument: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(self.checksum)
        data.append(contentsOf: self.common.asData())
        data.append(contentsOf: self.source.asData())
        
        return data
    }
    
    public var dataLength: Int { return DrumInstrument.Common.dataSize }
    
    public static let dataSize = 1 + 6 + 18
}
