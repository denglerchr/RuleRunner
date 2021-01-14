abstract type Signal end;

struct ScheduleSignal<:Signal end # Run a rule and put it back to waiting
struct RunSignal<:Signal end; # Run a non-scheduled rule once
struct StopSignal<:Signal end; # Stop a rule
#struct PauseSignal<:Signal end;