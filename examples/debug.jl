using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers, .Serial

rect1 = Rect(1, H + 1, [1, MY])
rect2 = Rect(1, H + 1, [MX, MY])
rect3 = Rect(1, H + 1, [W, MY])
layers = [
    Layer([rect1], bkgred),
    Layer([rect2], bkggreen),
    Layer([rect3], bkgblue)
]

clock = Metronome(20, 1)
