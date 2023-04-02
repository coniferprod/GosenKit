# GosenKit

Patch management library for the Kawai K5000 Advanced Additive Synthesizer

This package needs a lot more comments and unit tests. It can be used for experiments, but it is not ready for production use,
although I'm trying to adhere to [semantic versioning](https://semver.org).

The word "gosen" 五千 is Japanese for 5,000.

## Test resources

This package contains some System Exclusive files to use in unit tests. They are packaged as described in [Bundling Resources
with a Swift Package](https://developer.apple.com/documentation/swift_packages/bundling_resources_with_a_swift_package).
This feature requires Swift 5.3.

## Dissection of the PowerK5K patch

PowerK5K is a single patch from "the Wizoo book".

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
    00000028  50 6f 77 65 72 4b 35 4b  // name (8 bytes)
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
    
    // Source data
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
    
    
    
    
    
