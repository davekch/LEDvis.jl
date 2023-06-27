using Ledvis
using .Geometry, .Visualize, .Animate, .Layers, .LEDLayout

l1 = Rect(2W, 1, 1, 1)
l2 = Rect(2W, 1, 7, 6)
l3 = Rect(2W, 1, 13, 12)
l4 = Rect(2W, 1, 19, 18)
l5 = Rect(2W, 1, 25, 24)
l6 = Rect(2W, 1, 31, 30)
dphi = π / 20
layers = [
    Layer(Dict(l1 => rotate(dphi)), bkgpurple),
    Layer(Dict(l2 => rotate(-dphi)), bkggreen),
    Layer(Dict(l3 => rotate(dphi)), bkgpurple),
    Layer(Dict(l4 => rotate(-dphi)), bkggreen),
    Layer(Dict(l5 => rotate(dphi)), bkgpurple),
    Layer(Dict(l6 => rotate(-dphi)), bkggreen)
]

ticks, signals = metronome(110, 16)
