function [seq]= FeargenSequencer(force,varargin)
%seq = FeargenSequencer(force,varargin);
%
%
%possible ISIs
%isis       = [1 2 3 4];%in terms of TRs.
isis        = [1 2 3];%in terms of TRs.
%
%RepeatVector = {[repmat(4,1,8) 1 1] [28 28 2]};%perfectly balanced when
%there are 4 different ISIs
*RepeatVector = {[repmat(3,1,8) 1 1] [30 30 3]};%perfectly
%balanced for 3 different ISIs (depending on the isis anyway).
%
%Example usage: FeargenSequencer(1,'isis',[1 2 3],'repeatvector',{[repmat(4,1,8) 1 1] [28 28 2]},'filenamesuffix','NonBalanced4')

%%
if rem(length(varargin),2) == 0
    name = '';
    for v = 1:2:length(varargin)
        
        if strcmpi(varargin{v},'isis');
            isis = varargin{v+1};
        elseif strcmpi(varargin{v},'repeatvector');
            RepeatVector = varargin{v+1};            
        elseif strcmpi(varargin{v},'filenamesuffix');
            %just something to add to the file name so that we know later
            %what it is what
            name = varargin{v+1};
        end
    end
end
%%
[~, b] = system('hostname');
%
if strcmp(deblank(b),'triostim1')
    p.path.baselocation           = 'C:\USER\onat\Experiments\';
    p.path.experiment            = [p.path.baselocation 'FearGeneralization_Scanner\Sequences\'];
elseif strcmp(deblank(b),'kosmos.fritz.box')
    p.path.baselocation           = '~/LabComputer/onat/Documents/Experiments/'
    p.path.experiment             = [p.path.baselocation 'FearGeneralization_Scanner/Sequences/'];
else
    p.path.baselocation           = '~/Documents/Experiments/';
    p.path.experiment             = [p.path.baselocation 'FearGeneralization_Scanner/Sequences/'];
end
%%
out = [];
if force
    %load ~/LabComputer/onat/Documents/Experiments/FearGeneralization_Scanner/BigPool.mat
    %total number of subjects, should be a multiple of the number of faces
    tSub                = 10;
    tFile               = 8;%we have 8 stimuli + null trial + oddball + ucs = 11 conditions.
    %
    tisis               = length(isis);
    prestim             = 0.5;%This is not being used anymore.
    %
    tTrainTrial         = 9;%number of training trials.
    %
    randgen_uniform     = @(n,mini,range) rand(1,n).*range+mini;
    %
    counter = 0;
    for cs_plus = 1:8;
        tic;
        %follows subject index, it is simpler to memorize        
        cs_neg  = mod( cs_plus + tFile/2-1, tFile)+1;%the opposite face
        %
        %10 represents for the moment the oddball trials
        %and 9 the UCS trials.
        map{1}  = [ 1:8 9 10 ];
        map{3}  = [ 1:8 9 10 ];
        map{2}  = [ cs_plus cs_neg 10];%mapping for the conditioning phase is dynamic.
        %
        for nphase = [1 2]%phase 3 is the same as 1.
            fprintf('=======================================\nCSP %d, phase %d\n',cs_plus,nphase);
            %init
            ucs     = [];
            stim_id = [];
            oddball = [];
            order   = [];
            tCond   = length(map{nphase});%with ucs condition and oddball it is 10
            
            %Get the sequence
            fprintf('Searching UCS, Oddball and Stim Sequence...\n');
            
            if nphase == 2
                while ~(oddball_check & ucs_check & common_check)
                    %[ucs_check oddball_check common_check]
                    %stimulus id sequence
                    GetStim_Sequence;
                    tTrial   = length(stim_id);
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
                    oddball         = stim_id == 10;
                end
                figure(1);
                plot(ucs,'ro-');
            hold on
            plot(oddball);
            hold off
            %pause;
            end
            
            %
            if nphase == 1
                while ~(oddball_check & ucs_check & common_check)
                    %fprintf('====\n');
                    counter = counter+1;
                    [ucs_check oddball_check common_check]
                    %stimulus id sequence
                    GetStim_Sequence;
                    %
                    tTrial   = length(stim_id);
                    %
                    if nphase == 2
                        %detect manually the UCS trials, these are taken from
                        %the CS+ condition, half of them is transformed to UCS
                        %trials
                        csplus_i          = find(stim_id == cs_plus);
                        %kill half of the trials
                        csplus_i          = randsample( csplus_i , round(length(csplus_i)./2));
                        stim_id(csplus_i) = 9;
                        %
                    end
                    ucs             = stim_id == 9;
                    oddball         = stim_id == 10;
                end
                
                figure(2)
                plot(X*b,'r');
                hold on;
                plot(rate,'ko-');
                title(mat2str(bint(1,:),3));
                hold off;
                figure(3)
                plot(ucs,'ro-')
                hold on
                plot(oddball,'bo-');
                hold off
                
            end
            
            fprintf('UCS, Oddball, Stim Sequence sequence found...\n');
            
            %Distribute the ISIs
            %We will not do this like this anymore.
            %isi                = BalancedDist(stim_id(1:end-1),isis);
            isi = [];
            for x = 1:tCond
                for y = 1:tCond
					keyboard
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
            isi(end+1)        = NaN;
            
            %prestim duration: this is the period where the fixation cross is
            %on but the stim is off.
            prestim_duration  = randgen_uniform( tTrial, prestim, prestim);
            %
            cross_position    = ones(1,length(stim_id)).*2;
            %deal all
            seq(nseq).phase(nphase+1).presentation.cond_id          = stim_id ;%will (not yet) contain all the original condition indices
            seq(nseq).phase(nphase+1).presentation.stim_id          = stim_id ;%will contain the condition indices
            seq(nseq).phase(nphase+1).presentation.isi              = isi;
            seq(nseq).phase(nphase+1).presentation.prestim_duration = prestim_duration;
            seq(nseq).phase(nphase+1).presentation.ucs              = ucs;
            seq(nseq).phase(nphase+1).presentation.cross_position   = cross_position;
            seq(nseq).cs_plus                                       = cs_plus;
            seq(nseq).cs_neg                                        = cs_neg;
            seq(nseq).phase(nphase+1).presentation.oddball          = oddball;
            %
            %now we need to replace the odd trials with face identities.
            %Here we exclude the UCS trials, so oddball trial can contain
            %the CS+ face.
            oddball_i     = find( oddball );
            seq(nseq).phase(nphase+1).presentation.stim_id(oddball_i) = randsample(setdiff(1:8,[cs_plus cs_neg]),length(oddball_i),1);
            
        end
        %
        %add the pre-experiment training trials
        fprintf('Dealing with the training sequence\n');
        seq(nseq).phase(1).presentation.stim_id              = randsample(setdiff(1:8,cs_plus),tTrainTrial,1);
        seq(nseq).phase(1).presentation.isi                  = ones(1,tTrainTrial);%make same isis all over
        seq(nseq).phase(1).presentation.prestim_duration     = randgen_uniform( tTrainTrial, prestim, prestim);
        seq(nseq).phase(1).presentation.ucs                  = zeros(1,tTrainTrial);
        seq(nseq).phase(1).presentation.cross_position       = ones(1,tTrainTrial)*2;
        seq(nseq).phase(1).presentation.oddball              = zeros(1,tTrainTrial);
        seq(nseq).phase(1).presentation.oddball([4 6])       = 1;
        %
        %
        %the test phase is EXACTLY THE SAME as the baseline phase
        seq(nseq).phase(4).presentation.stim_id          = seq(nseq).phase(2).presentation.stim_id;
        seq(nseq).phase(4).presentation.cond_id          = seq(nseq).phase(2).presentation.cond_id;
        seq(nseq).phase(4).presentation.isi              = seq(nseq).phase(2).presentation.isi;
        seq(nseq).phase(4).presentation.prestim_duration = seq(nseq).phase(2).presentation.prestim_duration;
        seq(nseq).phase(4).presentation.ucs              = seq(nseq).phase(2).presentation.ucs;
        seq(nseq).phase(4).presentation.cross_position   = seq(nseq).phase(2).presentation.cross_position;
        seq(nseq).phase(4).presentation.oddball          = seq(nseq).phase(2).presentation.oddball;
        
        %for the conditioning and test phases we replace 9 with the cs+
        %index
        for tobereplaced = [3 4]
            ucs_i                                                      = seq(nseq).phase(tobereplaced).presentation.stim_id == 9;
            seq(nseq).phase(tobereplaced).presentation.stim_id(ucs_i)  = cs_plus;
        end        
        save([p.path.experiment mfilename '_' datestr(now,'yymmdd_HHMM') '_' name],'seq');
        fprintf('This subject (%d) finished in %0.2g minutes\n',nseq,toc./60);
    end
    save([p.path.experiment mfilename '_' datestr(now,'yymmdd_HHMM') '_' name],'seq');
else
    d = dir([p.path.experiment '*.mat']);
    load([p.path.experiment d(end).name]);
end
%                                                           B/T  C
%==================================================================
% no UCS     in a row of 3                              :    +   +
% no Oddball in a row of 3                              :    +   +
% Exactly 1 ucs at the last 10%                         :    +   -
% Exactly 1 ucs at the first 10%                        :    +   -
% UCS occurs before CS+                                 :    +   +
% equally balancing between 1st and 2nd halves          :    -   +
% UCS doesn occur closer than 9 trials                  :    +   -
% oddball doesnt occur closer than 9 trials             :    +   -
% oddballs and UCS doesnt occur closer than 4 trials    :    +   -
% something must happend in the next 30 trials          :    +   -
% something must happend in the next 12 trials          :    +   +

    function out = ucs_check
        %returns one if the conditions is met
        out=false;
        if ~isempty(ucs);
            %CONDITIONING
% % % %             
% % % %             if nphase == 2
% % % %                 %are UCSs equally balanced between first and second halves
% % % %                 if sum(find(ucs) <= ceil(tTrial./2)) == round(sum(ucs)/2);
% % % %                     %fprintf('UCS+\n')
% % % %                     %no ucs in a row of 3
% % % %                     if sum(conv(double(ucs),[1 1 1]) == 3) == 0;
% % % %                         %fprintf('UCS++\n')
% % % %                         if sum(find(ucs) >= 0.9*tTrial) ~= 0
% % % %                         %first occurence of the dangerous face must be
% % % %                         %shocked
% % % %                         %if find(stim_id == cs_plus,1) > find(stim_id == 9,1);
% % % %                         %    fprintf('UCS+++\n')
% % % %                         out = true;
% % % %                         end
% % % %                     end
% % % %                 end
                
                %BASELINE AND TEST
% % % % %             elseif nphase == 1
% % % % %                 %no 3 UCSs in a serie
% % % % %                 if sum(conv(double(ucs),[1 1 1],'same') == 3) == 0;
% % % % %                     fprintf('UCS+\n')
% % % % %                     %Exactly zero UCS at the last part
% % % % %                     if sum(find(ucs) >= 0.9*tTrial) == 0
% % % % %                         fprintf('UCS++\n')
% % % % %                         %no more than 2 ucs per 10 trials
% % % % %                         if sum(conv(double(ucs),ones(1,30),'same') > 3) == 0;
% % % % %                             %    %are UCSs equally balanced between first and second halves
% % % % %                             if sum(find(ucs) <= ceil(tTrial./2)) == round(sum(ucs)/2);
% % % % %                                 fprintf('UCS++++\n')
% % % % %                                 out = true;
% % % % %                             end
% % % % %                         end
% % % % %                     end
% % % % %                 end
% % % % %             end
            %i dont really know what at the conditioning phase there should
            %be no trials at the end of the phase? if at all, may be this
            %is more relevant for the Baseline and Test Phases
            %%no UCS at the last 90% trials
            %RIGHT NOW THIS IS OFF, It has to be discussed?
        end
        %                     out = true;
    end
    function [out]=oddball_check
        out=false;
        %returns one if the condition is met
        if ~isempty(oddball);
            if nphase == 2
                
% % %                 %fprintf('oddball+\n')
% % %                 %are oddballs equally balanced between first and second halves
% % %                 if sum(find(oddball) <= ceil(tTrial./2)) == round(sum(oddball)/2);
% % %                     %fprintf('oddball++\n')
% % %                     %no oddballs in a series of 3
% % %                     if sum(conv(double(oddball),[1 1 1]) == 3) == 0;
% % %                         %fprintf('oddball+++\n')
% % %                         %if sum(find(ucs) >= 0.9*tTrial) == 0
% % %                         out = true;
% % %                         %end
% % %                     end
% % %                 end
                
            elseif nphase == 1
                
% % % %                 %the closest distance (excluding the one case
% % % %                 %where two ucs's follow each other) is 9 trials
% % % %                 x = sort(diff(find(oddball)));
% % % %                 if x(2) >= 10
% % % %                     %fprintf('oddball+\n')
% % % %                     out = true;
% % % %                 end
                
            end
        end
    end
    function [out]=common_check
        out=false;
        %returns one if the condition is met
        if ~isempty(oddball) && ~isempty(ucs)
            new = oddball+ucs;
            if nphase == 2
                x   = sort(diff(find(new)));
                %that is something has to happen within the next 12
                %trials...
                if max(x) < 12
                    %fprintf('common+\n')
                    out = true;
                end
                
            elseif nphase == 1%only for the baseline condition
% % % %                 
% % % %                 rate     = conv(double(new),ones(1,30),'valid');
% % % %                 X        = [[1:length(rate)]' ones(length(rate),1)];
% % % %                 [b bint] = regress( rate(:), X );
% % % %                 if sum(rate > 4) == 0
% % % %                     if bint(1)<=0 && bint(1,2)>=0
% % % %                         out = true;
% % % %                     end
% % % %                 end
            end
        end
    end

    function GetStim_Sequence
        
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
        [stim_id order]  = SecondOrderBalancedSequence( tCond, RepeatVector{nphase}, firstlast);
        %get the real condition index.
        stim_id          = map{nphase}(stim_id);
        
    end
%
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

d = dir([p.path.experiment '*.mat']);
load([p.path.experiment d(end).name]);

end
