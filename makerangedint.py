specs = [
    ('Fine', 'Fine tuning', -63, 63, 0),
    ('EffectDepth', 'Effect depth', 0, 100, 0),
    ('EffectPath', 'Effect path', 1, 4, 1),
    ('Resonance', 'Resonance', 0, 31, 0),
    ('Gain', 'Gain', 1, 63, 1),
    ('BenderPitch', 'Bender pitch', -12, 12, 0),
    ('BenderCutoff', 'Bender cutoff', 0, 31, 0),
    ('MIDINote', 'MIDI note', 0, 127, 60),
    ('PatchNumber', 'Patch number', 0, 127, 0),
    ('Transpose', 'Transpose', -24, 24, 0)
]

for spec in specs:
    range_string = f'{spec[2]}...{spec[3]}'
    print('/// ' + spec[1] + f' ({range_string}).')
    print(f'public struct {spec[0]}' + ' {')
    print('    public var value: Int')
    print(f'    public static let range: ClosedRange<Int> = {range_string}')
    print(f'    public static let defaultValue = {spec[4]}')

    init_method_1 = '''
    public init() {
        assert(Self.range.contains(Self.defaultValue), "Default value must be in range \(Self.range)")
        self.value = Self.defaultValue
    }'''
    print(init_method_1)

    init_method_2 = '''
    public init(_ value: Int) {
        self.value = Self.range.clamp(value)
    }'''
    print(init_method_2)
    print('}')
    print()

    ext_header = f'extension {spec[0]}: ExpressibleByIntegerLiteral ' + '{'
    ext = '''    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        self.value = Self.range.clamp(value)
    }
}
'''
    print(ext_header)
    print(ext)

    print()
