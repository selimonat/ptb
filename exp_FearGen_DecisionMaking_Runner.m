subject       = 999;
csp           = 1;
PainThreshold = 10;
%%
for world         = [1 2];
    % exp_FearGen_DecisionMaking(subject,phase,csp,PainThreshold,CurrentGains,world)
    phase         = 1;
    CurrentGains  = 0;
    p             = exp_FearGen_DecisionMaking(subject,phase,csp,PainThreshold,CurrentGains,world);
    %%
    phase         = 2;
    CurrentGains  = p.participant.earning_cumulative(end)
    p             = exp_FearGen_DecisionMaking(subject,phase,csp,PainThreshold,CurrentGains,world);
    %%
    phase         = 3;
    CurrentGains  = p.participant.earning_cumulative(end)
    p             = exp_FearGen_DecisionMaking(subject,phase,csp,PainThreshold,CurrentGains,world);
end
