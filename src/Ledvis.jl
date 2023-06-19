module Ledvis

export Geometry, Layers, Animate, Visualize, LEDLayout
export W, H, MX, MY, purple, green, shadow, bkgpurple, bkggreen, bkgshadow, layout

include("Geometry.jl")
include("Layers.jl")
include("Animate.jl")
include("Visualize.jl")
include("LEDLayout.jl")

using .Layers, .LEDLayout

# convenience
const layout = LEDLayout.fromfile("resources/layout_medium.txt")
const W = width(layout)
const H = height(layout)
# middle points
const MX = W ÷ 2 + 1
const MY = H ÷ 2 + 1
const purple = Color(255, 0, 200)
const green = Color(0, 255, 0)
const shadow = Color(-255, -255, -255)
const bkgpurple = monochromatic(purple, W, H)
const bkggreen = monochromatic(green, W, H)
const bkgshadow = monochromatic(shadow, W, H)


end # module ledvis
