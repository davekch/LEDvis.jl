module Serial

export serialize, deserialize
using ..LEDLayout

"""
    serialize(colormap::Matrix{Tuple{Integer}}, layout::Layout)

expects a matrix of RGB values and a layout object.
"""
function serialize(colormap, layout::Layout)
    ser = []
    for (j, i) in indices(layout)
        push!(ser, colormap[j, i]...)
    end
    join(ser, ",")
end


function deserialize(msg, layout::Layout)
    ints = map(x -> parse(Int64, x), split(msg, ','))
    cmap = Array{Any}(missing, height(layout), width(layout))
    for (i, (y, x)) in enumerate(indices(layout))
        imin = (i - 1) * 3 + 1
        imax = (i - 1) * 3 + 3
        cmap[y, x] = tuple(ints[imin:imax]...)
    end
    cmap
    ser
end


end # module Serial
