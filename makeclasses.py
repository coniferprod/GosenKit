base_class = r"""
/// Wraps an immutable `Int`, retrievable with `value`.
/// Specifies minimum, maximum, and default values.
/// When an instance is constructed, the new value is
/// checked by asserting it is within the min / max limits.
/// The no-argument initializer uses the default value.
public class Integer: ExpressibleByIntegerLiteral, CustomStringConvertible {
    class var minimumValue: Int { Int.min }
    class var maximumValue: Int { Int.max }
    class var defaultValue: Int { 0 }
    
    public private(set) var value: Int
    
    public init(_ value: Int) {
        assert(Self.isValid(value))
        self.value = value
    }
    
    public static func isValid(_ value: Int) -> Bool {
        return (Self.minimumValue ... Self.maximumValue).contains(value)
    }

    required public convenience init(integerLiteral value: Int) {
        self.init(value)
    }
    
    public convenience init() {
        self.init(Self.defaultValue)
    }
    
    /// Gets a random value within min and max (inclusive).
    public static var randomValue: Int {
        let range: ClosedRange<Int> = Self.minimumValue ... Self.maximumValue
        return Int.random(in: range)
    }
    
    public var description: String {
        return "\(value)"
    }
}
"""

print(base_class)

specs = [
    ('Volume', 'Volume level', 0, 127, 0),
    ('Level', 'Level', 0, 127, 0),
    ('Time', 'Time', 0, 127, 0),
    ('Depth', 'Depth', -63, 63, 0),
    ('Pan', 'Pan', -63, 63, 0),
    ('MIDIChannel', 'MIDI channel', 1, 16, 1),
    ('VelocityCurve', 'Velocity curve', 1, 12, 1),
    ('ControlDepth', 'Control depth', -63, 63, 0),
    ('Coarse', 'Coarse tuning', -24, 24, 0),
    ('Fine', 'Fine tuning', -63, 63, 0),
    ('EffectDepth', 'Effect depth', 0, 100, 0),
    ('EffectPath', 'Effect path', 1, 4, 1),
    ('Resonance', 'Resonance', 0, 31, 0),
    ('Gain', 'Gain', 1, 63, 1),
    ('BenderPitch', 'Bender pitch', -12, 12, 0),
    ('BenderCutoff', 'Bender cutoff', 0, 31, 0),
    ('MIDINote', 'MIDI note', 0, 127, 60),
    ('PatchNumber', 'Patch number', 0, 127, 0),
    ('Transpose', 'Transpose', -24, 24, 0),
    ('WaveNumber', 'Wave number', 1, 464, 1),
    ('EffectAlgorithm', 'Effect algorithm', 1, 4, 1)
]

# class Depth: Integer {
#    override class var minimumValue: Int { 0 }
#    override class var maximumValue: Int { 99 }
#    override class var defaultValue: Int { 0 }
#}

for spec in specs:
    class_name = spec[0]
    comment = spec[1]
    min_value = int(spec[2])
    max_value = int(spec[3])
    range_string = f'{min_value}...{max_value}'
    default_value = int(spec[4])
    print(f'/// {comment} ({range_string}, default {default_value})')
    print(f'public class {class_name}: Integer' + ' {')
    values = {'minimumValue': min_value, 'maximumValue': max_value, 'defaultValue': default_value}
    for key in values:
        print(f'    override class var {key}: Int' + ' { ' + str(values[key]) + ' }')
    print('}')

    print()
