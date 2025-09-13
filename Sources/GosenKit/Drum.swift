import SyxPack
import ByteKit

/// Drum wave number (0...285).
public struct DrumWaveNumber: RangedInt {
    public var value: Int
    public static let range: ClosedRange<Int> = 0...285
    public static let defaultValue = 0

    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }
}

/// Drum waveform.
/// TODO: Use DrumWaveNumber.
public struct DrumWave {
    private(set) var number: Int  // wave number 0~285 (9 bits)
    
    /// Initialize drum wave with number.
    public init(number: Int) {
        self.number = number
    }
    
    /// Initialize drum wave from two bytes.
    public init(msb: Byte, lsb: Byte) {
        self.number = DrumWave.numberFromBytes(msb, lsb)!
    }
    
    /// Gets the name of this drum wave.
    public var name: String { DrumWave.names[Int(self.number)] }
    
    /// Gets the drum wave number from `msb` and ` lsb`.
    public static func numberFromBytes(_ msb: Byte, _ lsb: Byte) -> Int? {
        let waveMSBString = String(msb, radix: 2).padded(with: "0", to: 2, from: .left)
        let waveLSBString = String(lsb, radix: 2).padded(with: "0", to: 7, from: .left)
        let waveString = waveMSBString + waveLSBString
        // Now we should have a 9-bit binary string, convert it to a decimal number.
        // The wave number is zero-based in the SysEx file, but treated as one-based. (0=MUTE)
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
        "MUTE",
        
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
    /// Pitch envelope for a drum source.
    public struct PitchEnvelope {
        /// Drum source pitch envelope level (-63...63)
        public struct Level: RangedInt {
            public var value: Int
            public static let range: ClosedRange<Int> = -63...63
            public static let defaultValue = 0

            public init(_ value: Int) {
                self.value = Self.range.clamp(value)
            }
        }

        /// Drum source pitch envelope time (0...127)
        public struct Time: RangedInt {
            public var value: Int
            public static let range: ClosedRange<Int> = 0...127
            public static let defaultValue = 0

            public init(_ value: Int) {
                self.value = Self.range.clamp(value)
            }
        }

        var startLevel: Level // (-63)1~(+63)127
        var attackTime: Time // 0~127
        var levelVelocitySensitivity: Level // (-63)1~(+63)127
        
        /// Initialize a drum source pitch envelope with default values.
        public init() {
            self.startLevel = 0
            self.attackTime = 0
            self.levelVelocitySensitivity = 0
        }
        
        /// Parse a drum source pitch envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<PitchEnvelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = PitchEnvelope()
            b = data.next(&offset)
            temp.startLevel = Level(Int(b) - 64)
            b = data.next(&offset)
            temp.attackTime = Time(Int(b))
            b = data.next(&offset)
            temp.levelVelocitySensitivity = Level(Int(b) - 64)
            
            return .success(temp)
        }
    }
    
    /// Velocity control for drum source DCA.
    public struct VelocityControl {
        /// Drum source velocity control level
        public struct Level: RangedInt {
            public var value: Int
            public static let range: ClosedRange<Int> = 0...63
            public static let defaultValue = 0

            public init(_ value: Int) {
                self.value = Self.range.clamp(value)
            }
        }

        /// Drum source velocity control time
        public struct Time: RangedInt {
            public var value: Int
            public static let range: ClosedRange<Int> = -63...63
            public static let defaultValue = 0

            public init(_ value: Int) {
                self.value = Self.range.clamp(value)
            }
        }

        public var level: Level  // 0~63
        public var attackTime: Time  // (-63)1~(+63)127
        public var decay1Time: Time  // (-63)1~(+63)127
        
        /// Initalize velocity control settings with default values.
        public init() {
            self.level = 0
            self.attackTime = 0
            self.decay1Time = 0
        }
        
        /// Initialize velocity control settings.
        public init(level: Int, attackTime: Int, decay1Time: Int) {
            self.level = Level(level)
            self.attackTime = Time(attackTime)
            self.decay1Time = Time(decay1Time)
        }
        
        /// Parse velocity control settings from MIDI System Exclusive data.
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
            
