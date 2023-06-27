module Animate

export animate!, linearmove, growcircle, rotate, pulsate
export Clock, start!, stop!, pause!, resume!, running, awaittick
import Dates
using ..Geometry
using ..Layers


@enum Event TICK STOP PAUSE RESUME
@enum ClockState INITIALIZED RUNNING PAUSED STOPPED


mutable struct Clock
    bpm::Integer
    resolution::Integer
    clockthread_::Union{UndefInitializer,Task}
    ticks::Channel{Event}   # channel to send ticks
    signals::Channel{Event}   # channel to receive stop, start, ...
    state::ClockState

    function Clock(bpm::Integer, resolution::Integer)
        ticks = Channel{Event}(Inf)
        signals = Channel{Event}(1)
        new(bpm, resolution, undef, ticks, signals, INITIALIZED)
    end
end

function start!(clock::Clock)
    if clock.state == RUNNING || clock.state == PAUSED
        @warn "clock was already started (now in state $(clock.state)). use resume! to resume a paused clock"
        return
    end
    clock.state = RUNNING
    # how much time in seconds must pass for each frame
    t_frame = 60 / (clock.bpm * clock.resolution)
    @info "clock is running $(clock.resolution) beats at $(clock.bpm)BPM ($(1/t_frame)Hz)"
    # start thread to send ticks
    task = Threads.@spawn begin
        @info "spawned clock ticking thread"
        # now run until stopped
        while clock.state != STOPPED
            # measure time of all instructions to sleep the rest of the tick
            t = @elapsed begin
                # check for incoming messages first
                if !isempty(clock.signals)
                    s = take!(clock.signals)
                    if s == PAUSE
                        clock.state = PAUSED
                        # wait for resume or stop
                        s_::Event
                        while (s_ = take!(clock.signals)) != RESUME || s_ != STOP
                        end
                    elseif s == STOP
                        clock.state = STOPPED
                        break  # <------------------ exit while
                    end  # the resume case does nothing
                end
                put!(clock.ticks, TICK)
            end
            # sleep for the remaining time
            if t_frame - t < 0
                @warn "clock can't keep up with framerate"
            end
            sleep(max(t_frame - t, 0))
        end
        @info "stopped clock"
    end
    clock.clockthread_ = task
end

function pause!(clock::Clock)
    if clock.state == RUNNING
        put!(clock.signals, PAUSE)
        # remove remaining ticks
        while !isempty(clock.ticks)
            _ = take!(clock.ticks)
        end
    else
        @warn "clock is currently not running ($(clock.state))"
    end
end

function resume!(clock::Clock)
    if clock.state != PAUSED
        @warn "clock is currently not paused ($(clock.state))"
    else
        put!(clock.signals, RESUME)
    end
end

function stop!(clock::Clock)
    clock.state = STOPPED
    put!(clock.signals, STOP)
    # remove remaining ticks
    while !isempty(clock.ticks)
        _ = take!(clock.ticks)
    end
end

function running(clock::Clock)
    clock.state == RUNNING || clock.state == PAUSED
end

function awaittick(clock::Clock)
    take!(clock.ticks)
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