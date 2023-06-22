module LEDLayout

export Layout, withlayout, width, height
using ..Layers
import JSON


"""
    Layout(width::Integer, height::Integer, indices::Vector{Tuple})

describes the layout of a LED strip
"""
struct Layout
    width::Integer
    height::Integer
    indices::Vector{Tuple}
    matrix::Matrix{Bool}
    # make an inner constructor with `matrix` missing; it is generated based on 
    # the other parameters and should not be provided by the user
    # the reason it's a member is to avoid having to recompute it often
    function Layout(width::Integer, height::Integer, indices::Vector)
        m = falses(height, width)
        for ji in indices
            m[ji...] = true
        end
        new(width, height, indices, m)
    end
end


width(layout::Layout) = layout.width
height(layout::Layout) = layout.height

function withlayout(image, layout::Layout)
    ifelse.(layout.matrix, image, missing)
end


"""
    fromfile(filepath)

read a LEDLayout.Layout from a file.
expects a json containing all arguments for `Layer`.
"""
function fromfile(filepath)
    config = open(JSON.parse, filepath)
    idxs = [tuple(i...) for i in config["indices"]]
    Layout(config["width"], config["height"], idxs)
end


end # module LEDLayout