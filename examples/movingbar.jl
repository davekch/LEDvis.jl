using Ledvis
using .Geometry, .Animate, .Layers

rect = Rect(W + 1, 6, [MX, -2])
glow = Glow(rect, 60)
background = [Color(250 * j / H, 220 * (1 - j / H), 120) for j = 1:H, _ = 1:W]
layers = [
    Layer(Dict(glow => linearmove(0, 1; edgesy=(-10, H + 1))), background)
]

clock = Clock(60, 8)

