function cleanchannel!(channel)
    while isready(channel)
        take!(channel)
    end
    return channel
end

isempty(channel) = !isready(channel)