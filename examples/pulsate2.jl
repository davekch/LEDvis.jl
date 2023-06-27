using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers, .Serial
using LibSerialPort

f = Animate.periodicparameter(identity, 1, 300, 15)
g = Animate.periodicparameter(identity, 1, 300, 11)
circle = Circle(1, center)
layers = [
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = f()), bkggreen),
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = g()), bkgpurple)
]

ticks, signals = metronome(80, 8)
