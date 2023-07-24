module Animate

export animate!, linearmove, growcircle, rotate, pulsate
export Metronome, Clock, start!, stop!, pause!, resume!, running, awaittick
import Dates
using ..Geometry
using ..Layers


@enum Event TICK STOP PAUSE RESUME
@enum ClockState INITIALIZED RUNNING PAUSED STOPPED

abstract type Clock end


"""
    Metronome(bpm::Integer, ppq::Integer)

returns a Metronome that runs at `bpm` BPM with `ppq` pulses per quarter
"""
mutable struct Metronome <: Clock
    bpm::Integer
    ppq::Integer  # pulses per quarter
    clockthread_::Union{UndefInitializer,Task}
    ticks::Channel{Event}   # channel to send ticks
    signals::Channel{Event}   # channel to receive stop, start, ...
    state::ClockState

    function Metronome(bpm::Integer, resolution::Integer)
        ticks = Channel{Event}(Inf)
        signals = Channel{Event}(1)
        new(bpm, resolution, undef, ticks, signals, INITIALIZED)
    end
end

"""
    start!(clock::Metronome)

starts a metronome in a separate thread. tick events may be read with `awaittick(clock)`
"""
function start!(clock::Metronome)
    if clock.state == RUNNING || clock.state == PAUSED
        @warn "clock was already started (now in state $(clock.state)). use resume! to resume a paused clock"
        return
    end
    clock.state = RUNNING
    # how much time in seconds must pass for each frame
    t_frame = 60 / (clock.bpm * clock.ppq)
    @info "clock is running $(clock.ppq) beats at $(clock.bpm)BPM ($(1/t_frame)Hz)"
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
                        @info "clock paused, waiting for resume"
                        # wait for resume or stop
                        while (s_ = take!(clock.signals)) != RESUME && s_ != STOP
                            @debug "clock got signal while on pause: $(s_)"
                        end
                        if s_ == RESUME
                            @info "resuming clock ..."
                            clock.state = RUNNING
                        else
                            @info "stopping paused clock ..."
                            clock.state = STOPPED
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

function pause!(clock::Metronome)
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

function resume!(clock::Metronome)
    if clock.state != PAUSED
        @warn "clock is currently not paused ($(clock.state))"
    else
        put!(clock.signals, RESUME)
    end
end

function stop!(clock::Metronome)
    clock.state = STOPPED
    put!(clock.signals, STOP)
    wait(clock.clockthread_)
    # remove remaining ticks
    while !isempty(clock.ticks)
        _ = take!(clock.ticks)
    end
end

function running(clock::Metronome)
    clock.state == RUNNING || clock.state == PAUSED
end

"""
    awaittick(clock::Metronome)

wait until a tick event occurs in `clock`
"""
function awaittick(clock::Metronome)
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
        return shape
    end
    _linearmove!
end


function growcircle(dr, minr, maxr)
    function _growcirle!(circle::Shape)
        newr = radius(circle) + dr
        if newr > maxr
            newr = minr
        end
        setradius!(circle, newr)
    end
    _growcirle!
end


function rotate(dphi::Number)
    function inner(shape::Shape)
        setangle!(shape, Geometry.angle(shape) + dphi)
        return shape
    end
    inner
end


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
