using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers, .Serial, .Timing
using LibSerialPort

f = Animate.periodicparameter(identity, 1, 300, 5)
g = Animate.periodicparameter(identity, 1, 300, 3)
circle1 = Circle(1, center - [18, 0])
circle2 = Circle(1, center + [18, 0])
layers = [
    Layer(Dict(Glow(circle1, 1) => glow -> glow.t = f()), monochromatic(Color(180, 0, 100), W, H)),
    Layer(Dict(Glow(circle2, 1) => glow -> glow.t = g()), monochromatic(Color(0, 40, 150), W, H))
]

clock = Metronome(120, 8)