            return .success(temp)
        }
    }
    
    /// Amplifier envelope for drum source.
    public struct AmplifierEnvelope {
        var attackTime: Level   // 0~127
        var decay1Time: Level   // 0~127
        var decay1Level: Level  // 0~127
        var releaseTime: Level  // 0~127
        
        /// Initialize drum source amplifier envelope with default values.
        public init() {
            self.attackTime = 0
            self.decay1Time = 0
            self.decay1Level = 0
            self.releaseTime = 0
        }
        
        /// Parse drum source amplifier envelope from MIDI System Exclusive data.
        public static func parse(from data: ByteArray) -> Result<AmplifierEnvelope, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            var temp = AmplifierEnvelope()
            
            b = data.next(&offset)
            temp.attackTime = Level(Int(b))
            b = data.next(&offset)
            temp.decay1Time = Level(Int(b))
            b = data.next(&offset)
            temp.decay1Level = Level(Int(b))
            b = data.next(&offset)
            temp.releaseTime = Level(Int(b))

            return .success(temp)
        }
    }
    
    public var volume: Level  // 0~127
    public var pan: Pan  // (63L)1 ~ (63R)127
    public var wave: DrumWave  // 0~224
    public var coarse: Coarse  // (-24)40~(+24)88
    public var fine: Fine  // (-63)1~(+63)127
    public var pitchEnvelope: PitchEnvelope
    public var filterCutoff: Level  // 0~127
    public var filterCutoffVelocityDepth: Depth  // (-63)1~(+63)127
    public var amplifierEnvelope: AmplifierEnvelope
    public var amplifierVelocitySensitivity: VelocityControl
    
    /// Initialize drum source with default values.
    public init() {
        self.volume = 100
        self.pan = 0
        self.wave = DrumWave(number: 1)
        self.coarse = 0
        self.fine = Fine(0)
        self.pitchEnvelope = PitchEnvelope()
        self.filterCutoff = Level(0)
        self.filterCutoffVelocityDepth = Depth(0)
        self.amplifierEnvelope = AmplifierEnvelope()
        self.amplifierVelocitySensitivity = VelocityControl()
    }
    
    /// Parse drum source from MIDI System Exclusive data bytes.
    public static func parse(from data: ByteArray) -> Result<DrumSource, ParseError> {
        var offset: Int = 0
        var b: Byte = 0
        
        var temp = DrumSource()
        
        b = data.next(&offset)
        temp.volume = Level(Int(b))
        
        b = data.next(&offset)
        temp.pan = Pan(Int(b) - 64)

        b = data.next(&offset)
        let waveMSB = b
        b = data.next(&offset)
        let waveLSB = b
        temp.wave = DrumWave(msb: waveMSB, lsb: waveLSB)

        b = data.next(&offset)
        temp.coarse = Coarse(Int(b) - 64)
        
        b = data.next(&offset)
        temp.fine = Fine(Int(b) - 64)
        
        var size = PitchEnvelope.dataSize
        let pitchEnvData = data.slice(from: offset, length: size)
        switch PitchEnvelope.parse(from: pitchEnvData) {
        case .success(let pitchEnv):
            temp.pitchEnvelope = pitchEnv
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        b = data.next(&offset)
        temp.filterCutoff = Level(Int(b))
        b = data.next(&offset)
        temp.filterCutoffVelocityDepth = Depth(Int(b) - 64)

        size = AmplifierEnvelope.dataSize
        let ampEnvData = data.slice(from: offset, length: size)
        switch AmplifierEnvelope.parse(from: ampEnvData) {
        case .success(let ampEnv):
            temp.amplifierEnvelope = ampEnv
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        size = VelocityControl.dataSize
        let controlData = data.slice(from: offset, length: size)
        switch VelocityControl.parse(from: controlData) {
        case .success(let control):
            temp.amplifierVelocitySensitivity = control
        case .failure(let error):
            return .failure(error)
        }

        return .success(temp).self
    }
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
        public var volume: Level  // 0~127
        public var gate: Gate
        public var exclusionGroup: ExclusionGroup
        public var effectPath: EffectPath  // 1~4 (in SysEx 0~3)
        
        /// Initialize drum instrument common data with default values.
        public init() {
            self.volume = 100
            self.gate = .off
            self.exclusionGroup = .off
            self.effectPath = 1
        }
        
        /// Parse drum instrument common data from MIDI System Exclusive data bytes.
        public static func parse(from data: ByteArray) -> Result<Common, ParseError> {
            var offset: Int = 0
            var b: Byte = 0
            
            b = data.next(&offset)  // dummy byte
            
            var temp = Common()
            
            b = data.next(&offset)
            temp.volume = Level(Int(b))
            
            b = data.next(&offset)
            if b == 0x00 {
                temp.gate = .off
            }
            else {
                temp.gate = .on(Int(b))  // TODO: Check that gate is in range 1~32
            }
            
            b = data.next(&offset)
            if b == 0x00 {
                temp.exclusionGroup = .off
            }
            else {
                temp.exclusionGroup = .on(Int(b))
            }
            
            b = data.next(&offset)
            temp.effectPath = EffectPath(Int(b + 1))  // adjust to 1...4
            
            b = data.next(&offset)  // src_mute is fixed to 0x01, so don't care
            
            return .success(temp)
        }
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
    
    public init() {
        self.common = Common()
        self.source = DrumSource()
    }
    
    public static func parse(from data: ByteArray) -> Result<DrumInstrument, ParseError> {
        var offset: Int = 0
        
        let _ = data.next(&offset)  // checksum
        
        var temp = DrumInstrument()

        var size = Common.dataSize
        let commonData = data.slice(from: offset, length: size)
        switch Common.parse(from: commonData) {
        case .success(let common):
            temp.common = common
        case .failure(let error):
            return .failure(error)
        }
        offset += size

        size = DrumSource.dataSize
        let sourceData = data.slice(from: offset, length: size)
        switch DrumSource.parse(from: sourceData) {
        case .success(let source):
            temp.source = source
        case .failure(let error):
            return .failure(error)
        }
        offset += size
        
        return .success(temp)
    }
}

/// Represents a drum note in a drum kit.
public enum DrumNote {
    case muted  // 0
    case instrument(Int) // 1~253, 254~285 = USR1~32
    
    public init(instrumentNumber: Int) {
        if instrumentNumber == 0 {
            self = .muted
        }
        else {
            self = .instrument(instrumentNumber)
        }
    }
    
    private func asBytes() -> (msb: Byte, lsb: Byte) {
        switch self {
        case .muted:
            return (0x00, 0x00)
        case .instrument(let number):
            // Convert instrument number to binary string with 9 digits
            // using a String extension (see Helpers.swift).
            let waveBitString = String(number, radix: 2).padded(with: "0", to: 9, from: .left)
            
            // Take the first two bits and convert them to a number
            let msbBitString = waveBitString.prefix(2)
            let msb = Byte(msbBitString, radix: 2)!
            
            // Take the last seven bits and convert them to a number
            let lsbBitString = waveBitString.suffix(7)
            let lsb = Byte(lsbBitString, radix: 2)!

            return (msb, lsb)
        }
    }
}

/// Represents a K5000W drum kit.
public struct DrumKit {
    /// Drum kit common settings.
    public struct Common {
        public var effects: EffectSettings
        public var geq: GEQ
        public var name: PatchName
        public var volume: Level
        public var effectControl: EffectControl
        
        /// Initialize drum kit common settings from default values.
        public init() {
            self.effects = EffectSettings()
            self.geq = GEQ(levels: [2, 1, 0, 0, -1, -2, 1])
            self.name = PatchName("DrumKit")
            self.volume = 100
            self.effectControl = EffectControl()
        }
        
        public static func parse(from data: ByteArray) -> Result<Common, ParseError> {
            var offset: Int = 0
            var b: Byte = 0x00
            
            print("Parsing drum kit common data, \(data.count) bytes")

            var temp = Common()  // initialize with defaults, then fill in

            var size = EffectSettings.dataSize
            print("Next: Drum Kit Common, EffectSettings, offset = \(offset)")
            let effectData = data.slice(from: offset, length: size)
            switch EffectSettings.parse(from: effectData) {
            case .success(let effects):
                temp.effects = effects
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            print("Next: Drum Kit Common, GEQ, offset = \(offset)")
            
            size = GEQ.bandCount
            switch GEQ.parse(from: data.slice(from: offset, length: size)) {
            case .success(let geq):
                temp.geq = geq
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            print("Next: Drum Kit Common, Drum mark, offset = \(offset)")
            // Eat the drum mark (39)
            offset += 1
            
            print("Next: Drum Kit Common, Name, offset = \(offset)")
            size = PatchName.length
            switch PatchName.parse(from: data.slice(from: offset, length: size)) {
            case .success(let name):
                temp.name = name
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            print("Next: Drum Kit Common, Volume, offset = \(offset)")
            b = data.next(&offset)
            temp.volume = Level(Int(b))
            
            print("Next: Drum Kit Common, EffectControl, offset = \(offset)")
            size = EffectControl.dataSize
            switch EffectControl.parse(from: data.slice(from: offset, length: size)) {
            case .success(let control):
                temp.effectControl = control
            case .failure(let error):
                return .failure(error)
            }
            offset += size

            return .success(temp)
        }
    }
    
    /// Drum kit note count.
    public static let noteCount = 64
    
    public var common: Common
    public var notes: [DrumNote]
    
    /// Initialize a drum kit with default values.
    public init() {
        self.common = Common()
        self.notes = Array(repeating: DrumNote(instrumentNumber: 10), count: DrumKit.noteCount)
    }
    
    public static func parse(from data: ByteArray) -> Result<DrumKit, ParseError> {
        var offset: Int = 0
        
        let _ = data.next(&offset)  // checksum

        var temp = DrumKit()

        let size = DrumKit.Common.dataSize
        let commonData = data.slice(from: offset, length: size)
        switch Common.parse(from: commonData) {
        case .success(let common):
            temp.common = common
        case .failure(let error):
            return .failure(error)
        }
        
        return .success(temp)
    }
    
    /// Drum kit checksum.
    public var checksum: Byte {
        var totalSum: Int = 0
        
        let commonData = common.asData()
        var commonSum: Int = 0
        for d in commonData {
            commonSum += Int(d) & 0xFF
        }
        totalSum += commonSum

        
        totalSum += 0xA5

        return Byte(totalSum & 0x7F)
    }

}

// MARK: - SystemExclusiveData

extension DrumInstrument.Common: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(0)  // dummy
        data.append(Byte(self.volume.value))
        
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
    
    public var dataLength: Int { DrumInstrument.Common.dataSize }
    
    public static let dataSize = 6
}

extension DrumSource.PitchEnvelope {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(self.startLevel.value + 64))
        data.append(Byte(self.attackTime.value))
        data.append(Byte(self.levelVelocitySensitivity.value + 64))
        
        return data
    }
    
    public var dataLength: Int { DrumSource.PitchEnvelope.dataSize }
    
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

        data.append(Byte(self.volume.value))
        data.append(Byte(self.pan.value))
        data.append(contentsOf: self.wave.asData())
        data.append(Byte(self.coarse.value + 64))
        data.append(Byte(self.fine.value + 64))
        data.append(contentsOf: self.pitchEnvelope.asData())
        data.append(Byte(self.filterCutoff.value))
        data.append(Byte(self.filterCutoffVelocityDepth.value + 64))
        data.append(contentsOf: self.amplifierEnvelope.asData())
        data.append(contentsOf: self.amplifierVelocitySensitivity.asData())
        
        return data
    }
    
    public var dataLength: Int { DrumSource.dataSize }
    
    public static let dataSize = 18
}

