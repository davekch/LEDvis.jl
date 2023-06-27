module Serial

export serialize, deserialize
using ..LEDLayout
import LibSerialPort
import Sockets

"""
    serialize(colormap::Matrix{Tuple{Integer}}, layout::Layout)

expects a matrix of RGB values and a layout object.
"""
function serialize(colormap, layout::Layout)
    ser = []
    for (j, i) in indices(layout)
        push!(ser, colormap[j, i]...)
    end
    map(UInt8, ser)
end


function deserialize(msg, layout::Layout)
    cmap = Array{Any}(missing, height(layout), width(layout))
    for (i, (y, x)) in enumerate(indices(layout))
        imin = (i - 1) * 3 + 1
        imax = (i - 1) * 3 + 3
        cmap[y, x] = tuple(msg[imin:imax]...)
    end
    cmap
end


function getserial(port::AbstractString, baudrate::Integer=115200)
    LibSerialPort.open(port, baudrate)
end

function gettcp(port::Integer=2002)
    server = Sockets.listen(port)
    @info "waiting for incoming connection to tcp server on port $(port)"
    Sockets.accept(server)
end


end # module Serial
