ENV["PYTHON"] = ""
using PyCall
println(PyCall.python)


mutable struct MidiClock <: Clock
    port::Integer
    ppq::Integer
    ppq_div::Integer
    clockthread_::Union{UndefInitializer,Task}
    ticks::Channel{Event}   # channel to send ticks
    signals::Channel{Event}   # channel to receive stop, start, ...
    state::ClockState
    _i::Integer
    function MidiClock(port::Integer, ppq::Integer, ppq_div::Integer)
        ticks = Channel{Event}(Inf)
        signals = Channel{Event}(1)
        new(port, ppq, ppq_div, undef, ticks, signals, INITIALIZED, 0)
    end
end
export MidiClock


function start!(clock::MidiClock)
    rtmidi = pyimport("rtmidi")
    println(rtmidi)
    midiin = rtmidi.RtMidiIn()
    println(midiin)
    midiin.openPort(clock.port)
    midiin.ignoreTypes(true, false, true)
    clock.state = RUNNING
    clock._i = 0
    t = Threads.@spawn begin
        @info "started clock thread"
        while clock.state == RUNNING
            msg = midiin.getMessage()
            if !isnothing(msg)
                # @info "msg is not nothing, am at step$(i)"
                if clock._i % clock.ppq_div == 0
                    put!(clock.ticks, TICK)
                end
                clock._i += 1
            end
            sleep(0.0005)
        end
        @info "end thread"
    end
    clock.clockthread_ = t
end

function awaittick(clock::MidiClock)
    take!(clock.ticks)
end

function reset!(clock::MidiClock)
    clock._i = 0
end
export reset!

function running(clock::MidiClock)
    clock.state == RUNNING
end