extension DrumSource.AmplifierEnvelope: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        [attackTime, decay1Time, decay1Level, releaseTime]
        .forEach {
            data.append(Byte($0.value))
        }

        return data
    }
    
    public var dataLength: Int { DrumSource.AmplifierEnvelope.dataSize }
    
    public static let dataSize = 4
}

extension DrumSource.VelocityControl: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(Byte(self.level.value))
        data.append(Byte(self.attackTime.value + 64))
        data.append(Byte(self.decay1Time.value + 64))
        
        return data
    }
    
    public var dataLength: Int { DrumSource.PitchEnvelope.dataSize }
    
    public static let dataSize = 3
}

extension DrumInstrument: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(self.checksum)
        data.append(contentsOf: self.common.asData())
        data.append(contentsOf: self.source.asData())
        
        return data
    }
    
    public var dataLength: Int { DrumInstrument.Common.dataSize }
    
    public static let dataSize = 1 + 6 + 18
}

extension DrumNote: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        let (msb, lsb) = self.asBytes()
        data.append(msb)
        data.append(lsb)

        return data
    }
    
    public var dataLength: Int { DrumNote.dataSize }
    
    public static let dataSize = 2
}

extension DrumKit: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(self.checksum)
        data.append(contentsOf: self.common.asData())
        
        for note in self.notes {
            data.append(contentsOf: note.asData())
        }
        
        return data
    }
    
    public var dataLength: Int { DrumKit.dataSize }
    
    public static let dataSize = DrumKit.Common.dataSize + DrumKit.noteCount * DrumNote.dataSize
}

extension DrumKit.Common: SystemExclusiveData {
    public func asData() -> ByteArray {
        var data = ByteArray()
        
        data.append(contentsOf: self.effects.asData())
        data.append(contentsOf: self.geq.asData())
        data.append(1)  // drum_mark
        data.append(contentsOf: self.name.asData())
        data.append(contentsOf: self.effectControl.asData())
        
        return data
    }
    
    public var dataLength: Int { DrumKit.Common.dataSize }
    
    public static let dataSize = 54
}
