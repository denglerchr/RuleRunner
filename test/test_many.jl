using RuleRunner, Dates

# try running many in parallel
nrules = 5000

rules = [Rule(x->(1+1), rand()*25+5; name = "Rule $i") for i = 1:nrules]
rules[end] = Rule(x->println(Time(now())), 2; name = "Timer Rule")

for rule in rules
    schedule!(rule)
end

sleep(30)

for rule in rules
    stop!(rule)
end
