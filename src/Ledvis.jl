module Ledvis

export Geometry, Layers, Animate, Visualize, LEDLayout, Serial
export W, H, MX, MY, purple, green, shadow, bkgpurple, bkggreen, bkgshadow, layout, center

include("Geometry.jl")
include("LEDLayout.jl")
include("Layers.jl")
include("Animate.jl")
include("Visualize.jl")
include("Serial.jl")

using .Layers, .LEDLayout, .Animate, .Serial, .Visualize
using LibSerialPort

# convenience
const layout = LEDLayout.fromfile("resources/layout.json")
const W = width(layout)
const H = height(layout)
# middle points
const MX = W ÷ 2 + 1
const MY = H ÷ 2 + 1
const center = [MX, MY]
const purple = Color(255, 0, 200)
const green = Color(0, 255, 0)
const shadow = Color(-255, -255, -255)
const bkgpurple = monochromatic(purple, W, H)
const bkggreen = monochromatic(green, W, H)
const bkgshadow = monochromatic(shadow, W, H)


function run(layers::Vector{Layer}, ticks::Channel{Event}, signals::Channel{Event}, ios; showterminal=false)
    while true
        animate!(layers)
        rendered = render(layers, layout)
        serialized = serialize(rendered, layout)
        # blocks until next tick
        @debug "waiting for tick..."
        _ = take!(ticks)
        @debug "ticked!"
        if showterminal
            asciivisualize(rendered)
            println()
        end
        for io in ios
            write(io, serialized)
        end
    end
end


end # module ledvis
