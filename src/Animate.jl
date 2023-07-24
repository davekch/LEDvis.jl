module Animate

export animate!, linearmove, growcircle, rotate, pulsate
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
    v = [dx, dy]
    function _linearmove!(shape::Shape)
        # if this is the first time calling, save the anker of the shape
        if p0 == undef
            p0 = anker(shape)
        end
        newanker = anker(shape) + factor * v
        # check if the anker moved out of bounds; if it did, reset to initial anker
        if (
            (!ismissing(edgesx) && (x(newanker) < edgesx[1] || x(newanker) > edgesx[2]))
            ||
            (!ismissing(edgesy) && (y(newanker) < edgesy[1] || y(newanker) > edgesy[2]))
        )
            newanker = p0
        end
        setanker!(shape, newanker)
        return shape
    end
    _linearmove!
end


function growcircle(dr, minr, maxr)
    function _growcirle!(circle::Shape)
        newr = radius(circle) + dr
        if newr > maxr
            newr = minr
        end
        setradius!(circle, newr)
    end
    _growcirle!
end


function rotate(dphi::Number)
    function inner(shape::Shape)
        setangle!(shape, Geometry.angle(shape) + dphi)
        return shape
    end
    inner
end


"""
    periodicparameter(f, minp, maxp, dp)

return a function that calls `f(p)` with p periodically moving from `minp` to `maxp`
and back, in steps of `dp`
"""
function periodicparameter(f, minp, maxp, dp)
    p = minp
    function _f()
        result = f(p)
        if p + dp > maxp
            dp = -dp
        elseif p + dp < minp
            dp = -dp
        end
        p += dp
        return result
    end
    _f
end


"""
    pulsate(redf, bluef, greenf, minp, maxp, dp, W, H)

returns a function that creates colorfields that vary periodically in time.  
Example:

    pulse = pulsate(
        t -> Fields.absexpfield(255, t),
        t -> (_ -> 0),
        t -> (_ -> 0),
        0.05, 0.5, 0.05, W, H
    )
    for _ in 1:20
        cmap = pulse()   # red blob with varying size on each iteration
        # ...
    end

Arguments:
- `redf`, `bluef`, `greenf`: functions of type `p::Number -> (v::Vector -> Number)`.
    the function should accept one parameter and return a function that turns a point into
    a number. that number will be the value for the respective color.
- `minp`, `maxp`, `dp`: on each successive call, the parameter `p` changes from `minp` to `maxp`
    and back in steps of `dp`
- `W`, `H`: the width and height of the generated colormap
"""
function pulsate(redf, bluef, greenf, minp, maxp, dp, W, H)
    periodicred = periodicparameter(redf, minp, maxp, dp)
    periodicgreen = periodicparameter(greenf, minp, maxp, dp)
    periodicblue = periodicparameter(bluef, minp, maxp, dp)
    function pulsatingcolorfield()
        red = field(periodicred(), W, H)
        green = field(periodicgreen(), W, H)
        blue = field(periodicblue(), W, H)
        return colorfield(red, green, blue)
    end
    pulsatingcolorfield
end



end # module Animate
