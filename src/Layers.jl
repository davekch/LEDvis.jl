module Layers


export Color, Layer, LayerGroup, render, monochromatic, shapes
export field, colorfield, Fields

using ..Geometry
using ..LEDLayout
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
rgb(::Missing) = missing

function Base.:+(c1::Color, c2::Color)
    Color(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)
end

Base.:+(::Color, ::Missing) = missing
Base.:+(::Missing, ::Color) = missing

function Base.:*(f::Number, c::Color)
    Color(f * c.r, f * c.g, f * c.b)
end

Base.:*(::Missing, ::Color) = missing

function normalize(color::Color)
    # restrict all values to [0..255]; i don't want to do
    # this in the type itself because masks with negative colors
    # can be used as shadows
    Color(
        round(Integer, max(min(color.r, 255), 0)),
        round(Integer, max(min(color.g, 255), 0)),
        round(Integer, max(min(color.b, 255), 0)),
    )
end

normalize(::Missing) = missing

hex(c::Color) = c.r * UInt32(16^4) + c.g * UInt32(16^2) + c.b


function monochromatic(color::Color, w::Integer, h::Integer)
    [color for j in 1:h, i in 1:w]
end

"""
    createmask(shape::Shape, layout::Layout, full=false)

create a Matrix{Float64} matching the size of `layout` that is `1.0` where shape sits.
if `full` is `false` (the default), only the pixels relevant to the layout are computed,
the rest is `missing`. If `full` is `true`, the entire image is computed
"""
function createmask(shape::Shape, layout::Layout; full=false) end

function createmask(circle::Circle, layout::Layout; full=false)
    # pixelate the shape on a w x h matrix
    w = layout.width
    h = layout.height
    mask = Array{Any}(missing, h, w)
    if full
        idxs = [(j, i) for i = 1:w, j = 1:h]
    else
        idxs = indices(layout)
    end
    for (j, i) in idxs
        mask[j, i] = distance2([i, j], anker(circle)) <= radius(circle)^2 ? 1.0 : 0.0
    end
    mask
end

function createmask(rect::Rect, layout::Layout; full=false)
    w = layout.width
    h = layout.height
    mask = Array{Any}(missing, h, w)
    if full
        idxs = [(j, i) for i = 1:w, j = 1:h]
    else
        idxs = indices(layout)
    end
    A, B, C, D = edges(rect)
    # taken from here: https://math.stackexchange.com/questions/190111/how-to-check-if-a-point-is-inside-a-rectangle
    for (j, i) in idxs
        M = [i, j]
        inside = (0 < (A - M) ⋅ (A - B) < (A - B) ⋅ (A - B)) & (0 < (A - M) ⋅ (A - D) < (A - D) ⋅ (A - D))
        mask[j, i] = inside ? 1.0 : 0.0
    end
    mask
end

function createmask(glow::Glow, layout::Layout; full=true)
    # calculate the full mask, we want to know where the shape is no matter
    # the layout; the glow could leak into the layout even if the shape itself
    # may not be visible
    mask = createmask(glow.inner, layout; full=true)
    w = layout.width
    h = layout.height
    if full
        idxs = [(j, i) for i = 1:w, j = 1:h]
    else
        idxs = indices(layout)
    end
    for (j, i) in idxs
        if mask[j, i] > 0
            continue
        else
            # find the distance to nearest point of a shape (where it's 1.0)
            shapeindices = map(Tuple, findall(mask .== 1.0))
            if !isempty(shapeindices)
                d = minimum([distance2([j, i], [l, k]) for (l, k) in shapeindices])
                mask[j, i] = exp(-d / glow.t)
            end
        end
    end
    mask
end

"""
    field(f, w::Integer, h::Integer)

apply `f([i, j])` to every element with indices `j, i` in a h×w matrix
"""
function field(f, w::Integer, h::Integer)
    A = Array{Any}(undef, h, w)
    for j = 1:h, i = 1:w
        A[j, i] = f([i, j])
    end
    A
end

colorfield(red, green, blue) = map(normalize ∘ Color, red, green, blue)

"""
contains handy functions to define color fields
"""
module Fields
using ..Geometry

"""
    expfield(a::Number, t::Number)

returns the function `f(p = [x, y]) = a * exp(-t * (x^2 + y^2))`
"""
expfield(a, t) = p -> a * exp(-t * (x(p)^2 + y(p)^2))

"""
    absexpfield(a::Number, t::Number)

returns the function `f(p = [x, y]) = a * exp(-t * (|x| + |y|))`
"""
absexpfield(a, t) = p -> a * exp(-t * (abs(x(p)) + abs(y(p))))

end #module fields


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


struct LayerGroup
    layers::Vector{Layer}
end

function to_colormap(layer::Layer, layout::Layout; full=false)
    # represent a layer as a simple matrix
    h, w = layout.height, layout.width # todo: check if all layers have the same dimension
    if full
        cmap = [Color(0, 0, 0) for j in 1:h, i in 1:w]
    else
        cmap = Array{Any}(missing, h, w)
        for (j, i) in indices(layout)
            cmap[j, i] = Color(0, 0, 0)
        end
    end
    if isempty(layer.shapes)
        mask = ones(h, w)
    else
        mask::Matrix{Union{Float64,Missing}} = zeros(h, w)
        for shape in keys(layer.shapes)
            # add all the masks together, making sure they don't get
            # larger than 1
            mask .+= min.(transparency(shape) .* createmask(shape, layout, full=full), ones(h, w))
        end
    end
    return cmap + mask .* layer.color
end


function to_colormap(layergroup::LayerGroup, layout::Layout; full=false)
    cmap = sum([to_colormap(layer, layout; full=full) for layer in layergroup.layers])
    return map(normalize, cmap)
end

function render(layers, layout::Layout; full=false)
    cmap = sum([to_colormap(layer, layout; full=full) for layer in layers])
    return map(rgb ∘ normalize, cmap)
end


end # module Layer

