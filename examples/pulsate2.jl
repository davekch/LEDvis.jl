using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers, .Serial
using LibSerialPort

f = Animate.periodicparameter(identity, 1, 300, 15)
g = Animate.periodicparameter(identity, 1, 300, 11)
circle = Circle(1, center)
layers = [
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = f()), bkggreen),
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = g()), bkgpurple)
]

serial = LibSerialPort.open("/dev/ttyACM0", 115200)

t = @elapsed for _ = 1:600
    animate!(layers)
    rendered = render(layers, layout)
    write(serial, serialize(rendered, layout))
    asciivisualize(rendered)
    println()
    sleep(0.05)
end

println("$(t/600)s per loop")