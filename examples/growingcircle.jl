using Ledvis
using .Geometry, .Layers, .Animate, .LEDLayout, .Visualize


c1 = Circle(3, W / 2, H / 2)
grow = growcircle(1, 1, 10)
layers = [
    Layer(Dict(c1 => grow), bkgpurple)
]

for _ in 1:50
    animate!(layers)
    asciivisualize(
        withlayout(
            evaluate(layers),
            layout
        )
    )
    println()
    sleep(0.1)
end
