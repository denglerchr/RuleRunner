@everywhere using RuleRunner, Dates

@everywhere function test_rule_cb(persistent)
    persistent[1] += 1
    println(Time(now()), ": persistent = ", persistent[1])
    return nothing
end

test_rule_with_init = Rule( test_rule_cb, 5; init = (pers)->pers[1] = 5, persistent = [-1])
test_rule_no_init = Rule( (x)->println("No persistent here"), 5)
test_rule_error = Rule( test_rule_cb, 5)

schedule!(test_rule_with_init)
sleep(2)
schedule!(test_rule_no_init)
sleep(2)
schedule!(test_rule_error)