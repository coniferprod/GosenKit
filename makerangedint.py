types = [
    {'name': 'Fine',
     'comment': 'Fine tuning',
     'range_low': -63,
     'range_high': 63,
     'default_value': 0},

    {'name': 'EffectDepth',
     'comment': 'Effect depth',
     'range_low': 0,
     'range_high': 100,
     'default_value': 0},

    {'name': 'EffectPath',
     'comment': 'Effect path',
     'range_low': 1,
     'range_high': 4,
     'default_value': 1},

    {'name': 'Resonance',
     'comment': 'Resonance',
     'range_low': 0,
     'range_high': 31,
     'default_value': 0},

    {'name': 'Gain',
     'comment': 'Gain',
     'range_low': 1,
     'range_high': 63,
     'default_value': 1},

    {'name': 'BenderPitch',
     'comment': 'Bender pitch',
     'range_low': -12,
     'range_high': 12,
     'default_value': 0},

    {'name': 'BenderCutoff',
     'comment': 'Bender cutoff',
     'range_low': 0,
     'range_high': 31,
     'default_value': 0},

    {'name': 'MIDINote',
     'comment': 'MIDI note',
     'range_low': 0,
     'range_high': 127,
     'default_value': 60},

    {'name': 'PatchNumber',
     'comment': 'Patch number',
     'range_low': 0,
     'range_high': 127,
     'default_value': 0},

    {'name': 'Transpose',
     'comment': 'Transpose',
     'range_low': -24,
     'range_high': 24,
     'default_value': 0}
]

for t in types:
    range_string = f'{t["range_low"]}...{t["range_high"]}'
    print('/// ' + t["comment"] + f' ({range_string}).')
    print(f'public struct {t["name"]}' + ' {')
    print('    public var value: Int')
    print(f'    public static let range: ClosedRange<Int> = {range_string}')
    print(f'    public static let defaultValue = {t["default_value"]}')

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

    ext_header = f'extension {t["name"]}: ExpressibleByIntegerLiteral ' + '{'
    ext = '''    /// Initialize with an integer literal.
    public init(integerLiteral value: Int) {
        self.value = Self.range.clamp(value)
    }
}
'''
    print(ext_header)
    print(ext)

    print()
