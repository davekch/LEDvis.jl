using Ledvis
using .Layers, .Visualize, .LEDLayout, .Animate

pulse = pulsate(
    t -> Fields.absexpfield(255, t) ∘ (p -> p - center),
    t -> (_ -> 0),
    t -> (_ -> 0),
    0.05, 0.5, 0.05, W, H
)

for _ in 1:100
    cmap = pulse()
    asciivisualize(
        render([Layer([], cmap)], layout),
    )
    println()
    sleep(0.05)
end