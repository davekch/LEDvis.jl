module Animate

export animate!, linearmove, growcircle, rotate, pulsate, metronome, Event, TICK, START, STOP
import Dates
using ..Geometry
using ..Layers


@enum Event TICK START STOP


"""
    metronome(bpm::Integer, resolution::Integer=1)

returns `(ticks::Channel{Event}, signals::Channel{Event})`.
calling this function starts a seperate thread that waits for a `START`
event to be put in the `signals` channel. Once it receives it, it puts
`TICK` events in the `ticks` channel `bpm * resolution` times per minute
(±1ms uncertainty)
"""
function metronome(bpm::Integer, resolution::Integer=1)
    # how much time in seconds must pass for each frame
    t_frame = 60 // (bpm * resolution)
    send = Channel{Event}(Inf)
    receive = Channel{Event}(1)

    Threads.@spawn begin
        @info "thread spawned, waiting to start metronome"
        # wait until we get a start signal
        # note that this is not a busy loop because take is blocking
        while take!(receive) != START
        end
        @info "starting metronome"
        while true
            t = @elapsed begin
                if !isempty(send)
                    @warn "can't keep up with framerate"
                end
                put!(send, TICK)
                if !isempty(receive)
                    s = take!(receive)
                    if s == STOP
                        @info "stopping metronome..."
                        break
                    end
                end
            end
            sleep(max(t_frame - t, 0))
        end
    end
    (send, receive)
end


function clockedanimate(ticks::Channel{Event}, signals::Channel{Event})
    put!(signals, START)
    tocks = ["BOOM", "2", "3", "4"]
    ts = []
    # for testing purposes, let it run just 100 ticks
    for i = 0:99
        _ = take!(ticks)
        push!(ts, Dates.now())
        println(tocks[i%4+1])
    end
    put!(signals, STOP)
    diff(ts)
end


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
    end
    _linearmove!
end


function growcircle(dr, minr, maxr)
    function _growcirle!(circle::Circle)
        newr = radius(circle) + dr
        if newr > maxr
            newr = minr
        end
        setradius!(circle, newr)
    end
    _growcirle!
end


rotate(dphi) = rect::Rect -> setangle!(rect, Geometry.angle(rect) + dphi)


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