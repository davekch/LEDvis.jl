module LEDLayout

export Layout, withlayout, width, height
using ..Layers


"""
    Layout(matrix::Matrix{Bool})

describes the layout of a LED strip
"""
struct Layout
    matrix::Matrix{Bool}
    # should in the future also contain instructions how to serialize
    # this; ie in what order the pixels come
end

width(layout::Layout) = size(layout.matrix, 2)
height(layout::Layout) = size(layout.matrix, 1)

function withlayout(image, layout::Layout)
    ifelse.(layout.matrix, image, missing)
end


"""
    fromfile(filepath)

read a LEDLayout.Layout from a file.
expects a Matrix{Bool} in text format.
"""
function fromfile(filepath)
    f = open(filepath, "r") do io
        read(io, String)
    end
    # split lines and remove all whitespace
    f = map(filter(!isspace), split(f, '\n'))
    height = length(f)
    width = length(f[1])
    layout = falses(height, width)
    for (j, line) in enumerate(f)
        for (i, c) in enumerate(line)
            layout[j, i] = c == '1'
        end
    end
    Layout(layout)
end


end # module LEDLayout