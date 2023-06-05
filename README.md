# GosenKit

Patch management library for the Kawai K5000 Advanced Additive Synthesizer

This package needs a lot more comments and unit tests. It can be used for experiments, but it is not ready for production use,
although I'm trying to adhere to [semantic versioning](https://semver.org).

The word "gosen" 五千 is Japanese for 5,000.

## Test resources

This package was supposed to contain some original System Exclusive files to use in unit tests. 
The packaging requires Swift 5.3 or later, and is described in [Bundling Resources
with a Swift Package](https://developer.apple.com/documentation/swift_packages/bundling_resources_with_a_swift_package).

However, I have never gotten it to work reliably, so to save myself some trouble I just made 
Swift source code of those SysEx files and included them in the test classes.

## Dissection of the PowerK5K patch

PowerK5K is a single patch from the K5000 factory sounds v4.04.

    00000000  f0   // SysEx initiator
    00000001  40   // Kawai manufacturer ID
    00000002  00   // channel 1 (0x00)
    00000003  00   // always fixed with K5000
    00000004  0A   // always fixed with K5000
    00000005  00   // bank A
    00000006  00   // patch number
    
The payload starts at offset 00000007. In the next breakdown the offsets are
relative to the start of the payload, not the whole message.

    00000000  24  // checksum
    
    // Common data (see 3.1.2.1)
    
    // Effect settings
    00000001  02  // effect algorithm: stored as 0x00~0x03, actual 1...4, so here algorithm = 3
    00000002  00 46 14 1A 00 00  // reverb settings
    00000008  1D 64 64 00 00 00  // effect 1 settings
    0000000E  15 63 06 4A 00 00  // effect 2 settings
    00000014  10 18 55 04 55 02  // effect 3 settings
    0000001A  0B 00 00 00 00 00  // effect 4 settings
    00000020  45 44 43 40 41 46 45  // GEQ, 7 bands
    00000027  00  // drum mark
    00000028  50 6f 77 65 72 4b 35 4b  // name (8 bytes): P, o, w, e, r, K, 5, K
    00000030  50  // volume (80)
    00000031  00  // polyphony
    00000032  00  // no use
    00000033  05  // number of sources
    00000034  1F  // source mutes
    00000035  00  // AM
    00000036  00 00 00 00 00 00  // effect control sources 1 and 2
    0000003C  00  // portamento setting
    0000003D  73  // portamento speed (115)
    0000003E  11 0B 01 12 04 0D 00 00 5F 21 21 5F 5F 5F 00 00    // macro controller settings for K5000S/R (16 bytes)
    0000004E  01 0A 01 0A // SW1 and SW2 parameters
    
    // SOURCE 1 (86 bytes)
    // Control
    00000052  00 7F  // zone lo and hi
    00000054  10  // velo sw
    00000055  00  // effect path
    00000056  77  // volume
    00000057  02 00 // bender
    00000059  00 40 00 40 // pressure
    0000005D  01 21 00 40 // wheel
    00000061  02 5F 00 40 // expression
    00000065  00 00 40 00 00 40 // assignable
    0000006B  00 // key on delay
    0000006C  03 40 // pan
    
    // DCO
    0000006E  02 66 // wave kit MSB and LSB
    00000070  34 // coarse
    00000071  40 // fine
    00000072  00 // fixed key
    00000073  00 // KS Pitch
    00000074  40 04 40 40 40 40 // Pitch Env
    
    // DCF
    0000007A  00 // DCF
    0000007B  00 // Mode
    0000007C  05 // Velo Curve
    0000007D  02 // Resonance
    0000007E  00 // DCF Level
    0000007F  59 // Cutoff
    00000080  40 // Cutoff KS Depth
    00000081  40 // Cutoff Velo Depth
    00000082  54 // DCF Env Depth
    00000083  00 7F 3D 65 40 74  // DCF Env
    00000089  40 40 // DCF KS To Env
    0000008B  4D 40 40  // DCF Velo To Env
    
    // DCA
    0000008E  01  // DCA Velo Curve
    0000008F  00 7F 7F 5E 7F 74  // DCA Env
    00000095  40 40 40 40  // DCA KS to Env
    00000099  37 40 40 40  // DCA Velo Sense
    
    // LFO
    0000009D  00  // Waveform
    0000009E  03  // Speed
    0000009F  00  // Delay onset
    000000A0  00 00 // Fade in 
    000000A2  00 40  // Pitch (Vibrato)
    000000A4  10 40  // DCF (Growl)
    000000A6  00 40  // DCA (Tremolo)
    
    // SOURCE 2 (86 bytes))
    000000A8  00 7F  // zone lo and hi
    000000AA  10  // velo sw
    000000AB  01  // effect path
    000000AC  6D  // volume
    000000AD  02 00 // bender
    000000AF  00 40 00 40  // pressure
    000000B3  01 21 00 40  // wheel
    000000B7  02 5F 00 40  // expression
    000000BB  00 00 40 00 00 40 // assignable
    000000C1  00  // key on delay
    000000C2  00 10 // pan
    
    // DCO
    000000C4  03 0C  // wave kit MSB and LSB
    000000C6  58  // coarse
    000000C7  40  // fine
    000000C8  00  // fixed key
    000000C9  00  // KS Pitch
    000000CA  01 7F 40 7F 40 40  // Pitch Env
    
    // DCF
    000000D0  00  // DCF
    000000D1  00  // mode
    000000D2  05  // Velo curve
    000000D3  03  // Resonance
    000000D4  00  // DCF Level
    000000D5  7A  // Cutoff 
    000000D6  40  // Cutoff KS Depth
    000000D7  40  // Cutoff Velo Depth
    000000D8  40  // DCF Env Depth
    000000D9  00 75 6D 53 7F 74 // DCF Env
    000000DF  40 40 // DCF KS To Env
    000000E1  78 40 40 // DCF Velo To Env
    
    // DCA
    000000E4  01  // DCA Velo Curve
    000000E5  00 7F 7F 5C 7F 74   // DCA Env
    000000EB  40 40 40 40  // DCA KS To Env
    000000EF  00 40 40 40  // DCA Velo Sense
    
    // LFO
    000000F3  00  // Waveform
    000000F4  01  // Speed
    000000F5  01  // Delay onset
    000000F6  0E 0A  // Fade in
    000000F8  00 40  // Pitch (vibrato) 
    000000FA  17 40  // DCF (Growl)           
    000000FC  00 40  // DCA (Tremolo)
    
    // SOURCE 3 (86 bytes)
    000000FE
    
    // SOURCE 4
    // SOURCE 5
    
    // ADD Kits for ADD sources, ordered by source number
