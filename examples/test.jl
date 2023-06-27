using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers, .Serial
using LibSerialPort

"""
test script to run an animation on the first 10 leds of a strip
"""

f = Animate.periodicparameter(t -> 20 * exp(-0.1t), 1, 30, 2)
circle = Circle(1, [1, 1])
layers = [
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = f()), bkgpurple)
]

serial = LibSerialPort.open("/dev/ttyACM0", 115200)

for _ = 1:600
    animate!(layers)
    rendered = render(layers, layout)
    serialized = serialize(rendered, layout)
    write(serial, serialized[begin:30])
    asciivisualize(rendered)
    println()
    sleep(0.01)
end
