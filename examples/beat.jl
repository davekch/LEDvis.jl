using Ledvis
using .Geometry, .Layers, .Timing

PPQ = 8
BPM = 108

base_sequence = TriggerSequence(1 // 8, PPQ, [1, 0, 0, 1, 1, 0, 0, 0])
snare_sequence = TriggerSequence(1 // 4, PPQ, [0, 1])

function flash(sequence, transparencydecay, glowdecay)
    trigger = maketrigger(sequence)
    function _flash(glow::Glow)
        if trigger()
            settransparency!(glow, 1.0)
            glow.t = 70
        else
            settransparency!(glow, transparencydecay * transparency(glow))
            glow.t = glowdecay * glow.t
        end
    end
    _flash
end

function explode(sequence, minr, speed)
    trigger = maketrigger(sequence)
    function _explode(shape::Shape)
        if trigger()
            setradius!(shape, minr)
        else
            setradius!(shape, radius(shape) + speed)
        end
    end
    _explode
end

base_circle = Circle(1, center)
glow = Glow(base_circle, 70)
snare_circle = Circle(1, center)
snare_circle_shadow = Circle(2, center)
snare_speed = 8
layers = [
    Layer(Dict(glow => flash(base_sequence, 0.8, 0.4)), bkgblue),
    LayerGroup([
        Layer(Dict(Glow(snare_circle, 5) => explode(snare_sequence, 2, snare_speed)), monochromatic(Color(255, 180, 0), W, H)),
        Layer(Dict(snare_circle_shadow => explode(snare_sequence, 0.2, snare_speed)), bkgshadow)
    ])
]

clock = Metronome(BPM, PPQ)
