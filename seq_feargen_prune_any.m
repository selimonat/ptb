function [s]=seq_prune_any(s,rr,or)
%[s]=seq_pruned_mseq(s,rr,or)
%
%   Prunes a balanced sequence for target UCS and oddball conditions so
%   that the final sequence has a RR and OR occurence probability. RR and
%   RO are between 0 and 1.



conds           = unique(s);%all conditions + nulls
ttrial          = length(s);
%prune odds
if ~isempty(or)    
    o_i             = s == max(conds);%oddball index
    o_trial_current = sum(o_i);%number of current oddbalss
    o_trial_target  = round(ttrial*or);%number of oddballs to have    
    s( randsample(find(s == max(conds)), o_trial_current - o_trial_target) ) = [];
    fprintf('%g oddbals are deleted...\n',o_trial_current - o_trial_target);   
end

%prune ucs
if ~isempty(rr)
    nucs = round(sum(s == 4)*(rr./(1-rr)));%how many do we need to have?
    tucs = sum(s == (max(conds)-1));
    s(randsample(find(s == (max(conds)-1)),tucs-nucs)) = [];
    fprintf('%g UCSs are deleted...\n',tucs-nucs);
end
