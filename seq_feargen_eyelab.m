function [seq]=seq_feargen_eyelab(condition,csp)
% FEARGENSEQUENCE_ET
% for 1 Circle!
%
% creates a sequence for all the gives faces (as defined by numbers in
% input FACE_STIMULI), adding UCS and Oddball trials as defined by the
% rates pOddball and pReinforcement.
% CSP (in face Number) contains the CSplus face.
% REP is the number of how often every transition (between faces) should be repeated (used by the
% SecondOrderBalancedSequence Script).
% method =1 for Baseline + Test, method=2 for Conditioning

% Reinforcement Rate (in Baseline + Test its automatically added, but in
% Cond. it needs to take RR of all the CSP faces as ucs.
seq.RR             = 0.3;
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
%% SEQ is between 1:tCond ==> 1 2 3 3 1 2 1 2 1 3 3 4
%% Stim ID = stimuli(SEQ)

if strcmp(condition,'c')
    rep_vec = [30 18 4 1];
    %for each entry in the sequence we assign a stimulus id so that
    %stimuli(sequence) gives us what we wnat to show on the screen
    stimuli = [csp csn csp oddball];%later oddball will be assigned randomly
    valid_oddballs         = mod([csp csn]+2,8);
    tface = 2;
elseif strcmp(condition,'t') ||  strcmp(condition,'b')
    rep_vec = [ones(1,8)*4 1 1];
    stimuli = [1:8 csp oddball];%ucs's are taken from the CSP indices
    valid_oddballs         = mod([csp csn]+2,8);
    tface = 8;
end



%% create the block-wise structure of trials
nb = 1;
seq.cond_id = [];
seq.CrossPosition=[];
OK=0;
seq.ucs   = logical(zeros(1,length(seq.cond_id)));
while ~OK
    
    % % if you need the chess fieldish structure of 1 and 2 to extend some
    % % transitions' repetitions:
    %     m=ones(length(stimuli),length(stimuli));
    %     m(1:2:end-2,2:2:end-2)=2;
    %     m(2:2:end-2,1:2:end-2)=2;
    
    
    %% Add the ucs trials, here we have to choose either by keeping the CSP
    %% faces seen by the subjects constant or not
    
    % this method 1 doesn't keep the amount of CSP faces (shocked +
    % non-schocked) equal to the repetition of other stimuli. so overall
    % participants see the CSP face a little bit more.
    
    [seq.cond_id,i]= seq_SecondOrderBalancedSequence(rep_vec,1);
    seq.stim_id    = stimuli(seq.cond_id);
    
    seq.oddball              = seq.cond_id == tface+2;
    seq.stim_id(seq.oddball) = RandSample( valid_oddballs,[1 sum(seq.oddball)]);
    
    seq.ucs     = seq.cond_id == (tface + 1);
    tucs = sum(seq.ucs);
    seq.tTrial             = length(seq.cond_id)
    
    OK=1%sanity_check;
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
%             seq.isi() = randsample(isis,rep);
            pos = nexts_clean(seq.cond_id(nexts_clean) == i)-1;
%             
            seq.isi(pos) = seq_BalancedDist(ones(1,length(pos)),isis);
