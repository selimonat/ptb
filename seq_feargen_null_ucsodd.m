function [s] = seq_feargen_null_ucsodd(s,rr,or,varargin)
%"null" given sequence so that transitions from UCS OR ODDBALL are
%balanced. This would mean same column sums in the transition matrix (over
%rows UCS and oddballs)

remove = 1;
if nargin == 4
   remove = 0;
end

conds           = unique(s);%all conditions + nulls
ttrial          = length(s);

%prune odds
if ~isempty(or)    
    o_i             = find(s==max(conds));%oddball index
    o_trial_current = length(o_i);%number of current oddballs
    o_trial_target  = round(ttrial*or);%number of oddballs to have
    
    
    %find cond after oddball
     fo = hist(s(o_i+1),max(conds)+1);
     imagesc(fo)
    %collects indices of transitions from oddball to cond=i and builts a
    %vector out of it
    for i=1:max(conds)
        trans_i(i,:)=Shuffle(strfind(s', [max(conds) i]));
    end
    
    %now i just take the first column completely and set it to
    %zero/varargin
    while length(find(s==max(conds))) ~= o_trial_target
        if remove
            s(trans_i(:,1)) = [];
            trans_i(:,1)=[];
            s(trans_i(1:2:end))=[];
            
        else
            s(trans_i(:,1)) = varargin{1};
            trans_i(:,1)=[];
            s(trans_i(1:2:end))= varargin{1};
            
        end
    end
    fprintf('%g oddballs are deleted/replaced...\n',o_trial_current - o_trial_target);   
end

%prune ucs
if ~isempty(rr)
    u_i=find(s==max(conds)-1); %indexes of ucs trials
    nucs = round(sum(s == 4)*(rr./(1-rr)));%how many do we need to have?
    tucs = sum(s == (max(conds)-1));
    
    %%%%stopped work here...
    if remove
        s(randsample(find(s == (max(conds)-1)),tucs-nucs)) = [];
    else
        s(randsample(find(s == (max(conds)-1)),tucs-nucs)) = varargin{1};
    end
    fprintf('%g UCSs are deleted/replaced...\n',tucs-nucs);
end

end

