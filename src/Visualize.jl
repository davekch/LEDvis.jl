module Visualize

export asciivisualize


using ..Layers
using Crayons


function asciivisualize(colormap)
    for row in eachrow(colormap)
        for r in row
            print(Crayon(background=r), "  ")
        end
        println(Crayon(reset=true))
    end
end


end # module Visualize