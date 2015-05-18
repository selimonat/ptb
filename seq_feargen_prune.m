function [s]=seq_feargen_prune(s,rr,or,varargin)
%[s]=seq_feargen_prune(s,rr,or,varargin)
%
%   Prunes a balanced sequence for target UCS and oddball conditions so
%   that the final sequence has a RR and OR occurence probability. RR and
%   RO are between 0 and 1. If VARARGIN is given, instead of removal, a
%   replacement is realized by the value in VARARGIN. Use 0 to switch
%   events to null.

remove = 1;
if nargin == 4
   remove = 0;
end

conds           = unique(s);%all conditions + nulls
ttrial          = length(s);
%prune odds
if ~isempty(or)    
    o_i             = s == max(conds);%oddball index
    o_trial_current = sum(o_i);%number of current oddballs
    o_trial_target  = round(ttrial*or);%number of oddballs to have    
    if remove
        s( randsample(find(s == max(conds)), o_trial_current - o_trial_target) ) = [];
    else
        s( randsample(find(s == max(conds)), o_trial_current - o_trial_target) ) = varargin{1};
    end
    fprintf('%g oddbals are deleted/replaced...\n',o_trial_current - o_trial_target);   
end

%prune ucs
if ~isempty(rr)
    nucs = round(sum(s == 4)*(rr./(1-rr)));%how many do we need to have?
    tucs = sum(s == (max(conds)-1));
    if remove
        s(randsample(find(s == (max(conds)-1)),tucs-nucs)) = [];
    else
        s(randsample(find(s == (max(conds)-1)),tucs-nucs)) = varargin{1};
    end
    fprintf('%g UCSs are deleted/replaced...\n',tucs-nucs);
end
