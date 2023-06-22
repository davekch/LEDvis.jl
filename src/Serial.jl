module Serial

export serialize
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
    ser
end


end # module Serial
