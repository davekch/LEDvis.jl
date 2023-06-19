module Visualize

export asciivisualize


using ..Layers
using Crayons


function asciivisualize(colormap)
    io = IOBuffer()
    for row in eachrow(colormap)
        for r in row
            if ismissing(r)
                write(io, "$(Crayon(reset=true))  ")
            else
                write(io, "$(Crayon(background=r))  ")
            end
        end
        write(io, "$(Crayon(reset=true))\n")
    end
    println(String(take!(io)))
end


end # module Visualize