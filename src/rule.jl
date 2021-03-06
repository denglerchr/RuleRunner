"""
Rule structure.
* Rule(description::String, callback::Function, interval::Number; init = nothing, persistent = nothing) *
The callback function must take a single input. The rule is called every "interval" seconds as callback(persistent).
An optionl init function can be provided that is called once at the beginning as init(persistent), which
can be used to, e.g., load data into the persistent variable. 
"""
mutable struct Rule
    name::String
    description::String
    callback::Function
    init::Union{Function, Nothing}
    cleanup::Union{Function, Nothing}
    persistent::Any
    interval::Number
    timer::Union{Timer, Nothing} # A timer sending a trigger signal every interval seconds
    triggerchannel::AbstractChannel # push!(true) into this to start the rule, and 0 to clear it

    # Constructor
    function Rule(callback::Function, interval::Number; init = nothing, cleanup = nothing, persistent = 0, name::String = "No name", description::String = "No description :(")
        triggerchannel = Channel{Signal}(1)
        isnothing(persistent) && (persistent = 0)
        return new(name, description, callback, init, cleanup, persistent, interval, nothing, triggerchannel)
    end
end

"""
Check if the rule is running by checking if a timer is running.
"""
isrunning(rule::Rule) = !isnothing(rule.timer) && rule.timer.isopen
