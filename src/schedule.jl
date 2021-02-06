
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
        timerfunc(nothing, rule)
    else
        # Run once and return
        cleanchannel!(rule.triggerchannel)
        Threads.@spawn ruleonworker(rule, rule.triggerchannel)
        put!(rule.triggerchannel, RunSignal())
    end
    return rule
end

function timerfunc(timer, rule)
    if isempty(rule.triggerchannel)
        put!(rule.triggerchannel, ScheduleSignal())
    else
        @warn "$(rule.name): previous execution not fínished, rule execution skipped."
    end
    return nothing
end

"""Start the remote execution and
the timer that is triggering the rule"""
function runremote(rule)
    #remote_do(ruleonworker, ...)
    Threads.@spawn ruleonworker(rule, rule.triggerchannel)
    timer = Timer( (timer)->timerfunc(timer, rule), 0; interval = rule.interval )
    return timer
end

"""This is running on a worker process and executing the callback function 
when a "true" is written in the rule.triggerchannel.
When a "false" is written in the rule.triggerchannel,
the rule stops"""
function ruleonworker(rule, triggerchannel)
    # init if it is a function
    !isnothing(rule.init) && safeinit(rule)
    
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
    !isnothing(rule.cleanup) && safeclanup(rule)
    return nothing
end


function safecallback(rule)
    try
        rule.callback(rule.persistent)
    catch e
        @warn "Callback of rule $(rule.name) failed with error: $e; consider stopping the rule."
    end
end

function safeinit(rule)
    try
        rule.init(rule.persistent)
    catch e
        @warn "Init of rule $(rule.name) failed with error: $e."
    end
end

function safeclanup(rule)
    try
        rule.cleanup(rule.persistent)
    catch e
        @warn "Cleanup of rule $(rule.name) failed with error: $e."
    end
end