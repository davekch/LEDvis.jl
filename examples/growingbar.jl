using Ledvis
using .Geometry, .Layers, .Timing


rect = Rect(2W, 1, [MX, H])
glow = Glow(rect, 10)
f = Animate.periodicparameter(identity, 1, 20, 1)
layers = [
    Layer(Dict(glow => g -> begin
            t = f()
            setheight!(g.inner, t)
            g.t = 4 * t
        end), bkgpurple)
]

clock = Metronome(70, 8)

