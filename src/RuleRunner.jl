module RuleRunner

using Distributed

"""
Rule structure.
* Rule(description::String, callback::Function, interval::Number; init = nothing, persistent = nothing) *
The callback function must take a single input. The rule is called every "interval" seconds as callback(persistent).
An optionl init function can be provided that is called once at the beginning as init(persistent), which
can be used to, e.g., load data into the persistent variable. 
"""
mutable struct Rule
    description::String
    callback::Function
    init::Union{Function, Nothing}
    persistent::Any
    interval::Number
    timer::Union{Timer, Nothing} # A timer sending a trigger signal every interval seconds
    triggerchannel::RemoteChannel # push!(true) into this to start the rule, and 0 to clear it

    # Constructor
    function Rule(description::String, callback::Function, interval::Number; init = nothing, persistent = 0)
        remotechannel = RemoteChannel(()->Channel{Bool}(5), 1)
        isnothing(persistent) && (persistent = 0)
        return new(description, callback, init, persistent, interval, nothing, remotechannel)
    end
end

"""
Check if the rule is running by checking if a timer is running.
"""
isrunning(rule::Rule) = !isnothing(rule.timer) && rule.timer.isopen

"""
Start a rule, trigger execution every interval on a remote worker.
"""
function run!(rule::Rule)
    # check if the timer is already running
    if isrunning(rule)
        warning("Rule is already running, ignoring run! command.")
        return rule
    end

    # Clear remotechannel and start rule
    cleanchannel!(rule.triggerchannel)
    rule.timer = runremote(rule)

    return rule
end

function cleanchannel!(channel)
    while isready(channel)
        take!(channel)
    end
    return channel
end

"""Start the remote execution and
the timer that is triggering the rule"""
function runremote(rule)
    #remote_do(ruleonworker, ...)
    @spawnat :any ruleonworker(rule, rule.triggerchannel)
    timer = Timer( (timer) -> put!(rule.triggerchannel, true), 0; interval = rule.interval )
    return timer
end

"""This is running on a worker process and executing the callback function 
when a "true" is written in the rule.triggerchannel.
When a "false" is written in the rule.triggerchannel,
the rule stops"""
function ruleonworker(rule, remotechannel)
    # init if it is a function
    if !isnothing(rule.init)
        rule.init(rule.persistent)
    end
    # main loop
    while true
        run_status = take!(remotechannel) # run if 1, abord if 0
        if run_status
            try
                rule.callback(rule.persistent)
            catch e
                @warn "Rule callback failed with error: $e; abording rule"
                break
            end
        else
            break
        end
    end
    println("Rule returning")
    return rule.persistent
end

"""
Stop a running rule. Stops the counter and sends an abord signal to the remote rule.
"""
function stop!(rule::Rule)
    if isrunning(rule)
        close(rule.timer)
        cleanchannel!(rule.triggerchannel)
        put!(rule.triggerchannel, false)
    end
    rule.timer = nothing
    return rule
end


export Rule, run!, stop!

end
