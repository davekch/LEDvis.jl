module Ledvis

export Geometry, Layers, Animate, Visualize, LEDLayout, Serial
export W, H, MX, MY, purple, green, shadow, bkgpurple, bkgred, bkggreen, bkgblue, bkgshadow, layout, center

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
const red = Color(255, 0, 0)
const blue = Color(0, 0, 255)
const shadow = Color(-255, -255, -255)
const bkgpurple = monochromatic(purple, W, H)
const bkggreen = monochromatic(green, W, H)
const bkgred = monochromatic(red, W, H)
const bkgblue = monochromatic(blue, W, H)
const bkgshadow = monochromatic(shadow, W, H)


function run(layers::Vector{Layer}, clock::Clock, ios; showterminal=false)
    start_flag = true
    while start_flag || running(clock)
        animate!(layers)
        rendered = render(layers, layout)
        serialized = serialize(rendered, layout)
        if !running(clock)
            start!(clock)
            start_flag = false
        end
        # remove ticks we missed
        if length(clock.ticks.data) > 1
            while length(clock.ticks.data) > 0
                @warn "can't keep up with clock, skipping beats"
                awaittick(clock)
            end
        end
        # blocks until next tick
        @debug "waiting for tick..."
        awaittick(clock)
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

function run(layers::Vector{Layer}, clock::Clock)
    run(layers, clock, []; showterminal=true)
end


end # module ledvis
