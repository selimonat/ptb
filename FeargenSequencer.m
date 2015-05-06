function seq= FeargenSequencer(force)


[~, b] = system('hostname');
if strcmp(deblank(b),'triostim1')
    p.path.baselocation           = 'C:\USER\onat\Experiments\';
	p.path.experiment            = [p.path.baselocation 'FearGeneralization_Scanner\Sequences\'];
elseif ismac
	p.path.experiment            = '/Users/onat/Documents/BehavioralExperiments/2015_05_feargen_revision/sequences/';
else
    p.path.baselocation           = 'C:\Users\onat\Documents\Experiments\';
	p.path.experiment            = [p.path.baselocation 'FearGeneralization_Scanner\Sequences\'];
end

if force
    
    %total number of subjects, should be a multiple of the number of faces
    tSub       = 10;
    tFile       = 8;%we have 8 stimuli + null trial + oddball + ucs = 11 conditions.
    %
    seq_type    = 1;%1 for second order balanced design, 2 for mini block design
    
    %%number of trial repetition. We have 10 different
    %conditions, consequently tRepet must be multiple of 10.
    Repet       = 40;
    %
    %possible ISIs
    isis        = [1 2 3 4];%in terms of TRs.
    tisis       = length(isis);
    prestim     =  0.5;%minimum
    rr          = [1 1 NaN];%reinforcement ratings (number of UCS trials)
    or          = [0.25 0.1 NaN];%ratio of odd ball trials to trial repetition
    %
    tTrainTrial = 9;%number of training trials.
    %
    condition_labels = {'face_1' 'face_2' 'face_3' 'face_4' 'face_5' 'face_6' 'face_7' 'face_8' 'null' 'ucs' 'oddball'};
    %
    %map{2} is dynamically stored.
    %
    randgen_expo                  = @(mu,n)       random('exponential',mu,1,n)';
    randgen_uniform               = @(n,mini,range) rand(1,n).*range+mini;
    for nsub = 1:16;
        tic;
        %follows subject index, it is simpler to memorize
        cs_plus = mod( nsub-1 , tFile )+1;
        cs_neg  = mod( cs_plus + tFile/2-1, tFile)+1;%the opposite face
        %
        %mapping between condition indices to stimuli, MUST be the same
        %size as TREPET. 10 represents for the moment the oddball trials
        %and 9 the UCS trials.
        map{1}  = [ 1:8 9 10  ];
        map{3}  = [ 1:8 9 10  ];
        %old
        %map{2}  = [ cs_plus cs_neg 9 10];%mapping for the conditioning phase is dynamic.
        %new
        map{2}  = [ cs_plus cs_neg 10];%mapping for the conditioning phase is dynamic.
        %
        for nphase = [1 2]
            fprintf('=======================================\nSubject %d, phase %d\n',nsub,nphase);
            %init
            ucs     = [];
            stim_id = [];
            oddball = [];
            order   = [];
            %number of total conditions
            tCond   = length(map{nphase});%with ucs condition and oddball it is 11.
            %tRepet
            tRepet  = [ repmat(Repet,1,length(map{nphase})-2) Repet*rr(nphase) Repet*or(nphase) ];
            
            %we will select the UCS trials out from the CS+ trials, so that
            %the total repetition of the CS+ faces are not extremely
            %different.
            %old version
            %RepetVector = {[4 4 4 4 4 4 4 4 1 1] [12 12 12 1]};            
            %new version
            RepetVector = {[4 4 4 4 4 4 4 4 1 1] [28 28 2]};
            
            fprintf('Searching UCS, Oddball and Stim Sequence...\n');
           
            while ~(ucs_check & oddball_check) 
                %[ucs_check oddball_check]
                %stimulus id sequence
                GetStim_Sequence;
                tTrial   = length(stim_id);
                %obsolete (now UCS trials are anyway balanced)
                %ucs            = BalancedUCSSelection(stim_id,tRepet(nphase)./tCond(nphase),rr(nphase),cs_plus);
                %
                if nphase == 2
                    %detect manually the UCS trials, these are taken from
                    %the CS+ condition, half of them is transformed to UCS
                    %trials
                    csplus_i = find(stim_id == cs_plus);
                    %kill half of the trials
                    csplus_i = randsample( csplus_i , round(length(csplus_i)./2));
                    stim_id(csplus_i) = 9;
                    %
                end                
                ucs             = stim_id == 9;                
                %obsolete (
                %oddball                      = SelectOddTrials(stim_id(1:end-1),1);
                %oddball(end+1)               = 0;
                oddball         = stim_id == 10;
            end
            fprintf('UCS, Oddball, Stim Sequence sequence found...\n');
            %CONSTRAINTLESS SEQUENCES
            %ISI
            %We will not do this like this anymore.
            %isi                              = BalancedDist(stim_id(1:end-1),isis);
            isi = [];
            for x = 1:tCond
                for y = 1:tCond
                    
                loc             = Shuffle(squeeze(order(y,x,:)));
                loc(isnan(loc)) = [];
                tloc            = length(loc);
                if rem(tloc,tisis) == 0%so if we have 4 different ISIs we distribute this to 4 different transitions randomly
                    isi(loc) = BalancedDist(ones(1,tloc),isis);
                else%some transition occur not as many as the number of ISIs
                    isi(loc) = randsample(isis,tloc,true);
                end
                end
            end
                        
            isi(end+1)                       = NaN;            
            %prestim duration: this is the period where the fixation cross is
            %on but the stim is off.
            prestim_duration                 = randgen_uniform( tTrial, prestim, prestim);
            
            %initial cross position
            %Obsolete:
            %cross_position                   = BalancedDist(stim_id(1:end-1),[1 2]);
            %cross_position(end+1)            = Shuffle([1 2],1);%randomly put the last cross position
            %from now on only one single direction of movement
            %
            cross_position                    = ones(1,length(stim_id)).*2;
            %deal all
            sub(nsub).phase(nphase+1).presentation.cond_id          = stim_id ;%will (not yet) contain all the original condition indices
            sub(nsub).phase(nphase+1).presentation.stim_id          = stim_id ;%will contain the condition indices
            sub(nsub).phase(nphase+1).presentation.isi              = isi;
            sub(nsub).phase(nphase+1).presentation.prestim_duration = prestim_duration;
            sub(nsub).phase(nphase+1).presentation.ucs              = ucs;
            sub(nsub).phase(nphase+1).presentation.cross_position   = cross_position;
            sub(nsub).cs_plus                                       = cs_plus;
            sub(nsub).cs_neg                                        = cs_neg;
            sub(nsub).phase(nphase+1).presentation.oddball          = oddball;
            %
            %now we need to replace the odd trials with face identities.
            %Here we exclude the UCS trials...
            oddball_i     = find( oddball );
            sub(nsub).phase(nphase+1).presentation.stim_id(oddball_i) = randsample(setdiff(1:8,[cs_plus cs_neg]),length(oddball_i),1);
            
        end
        %add the pre-experiment training trials
        fprintf('Dealing with the training sequence\n');
        sub(nsub).phase(1).presentation.stim_id              = randsample(setdiff(1:8,cs_plus),tTrainTrial,1);
        sub(nsub).phase(1).presentation.isi                  = ones(1,tTrainTrial);%make same isis all over
        sub(nsub).phase(1).presentation.prestim_duration     = randgen_uniform( tTrainTrial, prestim, prestim);
        sub(nsub).phase(1).presentation.ucs                  = zeros(1,tTrainTrial);
        sub(nsub).phase(1).presentation.cross_position       = ones(1,tTrainTrial)*2;
        sub(nsub).phase(1).presentation.oddball              = zeros(1,tTrainTrial);
        sub(nsub).phase(1).presentation.oddball([4 6])       = 1;
        %
        %the test phase is EXACTLY THE SAME as the baseline phase
        sub(nsub).phase(4).presentation.stim_id          = sub(nsub).phase(2).presentation.stim_id;
        sub(nsub).phase(4).presentation.cond_id          = sub(nsub).phase(2).presentation.cond_id;
        sub(nsub).phase(4).presentation.isi              = sub(nsub).phase(2).presentation.isi;
        sub(nsub).phase(4).presentation.prestim_duration = sub(nsub).phase(2).presentation.prestim_duration;
        sub(nsub).phase(4).presentation.ucs              = sub(nsub).phase(2).presentation.ucs;
        sub(nsub).phase(4).presentation.cross_position   = sub(nsub).phase(2).presentation.cross_position;
        sub(nsub).phase(4).presentation.oddball          = sub(nsub).phase(2).presentation.oddball;
        
        %for the conditioning and test phases we replace 9 with the cs+
        %index
        for tobereplaced = [3 4]
            ucs_i                                                      = sub(nsub).phase(tobereplaced).presentation.stim_id == 9;
            sub(nsub).phase(tobereplaced).presentation.stim_id(ucs_i)  = cs_plus;
        end
        
    save([p.path.experiment mfilename '_' datestr(now,'yymmdd_HHMM') ],'sub');    
    fprintf('This subject (%d) finished in %0.2g minutes\n',nsub,toc./60);
    end
            
else
    seq = [];
    d = dir([p.path.experiment '*.mat']);
    dummy = load([p.path.experiment d(end).name]);
    seq = dummy.sub;
end
    function out = ucs_check
        %returns one if the conditions is met
        out = false;
        if ~isempty(ucs);
            if nphase == 2
                %are UCSs equally balanced between first and second halves
                if sum(find(ucs) <= ceil(tTrial./2)) == round(sum(ucs)/2);
                    out = true;
                end
            elseif nphase == 1
                
                %no more UCS at the few last trials
                if sum(find(ucs) >= 0.9*tTrial) == 0
                    %are UCSs equally balanced between first and second halves
                    if sum(find(ucs) <= ceil(tTrial./2)) == round(sum(ucs)/2);
                        %we need to add here a third one. The first
                        %presentation of the UCS in the test phase has to
                        %be shocked. This means the first occurence of UCS
                        %condition must be earlier than the first occurence
                        %of the CS+ condition.
                        if find(stim_id == cs_plus,1) > find(stim_id == 10,1);
                            out = true;
                        end
                    end
                end
            %i dont really know what at the conditioning phase there should
            %be no trials at the end of the phase? if at all, may be this
            %is more relevant for the Baseline and Test Phases
            %%no UCS at the last 90% trials               
            %RIGHT NOW THIS IS OFF, It has to be discussed?
            end
%             out = true;
            %[sum(find(ucs) <= ceil(tTrial./2))  sum(find(ucs) >= 0.9*tTrial) ]
        end
        
    end
    function [out]=oddball_check
        %returns one if the condition is met
        out = false;
        if ~isempty(oddball)
            %no overlap with UCS and oddball trials( no need to check this)
            if sum(oddball.*ucs) == 0
                %are oddballs equally balanced between first and second halves
                if sum(find(oddball) <= ceil(tTrial./2)) == round(sum(oddball)/2);
                    %we don't want to have 3 times oddball stimuli one
                    %after another. 2 times, we cannot avoid because of the
                    %balancing.
                    if sum(conv(double(oddball),[1 1 1]) == 3) == 0;                        
                        out = true;
                    end
                end
            end
        end
    end
    function GetStim_Sequence
        if seq_type == 1%second order balanced sequence
            %first and last stimulus should not be the CS+ stimulus...
            %This is 1/ not nice 2/ UCS's cannot be balanced with
            %respect to the following stimulus identity%furthermore it
            %is stupied to start with null trials. We deal with these
            %constrainst with setdiff and ignoring the last conditions.
            %tCond(nphase)-1: we don't want to start with null trials
            
            %We want to select with which condition we start the
            %experiment. This must exclude CS_PLUS,
            %NULL, UCS and ODDBALL trials.
            %
            valid_conditions = map{nphase}(map{nphase} <= 8);
            firstlast        = Shuffle(setdiff(valid_conditions,cs_plus),1);%this is now in the face space;
            %bring it back to the index space that the SOBS function
            %understands.
            firstlast        = find(map{nphase} == firstlast);
            [stim_id order]  = SecondOrderBalancedSequence( tCond, RepetVector{nphase}, firstlast);
            %get the real condition index.
            stim_id          = map{nphase}(stim_id);
        elseif seq_type == 2%mini block design
            ok = 1;
            while ok
                stim_id = [];
                for nrepet = 1:tRepet
                    stim_id = [stim_id randperm(tCond)];
                end
                ok = 0;
            end
        end
    end

    function [oddball]=SelectOddTrials(stim_seq,tOddball)
        %selects oddball trials in a balanced manner so that all possible
        %conditions in STIM_SEQ are selected equally likely as oddball.
        tt = map{nphase}(1:end-1);
        for i = tt
            ind(i,:) = Shuffle(find(stim_seq == i));
        end
        oddball                    = zeros(1,length(stim_seq));
        oddball(ind(tt,1:tOddball)) = 1;
    end

    function shuffled = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end

end