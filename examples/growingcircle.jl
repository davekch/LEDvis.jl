using Ledvis
using .Geometry, .Layers, .Animate, .LEDLayout, .Visualize


c1 = Circle(3, [W / 2, H / 2], 0.5)
glow = Glow(c1, 10)
grow = growcircle(0.5, 1, 15)
layers = [
    Layer(Dict(glow => grow), bkgpurple)
]

clock = Clock(120, 8)
