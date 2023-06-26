using Ledvis
using .Animate, .Visualize, .Geometry, .LEDLayout, .Layers

f = Animate.periodicparameter(identity, 1, 300, 20)
g = Animate.periodicparameter(identity, 1, 300, 13)
circle = Circle(1, center)
layers = [
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = f()), bkggreen),
    Layer(Dict(Glow(circle, 1) => glow -> glow.t = g()), bkgpurple)
]

t = @elapsed for _ = 1:600
    animate!(layers)
    asciivisualize(
        render(layers, layout)
    )
    println()
    sleep(0.01)
end

println("$(t/600)s per loop")