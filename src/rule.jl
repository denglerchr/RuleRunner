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
    function Rule(callback::Function, interval::Number; init = nothing, persistent = 0, description::String = "No description :(")
        remotechannel = RemoteChannel(()->Channel{Signal}(1), 1)
        isnothing(persistent) && (persistent = 0)
        return new(description, callback, init, persistent, interval, nothing, remotechannel)
    end
end

"""
Check if the rule is running by checking if a timer is running.
"""
isrunning(rule::Rule) = !isnothing(rule.timer) && rule.timer.isopen
