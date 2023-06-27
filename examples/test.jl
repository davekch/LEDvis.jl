using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers, .Serial

"""
test script to run various animations in either the terminal, another terminal
(connected via tcp), on a LED strip or a combination of both

use like this: julia --project examples/test.jl rotatinglines tcp,serial

options for connections are tcp, serial, local. options for animations are 
all filenames in this folder (without .jl)
"""

const SERIAL_PORT_NAME = "/dev/ttyACM0"
const SERIAL_BAUDRATE = 115200
const TCP_PORT = 2002

animation = ARGS[1]
ports = split(ARGS[2], ',')

# import the animation code; should include `layers` and `clock`
include("$(@__DIR__)/$(animation).jl")
# open all the streams
ios = []
showterminal = false
for p in ports
    if p == "tcp"
        push!(ios, Serial.gettcp(TCP_PORT))
    elseif p == "serial"
        push!(ios, Serial.getserial(SERIAL_PORT_NAME, SERIAL_BAUDRATE))
    elseif p == "local"
        global showterminal = true
    end
end

Ledvis.run(layers, clock, ios; showterminal=showterminal)
