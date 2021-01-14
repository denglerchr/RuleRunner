module RuleRunner

using Distributed

include("signals.jl")
include("helpers.jl")
include("rule.jl")
include("schedule.jl")
include("stop.jl")

export Rule, schedule!, stop!, isrunning

end
