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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%phase specific cond2stim assignments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s.stim_id = s.cond_id;
%ucs condition is csp face (cond+test)
if ~strcmp(phase,'baseline')
s.stim_id(s.stim_id==(max(s.cond_id)-1))=csp;
end
%cond 2 means csn in conditioning, 1 and 3 csp
if strcmp(phase,'cond')
    s.stim_id(s.stim_id==2)=mod( csp + 8/2-1, 8)+1;
    s.stim_id(s.stim_id==1)=csp;
end

s.tTrial     = length(s.cond_id);
s.tFacetrial = sum(s.stim_id~=0);

%we want an index that gives us the distance from the csp face, e.g. for
%plotting it later
s.dist = MinimumAngle((s.stim_id-1)*45,(csp-1)*45);
s.dist(s.cond_id==0)=NaN;
%oddball=1000
s.dist(s.cond_id==max(s.cond_id))=1000;
%ucs=500
s.dist(s.cond_id==max(s.cond_id)-1)=500;

%get fixation crosses from that function
fprintf('Balancing fixation cross positions....\n')
s.CrossPosition = seq_feargen_fixcross(s);




    function [a]=MinimumAngle(y,x)
        %[a]=MinimumAngle(x,y);
        %
        %finds the minimum angle between two angles given in degrees, the answer is
        %also in degrees. The clockwise distances from Y to X are considered as
        %positive. Opposite angles are considered as positive 180.
        
        x  = deg2rad(x);
        y  = deg2rad(y);
        
        a  = atan2(sin(x-y), cos(x-y));
        
        a  = -round(rad2deg(a));
        
        if any(abs(a) == 180);
            a(abs(a) == 180) = 180;
        end
    end


end

