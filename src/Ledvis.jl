module Ledvis

export Geometry, Layers, Animate, Visualize, LEDLayout
export W, H, purple, shadow, bkgpurple, bkgshadow, layout

include("Geometry.jl")
include("Layers.jl")
include("Animate.jl")
include("Visualize.jl")
include("LEDLayout.jl")

using .Layers

# convenience
const W = H = 17
const purple = Color(255, 0, 200)
const shadow = Color(-255, -255, -255)
const bkgpurple = monochromatic(purple, W, H)
const bkgshadow = monochromatic(shadow, W, H)
const layout = LEDLayout.fromfile("resources/layout.txt")


end # module ledvis
