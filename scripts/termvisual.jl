import Ledvis
using Ledvis.Visualize, Ledvis.Serial
using Sockets


socket = connect(2002)
while isopen(socket)
    @info "waiting to read"
    s = readline(socket)
    @info "read message, visualizing:"
    cmap = deserialize(s, Ledvis.layout)
    asciivisualize(cmap)
end
