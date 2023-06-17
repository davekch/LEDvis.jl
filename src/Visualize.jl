module Visualize

export asciivisualize


using ..Layers
using Crayons


function asciivisualize(colormap)
    for row in eachrow(colormap)
        for r in row
            if ismissing(r)
                print(Crayon(reset=true), "  ")
            else
                print(Crayon(background=r), "  ")
            end
        end
        println(Crayon(reset=true))
    end
end


end # module Visualize