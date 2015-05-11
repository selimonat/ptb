function [seq]=seq_feargen_eyelab(condition,balancing,isis)
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
% isis=[2 3 4 5]; could be anything
% balancing: 'quasiuniform' 'random' 'uniform' 'exponential'
%
% Example: seq=seq_feargen_eyelab('tshort',1,'constant',[3]);
%
% The CSP related information has to be inserted to the sequence, that is
% cond_ind -> stim_id transformation has to be computed separately.

trialduration  = .75;
% minimum ISI
mini_isi       = 2.5;
% minimum pre stimulus
mini_ps        = 0.4;
%% SEQ is between 1:tCond ==> 1 2 3 3 1 2 1 2 1 3 3 4
%% Decide on how to call SecondOrderBalanced function
null_events=0;
if strcmp(condition,'c')
    rep_vec = [30 18 4 1];
elseif strcmp(condition,'t')
    rep_vec = [ones(1,8)*4 1 1];
elseif strcmp(condition,'b')
    rep_vec = [ones(1,8)*4 1 1];
elseif strcmp(condition,'bshort')%with null events
    rep_vec = [ones(1,9)*2 1 1];
    null_events=1;%will shift everything so that null events are indexed as 0.
elseif strcmp(condition,'tshort')
    rep_vec = [ones(1,9)*2 1 1];
    null_events=1;
elseif strcmp(condition,'cshort')
    rep_vec = [30 30 18 4 1];
    null_events=1;
end
tcond = length(rep_vec);
tface = tcond-2;
%% create the block-wise structure of trials
seq.CrossPosition   = [];
OK                  = 0;
fprintf('Starting Constraint Check....\n')
while ~OK
    %create the 2nd Order Balanced Sequence
    [seq.cond_id,ranks]    = seq_SecondOrderBalancedSequence(rep_vec,1);
    %first and second from the last are special
    seq.oddball            = seq.cond_id == tcond;
    seq.ucs                = seq.cond_id == tcond-1;
    %check constraints.
    if ~(IsEventAfter(seq.ucs,0.95) || IsEventAfter(seq.oddball,0.95) || IsEventBefore(seq.oddball,0.1) || SlopeCheck(seq.ucs)  || IsEventTooFar(seq.ucs,40))
        OK=1;
        tucs               = sum(seq.ucs);
        seq.tTrial         = length(seq.cond_id);
        if null_events
           seq.cond_id = seq.cond_id - 1;
        end
        computeEff;
        computeEnt;
        fprintf('Constraint Check: OK. \n')
    end
end

%% final variables
%prestim durations should be smaller than ISI, right now they are [0.4 0.7]
seq.prestim_duration = mini_ps+rand(1,seq.tTrial).*.3;
%
DistributeISI;
FixationCrossSequence;

fprintf('Starting sanity checks: RR \n')

% real Reinforcement Rate
seq.RRR=tucs./(tucs+sum(seq.cond_id == 1));%any condition wd do it.
fprintf('The effective RRR is %g percent \n',seq.RRR*100);


fprintf('Starting sanity checks: Duration (s) \n')
duration = sum(seq.isi);
fprintf('Total duration is %02g minutes.\n',duration./60);

%% viz stuff.
visualization =0;
if visualization == 1
    subplot(3,1,1)
    plot(1:length(seq.ucs==1 ),seq.cond_id,'o-');
    hold on;
    plot(find(seq.ucs == 1),seq.cond_id(seq.ucs == 1),'+r','markersize',10);
    plot(find(seq.oddball == 1),seq.cond_id(seq.oddball == 1),'sg','markersize',10);
    hold off;
    subplot(3,1,2)
    n = hist3([seq.cond_id ; [seq.cond_id(2:end) NaN]]');
    imagesc(n)
    title('transition check');
    subplot(3,1,3)
    n = hist3([seq.cond_id ; [seq.cond_id(2:end) NaN]]');
    for y = 1:length(unique(seq.cond_id));
        for x = 1:length(unique(seq.cond_id));
            r = ranks(y,x,:);
            isis_m(y,x) = mean(seq.isi(r(~isnan(r))));
        end;
    end
    imagesc(isis_m);colorbar;
    title('Average ISIs');
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
        seq.CrossPosition=round([cosd(seq.CrossPosition')*radius+center(1) sind(seq.CrossPosition')*radius+center(2)]);
        
    end


    function [out]=IsEventAfter(seq,part)
        %returns TRUE if there is any events after PART percentile of
        %trials
        out = sum(find(seq) > part*length(seq)) ~= 0;
    end

    function [out]=IsEventBefore(seq,part)
        %returns TRUE if there is any events before PART percentile of
        %trials
        out = sum(find(seq) < part*length(seq)) ~= 0;
    end

    function [out]=IsEventTooFar(seq,distance)
        %the longest distance where nothing happens.
        out = max(sort(diff(find(seq)))) > distance;
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
    function computeEff
        Q = max(seq.cond_id);
        [dummy_eff  dummy_det]  = calc_meffdet(seq.cond_id , 10 , Q , 3 );
        seq.stats.eff           = dummy_eff(1);
        seq.stats.det           = dummy_det(1);
        [~,~,seq.stats.max_det,seq.stats.max_eff] = tcurve(Q,10,length(seq.cond_id));
        fprintf('Normalized efficiency is %03g...\n',seq.stats.eff./seq.stats.max_eff);
    end
    function computeEnt
        seq.stats.ent_order =0:5;
        for order = 0:5;
            [seq.stats.ent(order+1),dummy,seq.stats.entmax] = calcent(seq.cond_id,order);
        end
    end

    function DistributeISI
        % balance the ISI
        if strcmp(balancing,'uniform')
            seq.isi     = seq_BalancedDist(seq.cond_id,isis);
        elseif strcmp(balancing,'exponential')
            if length(isis)~=2
                fprintf('Enter correct parameters for exponential distribution [min mean]! \n')
                return
            end
            dummy=exprnd(isis(2),[1 seq.tTrial]);
            seq.isi      = isis(1)+floor(dummy*2)/2;
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
            nanpos                  = isnan(seq.isi);
            seq.isi(isnan(seq.isi)) = seq_BalancedDist(ones(1,sum(nanpos)),isis);
            seq.cond_id(end)        = [];
        elseif strcmp(balancing,'random')
            seq.isi  = randsample(isis,seq.tTrial,1);
        elseif strcmp(balancing,'constant')
            seq.isi = repmat(isis,[1,seq.tTrial]);
        end
        
    end
end
