@everywhere using RuleRunner, Dates

nrules = 500

rules = [Rule(x->(1+1), rand()*10+1) for i = 1:nrules]
rules[end] = Rule(x->println(Time(now())), 2)

for rule in rules
    schedule!(rule)
end

sleep(30)

for rule in rules
    stop!(rule)
end