function [s] = seq_feargen_cloudseq(csp,phase)
%SEQ_FEARGEN_SEQ2FACES
%takes a pruned mseq (seq_feargen_mseq_pruned) and adds the remaining
%needed information
ok=0;
while ~ok
%create sequence until one passes the constraint-test
%method 2= baseline&test, 22 = conditioning
fprintf('Starting Constraint Check....\n')
if strcmp(phase,'baseline')
    [s]=seq_feargen_mseq_pruned(2,0.3,0.01);
elseif strcmp(phase,'cond')
    s=[];
    for n=1:2
    [s]=[s; seq_feargen_mseq_pruned(22,0.3,0.01)];
    end
elseif strcmp(phase,'test')
    s=[];
    for n=1:2
    [s]=[s; seq_feargen_mseq_pruned(2,0.3,0.01)];
    end
end

fprintf('Found appropriate sequence....\n')
%s has conditions only, so now we set up the whole seq structure as we had
%it in all versions
s.cond_id = s;
%assign ucs seq
s.ucs = (s.cond_id==(max(s.cond_id)-1));
%assign oddball seq
s.oddball = (s.cond_id==max(s.cond_id));
%got a sequence, see if it holds.
ok=seq_feargen_constraints(s,1,1,1,1,1);
end

%assign isis (uniform so far)
s.isi = ones(1,length(s.cond_id))*3;
%assign csp face to ucs 
s.stim_id = s.cond_id;
s.stim_id(s.stim_id==(max(s.cond_id)-1))=csp;

s.tTrial     = length(s.cond_id);
s.tFacetrial = sum(s.stim_id~=0);

%we want an index that gives us the distance from the csp face, e.g. for
%plotting it later
s.dist = s.stim_id-csp;
s.dist(s.cond_id==0)=NaN;
s.dist(s.cond_id==max(s.cond_id))=NaN;
%for baseline, face - shock symbol should also be NaN
if strcmp(phase,'baseline')
    s.dist(s.cond_id==max(s.cond_id)-1)=NaN;
end
%get fixation crosses from that function
fprintf('Balancing fixation cross positions....\n')
s.CrossPosition = seq_feargen_fixcross(s);


end

