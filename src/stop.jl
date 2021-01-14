"""
Stop a running rule. Stops the counter and sends an abord signal to the remote rule.
"""
function stop!(rule::Rule)
    if isrunning(rule)
        close(rule.timer)
        cleanchannel!(rule.triggerchannel)
        put!(rule.triggerchannel, StopSignal())
    end
    rule.timer = nothing
    return rule
end