%             
%             isipooldummy=Shuffle(repmat(isis,[1
%             ceil(rep/length(isis))+1]));
%             seq.isi(nexts_clean(seq.cond_id(nexts_clean) == i)-1) = isipooldummy(1:length(seq.isi(nexts_clean(seq.cond_id(nexts_clean) == i)-1)));
%             
        end        
    end
    %find transitions FROM ucs/odd, set them to max(isi)
    events_i=seq.ucs|seq.oddball;
    seq.isi(events_i) = max(isis);
    % from faces to ucs/odd should also be nicely random
    nanpos=isnan(seq.isi);
    seq.isi(isnan(seq.isi))=seq_BalancedDist(ones(1,sum(nanpos)),isis);
    seq.cond_id(end)=[];
    % % % % %         elseif method ==2
    % % % % %             % needs another balancing, because UCS is not an own balanced
    % % % % %             % condition, but within the CSP faces.
    % % % % %             %first find UCS and Oddballs and set them to max(isi)
    % % % % %             events_i=seq.ucs|seq.oddball;
    % % % % %             seq.isi(events_i)=max(isis);
    % % % % %             %then take no-ucs CSP faces and CSN faces and assign ISIs
    % % % % %             %randomly
    % % % % %             for first = 1:length(face_stimuli);
    % % % % %                 first_i=find(seq.cond_id==first&isnan([seq.isi NaN]));
    % % % % %                 nexts   = first_i+1;%transition to the following face
    % % % % %                 %nexts_clean = nexts(seq.cond_id(nexts) < length(face_stimuli)+1); %exclude trans to ucs/odd
    % % % % %                 nexts_clean = nexts(~(seq.ucs|seq.oddball));
    % % % % %
    % % % % %                 for i = find(unique(seq.cond_id(nexts_clean))<max(face_stimuli));
    % % % % %                     %for each destination face i, randomly assign an ISI
    % % % % %                     %create vector containing enough ISI material
    % % % % %                     seq.isi(nexts_clean(seq.cond_id(nexts_clean) == i)-1) = seq_BalancedDist(seq.isi(nexts_clean(seq.cond_id(nexts_clean) == i)-1),isis);
    % % % % %                 end
    % % % % %             end
    % % % % %
    % % % % %             % from faces TO ucs/odd should also be nicely random
    % % % % %
    % % % % %             seq.isi(isnan(seq.isi))= seq_BalancedDist(seq.isi(isnan(seq.isi)),isis);
    % % % % %             seq.isi(end)=7;
    % % % % %             seq.cond_id(end)=[];
    %         end
    
end

% duration = sum(seq.isi)+length(seq.cond_id)*trialduration;
% fprintf('Total duration is %02g minutes\n',duration./60);

FixationCrossSequence;

%% viz stuff.
visualization =1;
if visualization == 1
    plot(1:length(seq.ucs==1 ),seq.cond_id,'o-');
    hold on;
    plot(find(seq.ucs == 1),seq.cond_id(seq.ucs == 1),'+r','markersize',10);
    plot(find(seq.oddball == 1),seq.cond_id(seq.oddball == 1),'sg','markersize',10);
    hold off;
end

    function [OK]=sanity_check
        OK=0;
        % if ~isempty(oddball) && ~isempty(ucs)
        % % check if number of UCS is correct
        if sum(seq.ucs)==tucs
            % check for time trends in UCS
            rate=conv(double(seq.ucs),ones(1,20),'valid')';
            X = [[1:length(rate)]' ones(length(rate),1)];
            [b bint]= regress( rate, X );
            
            if bint(1)<=0 && bint(1,2)>=0
                %then 0 is within the CI, so it's not significant
                fprintf('No time trend in UCS.\n')
                if method==1
                    rate=conv(double(seq.oddball),ones(1,20),'valid')';
                    X = [[1:length(rate)]' ones(length(rate),1)];
                    [b bint]= regress( rate, X );
                    if bint(1)<=0 && bint(1,2)>=0
                        fprintf('No time trend in Oddballs.\n')
                        OK=1;
                    else
                        fprintf('Time trend in Oddballs...Creating New Sequence..\n')
                        OK=0;
                    end
                elseif method==2
                    % skip the Oddball time trend analyzer here... too few
                    % oddballs anyway
                    OK=1;
                end
            else
                OK=0;
                fprintf('Time trend in UCS...Creating New Sequence.\n')
            end
        else
            fprintf('%d UCS found instead of %d!\n',sum(seq.ucs),tucs)
            OK=0;
        end
    end

    function FixationCrossSequence
        seq.CrossPosition = nan(1,seq.tTrial);
%         cross_angles=linspace(0,30,17);
        radius=520; %in px
        cross_direction=[0 180];
        center         = [800 600]
        for ncond = 1:tface
            ind                              = seq.cond_id == ncond;
            seq.CrossPosition(ind) = seq_BalancedDist(ones(1,sum(ind)),cross_direction);
        end
        
        seq.CrossPosition(isnan(seq.CrossPosition)) = seq_BalancedDist(ones(1,sum(isnan(seq.CrossPosition))),cross_direction);     
        
        seq.CrossPosition = seq.CrossPosition + rand(1,293)*30-15;
        seq.CrossPosition=[cosd(seq.CrossPosition')*radius+center(1) sind(seq.CrossPosition')*radius+center(2)];
        
    end



end
