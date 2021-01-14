
"""
Start a rule, trigger execution every interval on a remote worker.
"""
function schedule!(rule::Rule)
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

"""
Run a rule once. If the rule was not scheduled yet,
init(persistent) will be executed and the rule will be in pause state.
"""
function run(rule::Rule)
    if isrunning(rule)
        # Addition run for already scheduled rule
        timerfunc(nothing, rule.triggerchannel)
    else
        # Run once and return
        cleanchannel!(rule.triggerchannel)
        @spawnat :any ruleonworker(rule, rule.triggerchannel)
        put!(rule.triggerchannel, RunSignal())
    end
    return rule
end

function timerfunc(timer, triggerchannel)
    if isempty(triggerchannel)
        put!(triggerchannel, ScheduleSignal())
    else
        @warn "Previous rule execution not fínished, rule execution skipped."
    end
    return nothing
end

"""Start the remote execution and
the timer that is triggering the rule"""
function runremote(rule)
    #remote_do(ruleonworker, ...)
    @spawnat :any ruleonworker(rule, rule.triggerchannel)
    timer = Timer( (timer)->timerfunc(timer, rule.triggerchannel), 0; interval = rule.interval )
    return timer
end

"""This is running on a worker process and executing the callback function 
when a "true" is written in the rule.triggerchannel.
When a "false" is written in the rule.triggerchannel,
the rule stops"""
function ruleonworker(rule, triggerchannel)
    # init if it is a function
    if !isnothing(rule.init)
        try
            rule.init(rule.persistent)
        catch e
            @warn "Rule Init failed with error: $e; consider stopping the rule."
        end
    end
    # main loop
    while true
        signal = fetch(triggerchannel) # wait and get a Signal
        if isa(signal, ScheduleSignal)
            safecallback(rule)
        elseif isa(signal, RunSignal)
            safecallback(rule)
            break
        else
            break
        end
        isready(triggerchannel) && take!(triggerchannel)
    end
    isready(triggerchannel) && take!(triggerchannel)
    println("Rule returning")
    return rule.persistent
end

function safecallback(rule)
    try
        rule.callback(rule.persistent)
    catch e
        @warn "Rule callback failed with error: $e; consider stopping the rule."
    end
end