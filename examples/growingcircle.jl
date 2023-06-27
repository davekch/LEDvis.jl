using Ledvis
using .Geometry, .Layers, .Animate, .LEDLayout, .Visualize


c1 = Circle(3, W / 2, H / 2)
grow = growcircle(0.5, 1, 15)
layers = [
    Layer(Dict(c1 => grow), bkgpurple)
]

ticks, signals = metronome(120, 8)
