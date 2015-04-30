function [seq]=seq_feargen_eyelab(condition,csp)
% FEARGENSEQUENCE_ET
% for 1 Circle!

% 
%
% creates a sequence for all the given faces, plus ucs and oddball.
% The sequence is 2ndOrderBalanced regarding Face Transitions, ISI and
% Fixation Crosses (balanced only left/right, not real angle).
% CSP (in face Number) contains the CSplus face.
% 
% condition='b' for Baseline, 't' for Test, and 'c' for Conditioning.

trialduration      = .75;
% minimum ISI
mini_isi       = 1.5;
% minimum pre stimulus
mini_ps        = 0.4;

isis=[2 3 4 5];
balancing='quasiuniform';
oddball  = 10;
ucs      = 9;
csn      = mod( csp + 8/2-1, 8)+1;
%store csp and csn in the output
seq.csp = csp;
seq.csn = csn;
%% SEQ is between 1:tCond ==> 1 2 3 3 1 2 1 2 1 3 3 4
%% Stim ID = stimuli(SEQ)

if strcmp(condition,'c')
    rep_vec = [30 18 4 1];
    %for each entry in the sequence we assign a stimulus id so that
    %stimuli(sequence) gives us what we wnat to show on the screen
    stimuli = [csp csn csp oddball];%later oddball will be assigned randomly
    valid_oddballs         = mod([csp csn]+2,8);
    tface = 2;
elseif strcmp(condition,'t') || strcmp(condition,'b')
    rep_vec = [ones(1,8)*4 1 1];
    stimuli = [1:8 csp oddball];%ucs's are taken from the CSP indices
    valid_oddballs         = mod([csp csn]+2,8);
    tface = 8;
elseif strcmp(condition,'b')
    % stimuli has to include stim_id=ucs==9, to keep the shock signal
    stimuli = [1:8 ucs oddball];
end



%% create the block-wise structure of trials

seq.cond_id = [];
seq.CrossPosition=[];
OK=0;
seq.ucs   = logical(zeros(1,length(seq.cond_id)));
fprintf('Starting Sanity Check....\n')
while ~OK
    
    %create the 2nd Order Balanced Sequence
    [seq.cond_id]= seq_SecondOrderBalancedSequence(rep_vec,1);
    %replace Conditions with real Stimuli numbers
    seq.stim_id    = stimuli(seq.cond_id);
    
    seq.oddball              = seq.cond_id == tface+2;
    seq.stim_id(seq.oddball) = RandSample( valid_oddballs,[1 sum(seq.oddball)]);
    
    seq.ucs     = seq.cond_id == (tface + 1);
    tucs = sum(seq.ucs);
    seq.tTrial             = length(seq.cond_id);

    
    
% % % % %         
    if ExcludeEvents(seq.ucs,0.95) || ExcludeEvents(seq.oddball,0.95) || ExcludeEvents(seq.oddball,0.1)|| SlopeCheck(seq.ucs)  || LongestNoEventDistance(seq.ucs,40) || TucsTest(seq.ucs,tucs)
    
        OK=0;        
    else
        OK=1;
        fprintf('Sanity Check: OK. \n')
    end
        
end

%% final variables
seq.cross_position   = ones(1,seq.tTrial).*2;
%prestim durations should be smaller than ISI, right now they are [0.4 0.7]
seq.prestim_duration = mini_ps+rand(1,seq.tTrial).*.3;
%
if ~isempty(csp)
    % real Reinforcement Rate
    seq.RRR=sum(seq.ucs)./length(find(seq.stim_id==csp));
    fprintf('The effective RRR is %g percent \n',seq.RRR*100);
end

% balance the ISI

if strcmp(balancing,'uniform')
    seq.isi     = seq_BalancedDist(seq.cond_id,isis);
elseif strcmp(balancing,'exponential')
    dummy=exprnd(.75,[1 seq.tTrial]);
    seq.isi      = mini_isi+floor(dummy*2)/2;
elseif strcmp(balancing,'quasiuniform')
    seq.isi = nan(1,seq.tTrial);
    seq.cond_id(end+1)=NaN;
    %         if method ==1
    %search for transitions from all 'first'=1:2or8 faces to sth else.
    for first = 1:tface;
        first_i = find(seq.cond_id==first);
        nexts   = first_i+1;%transition to the following face
        nexts_clean = nexts(seq.cond_id(nexts) < tface+1); %exclude trans to ucs/odd
        
        for i = unique(seq.cond_id(nexts_clean))
            %for each destination face, randomly assign an ISI
            pos = nexts_clean(seq.cond_id(nexts_clean) == i)-1;
            seq.isi(pos) = seq_BalancedDist(ones(1,length(pos)),isis);
        end        
    end
    %find transitions FROM ucs/odd, set them to max(isi)
    events_i=seq.ucs|seq.oddball;
    seq.isi(events_i) = max(isis);
    % from faces to ucs/odd should also be nicely random
    nanpos=isnan(seq.isi);
    seq.isi(isnan(seq.isi))=seq_BalancedDist(ones(1,sum(nanpos)),isis);
    seq.cond_id(end)=[];
    
    
end

duration = sum(seq.isi)+seq.tTrial*trialduration;
fprintf('Total duration is %02g minutes.\n',duration./60);

FixationCrossSequence;

%% viz stuff.
visualization =1;
if visualization == 1
    subplot(2,1,1)
    plot(1:length(seq.ucs==1 ),seq.cond_id,'o-');
    hold on;
    plot(find(seq.ucs == 1),seq.cond_id(seq.ucs == 1),'+r','markersize',10);
    plot(find(seq.oddball == 1),seq.cond_id(seq.oddball == 1),'sg','markersize',10);
    hold off;
    subplot(2,1,2)
    n = hist3([seq.cond_id ; [seq.cond_id(2:end) NaN]]');
    imagesc(n)
    title('transition check');
end


    function FixationCrossSequence
        seq.CrossPosition = nan(1,seq.tTrial);
        
        radius=520; %in px
        cross_direction = [0 180];
        center          = [800 600];
        for ncond = 1:tface
            ind                              = seq.cond_id == ncond;
            seq.CrossPosition(ind)           = seq_BalancedDist(ones(1,sum(ind)),cross_direction);
        end
        
        %Transitions to/from UCS/Oddball.
        seq.CrossPosition(isnan(seq.CrossPosition)) = seq_BalancedDist(ones(1,sum(isnan(seq.CrossPosition))),cross_direction);
        
        seq.CrossPosition = seq.CrossPosition + rand(1,length(seq.cond_id))*30-15;
        seq.CrossPosition=[cosd(seq.CrossPosition')*radius+center(1) sind(seq.CrossPosition')*radius+center(2)];
        
    end



    function [out]= TucsTest(seq,reference)
        %check if number of UCS is tUCS as supposed
        out=sum(seq)~=reference;
    end

    function [out]=ExcludeEvents(seq,part)
        %returns TRUE if there is no event on the last percentage of the
        %sequence.
        out = sum(find(seq)>= part*length(seq)) ==0;
    end


    function [out]=LongestNoEventDistance(seq,distance)
        %the longest distance where nothing happens.
        out = max(sort(diff(find(seq)))) < distance;
    end

    function [out]=SlopeCheck(seq)
        
        rate     = conv(double(seq),ones(1,30),'valid');
        X        = [(1:length(rate))' ones(length(rate),1)];
        [b bint] = regress( rate(:), X );
        if bint(1) <=0 && bint(1,2)>=0
            out = false;
        else
            out=true;
        end
        
    end

end
