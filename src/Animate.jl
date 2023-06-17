module Animate

export animate!, linearmove, growcircle
using ..Geometry
using ..Layers


function animate!(layer::Layer)
    for (shape, animation) in shapes(layer)
        animation(shape)
    end
end

function animate!(layers::Vector{Layer})
    for layer in layers
        animate!(layer)
    end
end


"""
moves a shape linearly in direction `(dx, dy)`
"""
function linearmove(dx, dy; factor=1, edgesx=missing, edgesy=missing)
    # save the anker for later
    p0 = undef
    v = Vec2D(dx, dy)
    function _linearmove!(shape::Shape)
        # if this is the first time calling, save the anker of the shape
        if p0 == undef
            p0 = anker(shape)
        end
        newanker = anker(shape) + factor * v
        # check if the anker moved out of bounds; if it did, reset to initial anker
        if (
            (!ismissing(edgesx) && (newanker.x < edgesx[1] || newanker.x > edgesx[2]))
            ||
            (!ismissing(edgesy) && (newanker.y < edgesy[1] || newanker.y > edgesy[2]))
        )
            newanker = p0
        end
        setanker!(shape, newanker)
    end
    _linearmove!
end


function growcircle(dr, minr, maxr)
    function _growcirle!(circle::Circle)
        newr = radius(circle) + dr
        if newr > maxr
            newr = minr
        end
        setradius!(circle, newr)
    end
    _growcirle!
end


end # module Animate