module Timing

export Metronome, Clock, start!, stop!, pause!, resume!, running, awaittick

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


end  # module Timing