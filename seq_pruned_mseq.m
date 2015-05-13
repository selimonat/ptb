function [ms]=seq_pruned_mseq(ttrial,rr,or)
%[ms]=seq_pruned_mseq(ttrial,rr,or)
%
%   Generates a pseudo-maximum length sequence, pruned for UCS and oddball
%   conditions.



%randomly create an mseq with 11^2 using random taps
ms0 = [];
for r = randsample(1:18,18);
    [ms0]=[ms0 ; mseq2(11,2,[],r)];
end
OK      = 1;
%ttrial is the target trials, however we have to cut it a bit longer so
%that when pruned target trial is reached. 
ttrial2 = ttrial;
while OK    
    ms = ms0(1:ttrial2);
    %prune
    conds           = unique(ms);%all conditions
    o_i             = ms == max(conds);%oddball index
    o_trial_current = sum(o_i);%number of current oddbalss
    o_trial_target  = round(ttrial*or);%number of oddballs to have
    ms( randsample(find(ms == max(conds)), o_trial_current - o_trial_target) ) = [];
        
    nucs = round(sum(ms == 4)*(rr./(1-rr)));%how many do we need to have?
    tucs = sum(ms == (max(conds)-1));
    ms(randsample(find(ms == (max(conds)-1)),tucs-nucs)) = [];        
    if length(ms) == ttrial        
        OK = 0;
    else
        ttrial2 = ttrial2 + 1;
    end
end