module Layers


export Color, Layer, evaluate, monochromatic, shapes

using ..Geometry
import LinearAlgebra: ⋅

struct Color
    r
    g
    b
end

red(c::Color) = c.r
green(c::Color) = c.g
blue(c::Color) = c.b
rgb(c::Color) = (red(c), green(c), blue(c))

function Base.:+(c1::Color, c2::Color)
    Color(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)
end

function normalize(color::Color)
    # restrict all values to [0..255]; i don't want to don
    # this in the type itself because masks with negative colors
    # can be used as shadows
    Color(
        max(min(color.r, 255), 0),
        max(min(color.g, 255), 0),
        max(min(color.b, 255), 0),
    )
end

hex(c::Color) = c.r * UInt32(16^4) + c.g * UInt32(16^2) + c.b


function monochromatic(color::Color, w::Integer, h::Integer)
    [color for j in 1:h, i in 1:w]
end

"""
    createmask(shape::Shape, width, height)

create a width x height Matrix{Bool} that is true where shape sits
"""
function createmask(shape::Shape, w::Integer, h::Integer) end

function createmask(circle::Circle, w::Integer, h::Integer)
    # pixelate the shape on a w x h matrix
    mask = falses(h, w)
    for i = 1:w, j = 1:h
        mask[j, i] = distance2(Vec2D(i, j), anker(circle)) <= radius(circle)^2
    end
    mask
end

function createmask(rect::Rect, w::Integer, h::Integer)
    mask = falses(h, w)
    A, B, C, D = edges(rect)
    # taken from here: https://math.stackexchange.com/questions/190111/how-to-check-if-a-point-is-inside-a-rectangle
    for i = 1:w, j = 1:h
        M = [i, j]
        mask[j, i] = (0 < (A - M) ⋅ (A - B) < (A - B) ⋅ (A - B)) & (0 < (A - M) ⋅ (A - D) < (A - D) ⋅ (A - D))
    end
    mask
end


struct Layer
    shapes::Dict{Shape,Function}
    color::Matrix{Color}
end

function Layer(shapes::Vector, color::Matrix{Color})
    Layer(Dict([s => identity for s in shapes]), color)
end

width(layer::Layer) = size(layer.color, 2)
height(layer::Layer) = size(layer.color, 1)
shapes(layer::Layer) = layer.shapes

function evaluate(layers::Vector{Layer})  # todo: give better name
    # represent a layer as a simple matrix
    h, w = height(layers[1]), width(layers[1])  # todo: check if all layers have the same dimension
    background = [Color(0, 0, 0) for j in 1:h, i in 1:w]
    cmap = copy(background)
    for layer in layers
        if isempty(layer.shapes)
            mask = trues(h, w)
        else
            mask = falses(h, w)
            for shape in keys(layer.shapes)
                mask .|= createmask(shape, w, h)
            end
        end
        cmap += ifelse.(mask, layer.color, background)
    end
    return map(rgb ∘ normalize, cmap)
end


end # module Layer