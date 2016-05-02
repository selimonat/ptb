function [p]=exp_predCodfMRI(subject,phase,itration)

%check the response box!!!!


debug = 0;%debug mode

%replace parallel port function with a dummy function
[~, hostname]                 = system('hostname');
hostname                    = deblank(hostname);
% if strcmp(hostname,'Sepideh-PC') 
%     outp = @(x,y) fprintf('[%i %i]\n',x,y);
% end

if nargin ~= 3
    fprintf('Wrong number of inputs\n');
    keyboard;
end

commandwindow;
%clear everything 
clear mex global functions
if ~strcmp(hostname,'Sepideh-PC')
    cgshut;
    global cogent;
end
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);
%
el        = [];
p         = [];
SetParams;
SetPTB;
%
%init all the variables
t                         = [];
nTrial                    = 0;
%%
%Time Storage
TimeCueOnset              = [];
TimeCrossOnset            = [];
TimeEndStim               = [];
TimeEndTrial              = [];
TimeTrackerOff            = [];
p.var.event_count         = 0;
%%
if strcmp(p.hostname,'triostim1') 
    InitEyeLink;
end
WaitSecs(2);
if strcmp(p.hostname,'triostim1') 
     CalibrateEL;
end

% sep KbQueueStop(p.ptb.device);
% sep KbQueueRelease(p.ptb.device);
%save again the parameter file
save(p.path.path_param,'p');
if  phase>0
    p.var.ExpPhase  = phase;
    %sep CalibrateEL;
    for ninst = [3 30:1:37 301:306]
        ShowInstruction(ninst,1);
    end
    p.out.expStart = GetSecs;
    PresentStimuli;
end

%get the eyelink file back to this computer
if strcmp(p.hostname,'triostim1') 
    StopEyelink(p.path.edf);
end
%trim the log file and save
p.out.log = p.out.log(sum(isnan(p.out.log),2) ~= size(p.out.log,2),:);
%shift the time so that the first timestamp is equal to zero
p.out.log(:,1) = p.out.log(:,1) - p.out.log(1);
p.out.log      = p.out.log;%copy it to the output variable.
save(p.path.path_param,'p');
%
%move the file to its final location.
movefile(p.path.subject,p.path.finalsubject);
%close everything down
p.out.expEnd = GetSecs;
WaitSecs((p.out.expEnd-p.out.expStart)-(821*1.24))
cleanup;

 
    function PresentStimuli
        %Enter the presentation loop and wait for the first pulse to
        %arrive.
        %wait for the dummy scans
        
        [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%will log it
        p.out.firstPulse=secs(end);
        KbQueueStop(p.ptb.device);
        WaitSecs(.05);
        KbQueueCreate(p.ptb.device);
        KbQueueStart(p.ptb.device);
        %log the pulse timings.
        TimeEndTrial     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        fix_y        = p.presentation.CrossPosition;
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_y)];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, FixCross');
        Screen('Flip',p.ptb.w);
        for nTrial  = 1:p.presentation.tTrial;   
%             Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
            if (p.presentation.catch(nTrial))
               fix_y        = p.presentation.CrossPosition;
               cue_id       = randi(6);
               p.out.catch_id(nTrial) = cue_id;
               prestimdur   = p.presentation.prestimdurCatch(nTrial); %when cue apears 
               ISI          = p.presentation.catchisi(nTrial);
               TimeStimOnset     = TimeEndTrial + prestimdur + ISI - p.ptb.slack;
               p.out.catchCueOnset(nTrial)=TimeStimOnset  - prestimdur;
               [TimeEndTrial] = catchTrial(nTrial, TimeStimOnset, prestimdur, cue_id, fix_y);     
               fprintf('CatchOffsetTime: %05.8gs, Difference of %05.8gs\n',TimeEndTrial,TimeEndTrial-TimeStimOnset-4);
               [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
                %log everything but "pulse keys" as pulses, not as keypresses.
                pulses = (keycode == p.keys.pulse);
                if any(~pulses);%log keys presses if only there is one
                    Log(secs(~pulses),7,keycode(~pulses));
                end
                if any(pulses);%log pulses if only there is one
                    Log(secs(pulses),0,keycode(pulses));
                end
            end
                       
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            stim_add     = p.presentation.stim_add(nTrial);
            con_id       = p.presentation.con_id(nTrial);
            fix_y        = p.presentation.CrossPosition;
            ISI          = p.presentation.isi(nTrial);
            pain         = p.presentation.pain(nTrial);
            cue_id       = p.presentation.cue_id(nTrial);
            prestimdur   = p.presentation.prestimdur(nTrial); %when cue apears 
            TimeStimOnset     = TimeEndTrial + prestimdur + ISI - p.ptb.slack;
            p.out.stimOnset(nTrial)=TimeStimOnset;
            p.out.cueOnset(nTrial)=TimeStimOnset  - prestimdur;
            fprintf('%d of %d, S: %d, ISI: %d, pain: %d, OnsetTime: %05.8gs, ',nTrial,p.presentation.tTrial,stim_id,ISI,pain, TimeStimOnset);
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndTrial] = Trial(nTrial, TimeStimOnset, prestimdur, stim_add, stim_id, cue_id, con_id, pain, fix_y);
            %(nTrial,TimeStimOnset , prestimdur, stim_id , pain  , fix_i, oddball, dist )
            fprintf('OffsetTime: %05.8gs, Difference of %05.8gs\n',TimeEndTrial,TimeEndTrial-TimeStimOnset-4);
            %
            %dump it
            [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
            %log everything but "pulse keys" as pulses, not as keypresses.
            pulses = (keycode == p.keys.pulse);
            if any(~pulses);%log keys presses if only there is one
                Log(secs(~pulses),7,keycode(~pulses));
            end
            if any(pulses);%log pulses if only there is one
                Log(secs(pulses),0,keycode(pulses));
            end
            %now we have to detect if the subject has pressed the CONFIRM
            %key while the ODDBALL stimulus was on the screen.            
        end
        KbQueueRelease(p.ptb.device);
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        WaitSecs(6);
%         WaitPulse(p.keys.pulse,p.mrt.LastScans)
%         WaitPulse(p.keys.pulse,ceil(6./p.mrt.tr));%
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
    end
    function [TimeEndTrial]=Trial(nTrial, TimeStimOnset, prestimdur, stim_add, stim_id, cue_id, con_id, pain, fix_i)
                
        %get all the times
        TimeCueOnset        = TimeStimOnset  - prestimdur;
        TimeCrossOnset      = TimeStimOnset  - prestimdur + p.duration.cueDur;
        TimeEndStim         = TimeStimOnset  + p.duration.stim- p.ptb.slack;
        TimeEndTrial        = TimeStimOnset  + p.duration.stim- p.ptb.slack + p.duration.ratingDur;
        TimeTrackerOff      = TimeStimOnset  + 2 + p.duration.keep_recording;
        
        %% Cue Onset 
        imageArray = imread(char(strcat(p.path.cue,num2str(cue_id),'.png')));
        Screen('FillRect', p.ptb.w , p.stim.bg ); %always create a gray background
        Screen('PutImage', p.ptb.w, imageArray);
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCueOnset  = Screen('Flip',p.ptb.w,TimeCueOnset,0);
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset );
        Log(TimeCueOnset,1,cue_id);%cross onset.
        %% Fixation Onset
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.red, FixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOnset  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);        
        Log(TimeCrossOnset,2,fix_i);%cross onset.
        %turn the eye tracker on
        if strcmp(p.hostname,'triostim1') 
            StartEyelinkRecording(nTrial,stim_id,p.var.ExpPhase,pain,fix);
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        %% Draw the stimulus to the buffer
        if ~stim_id==0
            if stim_id <4
                Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
                Screen('FillRect',  p.ptb.w, p.stim.red, FixCross');
                Screen('DrawingFinished',p.ptb.w,0);
                %% STIMULUS ONSET
                TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
                MarkCED(p.com.lpt.address, p.com.lpt.pain);
                if strcmp(p.hostname,'triostim1') 
                    Eyelink('Message', 'pain Onset');
                end
                Buzz;
                Log(TimeStimOnset,3,stim_id);
            else
                imageTexture=p.ptb.stim_sprites(find(strcmp(p.stim.label,stim_add)));
                Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
                Screen('FillRect',  p.ptb.w, p.stim.red, FixCross');
                Screen('DrawingFinished',p.ptb.w,0);
                %% STIMULUS ONSET
                TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
                MarkCED(p.com.lpt.address, p.com.lpt.pic);
                if strcmp(p.hostname,'triostim1') 
                    Eyelink('Message', 'pic Onset');
                end
                Log(TimeStimOnset,3,stim_id);
                mytime=0;
                slope=10;
                while mytime<.5
                    thisContrast = 1/(1+exp(-slope*(mytime-0.25)));
                    % Draw the image to the screen
                    Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
                    Screen('DrawTexture', p.ptb.w, imageTexture, [], [], 0, [], thisContrast);                
                    Screen('FillRect',  p.ptb.w, p.stim.red, FixCross');
                    Screen('DrawingFinished',p.ptb.w,0);
                    % Increment the time
                    mytime = mytime + p.ptb.ifi;
                    % Flip to the screen
                    Screen('Flip', p.ptb.w);
                end
                Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
                Screen('DrawTexture', p.ptb.w, imageTexture);
                Screen('FillRect',  p.ptb.w, p.stim.red, FixCross');
                Screen('DrawingFinished',p.ptb.w,0);
                Screen('Flip', p.ptb.w);
            end
        end
        %log the stimulus onset
        
        %%   
        
        %% STIM OFF immediately
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, FixCross');
        TimeEndStim = Screen('Flip',p.ptb.w,TimeEndStim,0);
        %send eyelink and ced a marker        
        Log(TimeEndStim,4,con_id);%log the stimulus offset
        %
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        if strcmp(p.hostname,'triostim1') 
            Eyelink('Message', 'Stim Offset');
            Eyelink('Message', 'SLIDER_SCREEN');
            TimeTrackerOff    = StopEyelinkRecording;
        end
        if pain == 1
            fprintf('This was a pain trial!\n');
        else
            fprintf('This was a picture trial!\n');
        end
        %% rating
        %the super ratings:      
        [p.out.rating(nTrial,:), p.out.rt(nTrial,:), p.out.mans{nTrial}] = RatingCircle(p.rating.crect, p.rating.division, GetSecs, NaN, p.keys.one, p.keys.two, p.keys.three,p.keys.four, {p.rating.SliderTextL{1} p.rating.SliderTextR{1}},p.rating.message,1,p.duration.ratingDur);
%         [p.out.rating(nTrial,:), p.out.rt(nTrial,:)] = RatingSlider(p.rating.rect, p.rating.division, GetSecs, NaN, p.keys.one, p.keys.two, p.keys.three,p.keys.four, {p.rating.SliderTextL{1} p.rating.SliderTextR{1}},p.rating.message,1,p.duration.ratingDur);
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, FixCross');
        TimeEndTrial = Screen('Flip',p.ptb.w,TimeEndTrial,0);
        Log(TimeEndTrial,5,p.out.rating(nTrial,1));%log the stimulus offset
        Log(TimeEndTrial,6,p.out.rt(nTrial,1));        
    end

    function [TimeEndTrial]=catchTrial(nTrial, TimeStimOnset, prestimdur, cue_id, fix_i)
                
        %get all the times
        TimeCueOnset        = TimeStimOnset  - prestimdur;
        TimeCrossOnset      = TimeStimOnset  - prestimdur + p.duration.cueDur;
        TimeEndTrial        = TimeStimOnset  - p.ptb.slack + p.duration.ratingDur+2;
        TimeTrackerOff      = TimeStimOnset  + p.duration.keep_recording;
        
        %% Cue Onset   
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        imageArray = imread(char(strcat(p.path.cue,num2str(cue_id),'.png')));
        Screen('PutImage', p.ptb.w, imageArray);
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCueOnset  = Screen('Flip',p.ptb.w,TimeCueOnset,0);
        Log(TimeCueOnset,11,cue_id);%cross onset.
        %% Fixation Onset
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, FixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOnset  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);        
        Log(TimeCrossOnset,12,fix_i);%cross onset.
        %turn the eye tracker on
        %%   
        %% STIM OFF immediately
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        TimeEndStim = Screen('Flip',p.ptb.w,TimeStimOnset,0);
        %send eyelink and ced a marker        
        Log(TimeEndStim,13,cue_id);%log the stimulus offset
        %
        %% record some more eye data after stimulus offset.
        %% rating
        %the super ratings:      
        [p.out.catchCueMod(nTrial,1)] = RatingSlider(p.rating.rect, 2, GetSecs, NaN, p.keys.one, p.keys.two, p.keys.three, p.keys.four, {'Schmerz' 'Bild'},GetText(9),1,p.duration.ratingDur+2);
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, FixCross');
        TimeEndTrial = Screen('Flip',p.ptb.w,TimeEndTrial,0);
        Log(TimeEndTrial,14,p.out.catchCueMod(nTrial,1));%log the stimulus offset
        [p.out.catchCueInt(nTrial,1)] = RatingSlider(p.rating.rect, 3, GetSecs, NaN, p.keys.one, p.keys.two, p.keys.three, p.keys.four, {'niedrig' 'hoch'},GetText(10),1,p.duration.ratingDur+2);
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, FixCross');
        TimeEndTrial = Screen('Flip',p.ptb.w,TimeEndTrial+ p.duration.ratingDur+2,0);
        Log(TimeEndTrial,14,p.out.catchCueInt(nTrial,1));%log the stimulus offset
    end

    function SetParams
        p.parm.phase  = phase;
        p.parm.interation = itration; 
        %mrt business
        p.mrt.dummy_scan              = 7;%7 this will wait until the 6th image is acquired.
        p.mrt.LastScans               = 5;%7 number of scans after the offset of the last stimulus
        p.mrt.tr                      = 1.24;%in seconds.
        %will count the number of events to be logged
        p.var.event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\fazeli\scannerFiles';
            p.path.cue      = ['C:\USER\fazeli\scannerFiles\codes\NormCues\'];
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\USER\fazeli\scannerFiles';
            p.path.cue      = ['C:\USER\fazeli\scannerFiles\codes\NormCues\'];
        elseif strcmp(p.hostname,'Sepideh-PC')
            p.path.baselocation       = 'C:\Users\Sepideh\work\cueingPE';
            p.path.cue      = ['C:\Users\Sepideh\work\ncueingPE\matlabFiles\pilot\V-2\NormCues\'];
        else

        end
        
        p.path.experiment             = [p.path.baselocation  filesep];
        p.path.stim                   = [p.path.baselocation filesep 'stimuli' filesep 'Normalized' filesep];        
        p.path.stim24                 = [p.path.stim '24bit' filesep];        
        %
        p.subID                       = sprintf('s%02d',subject);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment  'tmp' filesep p.subID '_' timestamp filesep ];
        p.path.finalsubject           = [p.path.experiment  p.subID '_' timestamp filesep ];
        p.path.path_edf               = [p.path.subject  'eye' filesep];
        p.path.edf                    = sprintf([p.subID 'p%02d.edf' ],phase);
        p.path.path_param             = [p.path.subject 'stimulation' filesep 'data.mat'];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);
        mkdir([p.path.subject 'eye']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.jpg']);        
         p.stim.tFile                  = size(p.stim.files,1);%number of different files (including the pain symbol)
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
                
        %is all the captured bg values the same?
        
            %if so take it as the bg color
        p.stim.bg                      = [100 100 100];
        
        %bg of the rating screen.
        p.stim.bg_rating               = p.stim.bg;
        p.stim.white                   = [0 0 0];
        p.stim.red                     = [120 0 0];
        %% font size and background gray level
%         p.text.fontname                = 'Times New Roman';
        p.text.fontname                = 'Arial';
        p.text.fontsize                = 20;%18;%30;
        p.text.intfontsize                = 16;%18;%30;
        p.text.fixsize                 = 60;
        %rating business
        p.rating.division              = 4;%number of divisions for the rating slider
        %% get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        info                           = imfinfo(char(strcat(p.path.cue,'1.png')));
        p.cue.width                   = info.Width;
        p.cue.height                  = info.Height;
        %% keys to be used during the experiment
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner
        p.keys.confirm                 = KbName('4$');
        p.keys.two                     = KbName('1!');
        p.keys.three                     = KbName('2@');
        p.keys.four                   = KbName('3#');
        p.keys.one                    = KbName('4$');
%         p.keys.confirm                 = KbName('4');
%         p.keys.one                     = KbName('1!');
%         p.keys.two                     = KbName('2');
%         p.keys.three                   = KbName('3');
%         p.keys.four                    = KbName('4$');
        p.keys.pulse                   = KbName('5%');
        p.keys.el_calib                = KbName('v');
        p.keys.el_valid                = KbName('c');
        if ismac
            p.keys.escape                  = KbName('escape');
        else
            p.keys.escape                  = KbName('esc');
        end
        p.keys.enter                   = KbName('return');
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
%         p.com.lpt.address    = hex2dec('378');  %training
%         p.com.lpt.thermode    = hex2dec('E800');  %training
        p.com.lpt.address    = 888;  %scanner 
        p.com.lpt.thermode   = 888; %scanner
        %codes for different events                
        p.com.lpt.StimOnset  = 64;
        p.com.lpt.pic        = 32;
        p.com.lpt.pain       = 16;
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 2;%1.5;%2;%s
        p.duration.keep_recording      = 0.05;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.cueDur              = 0.5;
        p.duration.ratingDur           = 2;
        p.duration.pain                = 2;
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %this will deal all the presentation sequence related information
        %stimulus sequence
        if phase > 0
            load([p.path.baselocation  '\ExpParams\myexpPars.mat']);
            seq                                 = sequence{itration,phase};
            seq.tTrial                          = length(seq.stim_id);
            catchOrd                            = randperm(seq.tTrial); %1:1:130;%
            temp                                = Shuffle(seq.tisi);
            seq.isi                             = temp(1:seq.tTrial);
            seq.catchisi(catchOrd(1:4))         = temp(seq.tTrial+1:end);
            seq.catchisi(end+1:seq.tTrial)        = 0;
            seq                                 = rmfield(seq,'tisi');
            temp                                = Shuffle(seq.tpsdur);
            seq.prestimdur                      = temp(1:seq.tTrial);
            seq.prestimdurCatch(catchOrd(1:4))  = temp(seq.tTrial+1:end);
            seq.prestimdurCatch(end+1:seq.tTrial) = 0;
            seq                                 = rmfield(seq,'tpsdur');
            seq.catch(catchOrd(1:4))            = [1 1 1 1];
            seq.catch(end+1:seq.tTrial)           = 0;
            seq.stim_add (seq.stim_id==4)       = Shuffle(seq.stim_add (seq.stim_id==4));
            seq.stim_add (seq.stim_id==5)       = Shuffle(seq.stim_add (seq.stim_id==5));
            seq.stim_add (seq.stim_id==6)       = Shuffle(seq.stim_add (seq.stim_id==6));
        end
        %
        p.presentation                 = seq;
        clear seq
        %% create the randomized design
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        
        
        p.out.rating                  = zeros(p.presentation.tTrial,1);
        p.out.rt                      = zeros(p.presentation.tTrial,1);
        p.out.log                     = zeros(1000000,4).*NaN;
        p.out.firstPulse              = NaN;
        p.out.stimOnset               = zeros(p.presentation.tTrial,1);
        p.out.cueOnset                = zeros(p.presentation.tTrial,1);
        p.out.catchCueOnset           = zeros(p.presentation.tTrial,1);
        p.out.catchCueInt             = zeros(p.presentation.tTrial,1);
        p.out.catchCueMod             = zeros(p.presentation.tTrial,1);
        %%
        p.var.current_bg              = p.stim.bg;%current background to be used.
        %
        p.rating.message     = {};
        p.rating.SliderTextL = GetText(13);
        p.rating.SliderTextR = GetText(12);
        
        %Save the stuff
        save(p.path.path_param,'p');
        %
        function [FM labels] = FileMatrix(path)
            
            %Takes a path with file extension associated to regexp (e.g.
            %C:\blabl\bla\*.bmp) returns the file matrix
            dummy = dir(path);
            FM    = [repmat([fileparts(path) filesep],length(dummy),1) vertcat(dummy(:).name)];
            labels = {dummy(:).name};
        end
    end
   
    function [rating, rt] = RatingSlider(rect,tSection,secs,position,up,down,left,right,labels,message,numbersOn,ratingDur)
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        timewaitend= GetSecs + ratingDur;
        while GetSecs<=timewaitend     
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [~ , ~, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
            Screen('FillRect',p.ptb.w,p.var.current_bg);
        end
        bb = max(bb);
        bb_size = bb(3)-bb(1);%vertical size of the bb.
        %
        DrawSkala;
%         rating = NaN;
        ok = 1;
        while ok == 1 &&  GetSecs<=timewaitend
            [secs, keyCode, ~] = KbStrokeWait(p.ptb.device,timewaitend);
            keyCode = find(keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                switch keyCode
                    case up
                        position = 1;
                    case down
                        position = 2;
                    case left
                        position = 3;
                    case right
                        position = 4;
                end
                Log(secs,7,keyCode);
%                 ok =0;
                if position<tSection+1
                    DrawSkala; 
                else
                    position = NaN;
                end
            end
            if GetSecs>timewaitend
               break
            end
        end
        if GetSecs>timewaitend
           break
        end
        end
%         entTime=GetSecs;
        function DrawSkala
            Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
            %rating               = tSection - position + 1;
            rating               = position ;
            rt                   = secs;
            tick_x               = linspace(rect(1),rect(1)+rect(3),tSection+1);%tick positions
            tick_size            = rect(3)./tSection;
            ss                   = tick_size/5*0.9;%slider size.
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, p.stim.red, tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p.stim.white);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.4,rect(2), p.stim.white);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.4,rect(2), p.stim.white);
                end
            end
            %slider coordinates
            if ~isnan(position)
                slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
                %draw the slider
                Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            end
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            t = Screen('Flip',p.ptb.w);
            Log(t,-2,NaN);
        end
    end
    function [rating, rt ,mans] = RatingCircle(rect,tSection,secs,position,up,down,left,right,labels,message,numbersOn,ratingDur)
        timewaitend= GetSecs + ratingDur;
        while GetSecs<=timewaitend     
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [~ , ~, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
            Screen('FillRect',p.ptb.w,p.var.current_bg);
        end
        bb = max(bb);
        bb_size = bb(3)-bb(1);%vertical size of the bb.
        %
        cc = 0;
        DrawSkala;
%         rating = NaN;
        ok = 1;
        while ok == 1 &&  GetSecs<=timewaitend
            [secs, keyCode, ~] = KbStrokeWait(p.ptb.device,timewaitend);
            cc = cc+1;
            keyCode = find(keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                switch keyCode
                    case up
                        position = 1;
                    case down
                        position = 2;
                    case left
                        position = 3;
                    case right
                        position = 4;
                end
                Log(secs,7,keyCode);
%                 ok =0;
                if position<tSection+1
                    DrawSkala; 
                else
                    position = NaN;
                end
            end
            if GetSecs>timewaitend
               break
            end
        end
        if GetSecs>timewaitend
           break
        end
        end
%         entTime=GetSecs;
        function DrawSkala
            %rating               = tSection - position + 1;
            rating                = position ;
            rt                    = secs;
            if cc>0
                mans.rating(cc)    = position;
                mans.rt(cc)        = secs;
            else
                mans.rating(cc+1)    = NaN;
                mans.rt(cc+1)        = NaN;
            end
            
            tick_size            = rect(3)./tSection;
            ss                   = tick_size*0.25;%slider size.
            tick_x               = linspace(rect(1),rect(1)+rect(3),(tSection/2)+1);%tick positions
            tick_y               = linspace(rect(2),rect(2)+rect(4),(tSection/2)+1);%tick positions
            pointList(:,:,1)=[tick_x(2)-ss tick_y(1); tick_x(2) tick_y(1)-ss; tick_x(2)+ss tick_y(1); tick_x(2) tick_y(1)+ss];
            pointList(:,:,2)=[tick_x(3)-ss tick_y(2); tick_x(3) tick_y(2)-ss; tick_x(3)+ss tick_y(2); tick_x(3) tick_y(2)+ss];
            pointList(:,:,3)=[tick_x(2)-ss tick_y(3); tick_x(2) tick_y(3)-ss; tick_x(2)+ss tick_y(3); tick_x(2) tick_y(3)+ss];
            pointList(:,:,4)=[tick_x(1)-ss tick_y(2); tick_x(1) tick_y(2)-ss; tick_x(1)+ss tick_y(2); tick_x(1) tick_y(2)+ss];
      
            %
            for tick = 1:tSection%draw ticks
                slider = [pointList(2,1,tick) pointList(1,2,tick) pointList(3,1,tick) pointList(4,2,tick)];
                Screen('FillOval', p.ptb.w, p.stim.white, round(slider));
%                 Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , round(pointList(2,1,tick))+1.5*ss, round(pointList(1,2,tick))+1.5*ss,  p.stim.white);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},round(pointList(2,1,tick))+bb_size*1.4,round(pointList(1,2,tick)), p.stim.white);
                elseif tick == tSection
                    DrawFormattedText(p.ptb.w, labels{2},round(pointList(2,1,tick))-bb_size*1.4,round(pointList(1,2,tick)), p.stim.white);
                end
            end
            %slider coordinates
            if ~isnan(position)
                %draw the slider
                slider = [pointList(2,1,position) pointList(1,2,position) pointList(3,1,position) pointList(4,2,position)];
                Screen('FillOval', p.ptb.w, p.stim.red, round(slider));
            end
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            t = Screen('Flip',p.ptb.w);
            Log(t,-2,NaN);
        end
    end
    function ShowInstruction(nInstruct,waitforkeypress)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, then subject has to press a button to
        %make the instruction text dissappear. Otherwise you have to take
        %care of it later
        
        [text]= GetText(nInstruct);
        if ismember(nInstruct,[31:1:36])
            imageArray = imread(char(strcat(p.path.cue,num2str(nInstruct-30),'.png')));
            Screen('FillRect', p.ptb.w , p.stim.bg ); %always create a gray background
            Screen('PutImage', p.ptb.w, imageArray);
            DrawFormattedText(p.ptb.w,text, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
%             DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            Screen('DrawingFinished',p.ptb.w,0);
            t=Screen('Flip',p.ptb.w);

        else
            ShowText(text);
        end

        %let subject read it and ask confirmation to proceed. But we don't
        %need that in the case of INSTRUCT = 5;
        if waitforkeypress
            if nInstruct ~= 14%this is for the Reiz kommnt
                KbStrokeWait(p.ptb.device);
            else
                WaitSecs(2.5+rand(1));
            end
            Screen('FillRect',p.ptb.w,p.var.current_bg);
            t = Screen('Flip',p.ptb.w);
        else
            if ~ismember(nInstruct,[14]);%this is for the Reiz kommnt and danke message at the end
                KbStrokeWait(p.ptb.device);
            else
                WaitSecs(1+rand(1));
            end
        end
        
        
        function ShowText(text)
            
            Screen('FillRect',p.ptb.w,p.var.current_bg);            
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            Log(t,-1,nInstruct);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');            
            fprintf(text);
            fprintf('=========================================================\n');
            
        end
    end
    function [text]=GetText(nInstruct)
        if nInstruct == 0%Eyetracking calibration
            
            text = ['Wir kalibrieren jetzt den Eye-Tracker.\n\n' ...
                'Bitte fixieren Sie die nun folgenden weißen Kreise und \n' ...
                'bleiben so lange darauf, wie sie zu sehen sind.\n\n' ...
                'Nach der Kalibrierung dürfen Sie Ihren Kopf nicht mehr bewegen.\n'...
                'Sollten Sie Ihre Position noch verändern müssen, tun Sie dies jetzt.\n'...
                'Die beste Position ist meist die bequemste.\n\n'...
                'Bitte drücken Sie jetzt den oberen Knopf, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
            
        elseif nInstruct == 3%third Instr. of the training phase.
            text = ['Wir sind jetzt kurz vor Beginn des Experiments.\n'...
                'Wir möchten Sie nun noch einmal an die wichtigsten Punkte erinnern.\n\n'...
                'Drücken Sie eine beliebige Taste um fortzufahren.\n' ...
                ];
       elseif nInstruct == 30%third Instr. of the training phase.
            text = [' Es gibt 6 verschiedene Hinweisreize.\n' ...
                ];
       elseif nInstruct == 31%third Instr. of the training phase.
            text = ['Dies ist ein Hinweisreiz für \n'...
                'NIEDRIGEN SCHMERZ!\n' ...
                ];
       elseif nInstruct == 32%third Instr. of the training phase.
            text = ['Dies ist ein Hinweisreiz für \n'...
                'MITTELEREN SCHMERZ!\n' ...
                ];           
       elseif nInstruct == 33%third Instr. of the training phase.
            text = ['Dies ist ein Hinweisreiz für \n'...
                'STARKEN SCHMERZ!\n' ...
                ];            
      elseif nInstruct == 34%third Instr. of the training phase.
            text = ['Dies ist ein Hinweisreiz für ein \n'...
                'NEUTRALES BILD!\n' ...
                ];           
      elseif nInstruct == 35%third Instr. of the training phase.
            text = ['Dies ist ein Hinweisreiz für ein \n'...
                'MITTELSCHLIMMES BILD!\n' ...
                ];            
      elseif nInstruct == 36%third Instr. of the training phase.
            text = ['Dies ist ein Hinweisreiz für ein \n'...
                'SEHR SCHLIMMES BILD!\n' ...
                ];     
        elseif nInstruct == 37%third Instr. of the training phase.
            text = ['und, einige andere wichtige Punkte:\n'...
                ];    
        elseif nInstruct == 301%third Instr. of the training phase.
            text = ['1/ Konzentrieren Sie sich immer auf das Fixationskreuz.\n'...
                ];
        elseif nInstruct == 302%third Instr. of the training phase.
            text = ['2/ Merken Sie sich immer den Informationsgehalt des Hinweisreizes (Dreiecke).\n'...
                ];
        elseif nInstruct == 303%third Instr. of the training phase.
            text = ['3/ Bitte bewerten Sie die Wertigkeit \n'...
                'des Hinweisreizes in den Überprüfungsdurchgängen \n'...
                ];
        elseif nInstruct == 304%third Instr. of the training phase.
            text = ['4/ Lassen Sie sich vom Scannergeschehen nicht stören.\n'...
                ];
        elseif nInstruct == 305%third Instr. of the training phase.
            text = ['5/ Bewegen Sie sich nicht.\n'...
                ];
        elseif nInstruct == 306%third Instr. of the training phase.
            text = ['Drücken Sie jetzt die obere Taste, \n'...
                'das Experiment startet dann in wenigen Sekunden.\n' ...
                ];          
        elseif nInstruct == 9%
            %=================================================================================================================%
            text = ['Schmerz (1) oder Bild (2) ?'];            
        elseif nInstruct == 10
            text = ['Wie war die Intensität?'];
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
%             text = {'Sehr\nwahrscheinlich'};
            text = {'stark'};
        elseif nInstruct == 13
%             text = {'Überhaupt\nnicht\nwahrscheinlich'};
            text = {'neutral'};
        else
            text = {''};
        end
    end
    function SetPTB
        %KbName('UnifyKeyNames');
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.        
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.intfontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
%         Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %%Find the number of the screen to be opened
        screens                     =  Screen('Screens');
        p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor
%         p.ptb.screenNumber          =  1;%max(screens);%the maximum is the second monitor

        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end        
        %set the resolution correctly
        res = Screen('resolution',p.ptb.screenNumber);
%         HideCursor(p.ptb.screenNumber);        
        %spit out the resolution        
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
         p.ptb.ifi = Screen('GetFlipInterval', p.ptb.w);

        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
%         p.ptb.cue_win              =  [0.5*res.width-0.125*p.cue.width 0.5*res.height+0.125*p.cue.height 0.5*res.width+0.125*p.cue.width 0.5*res.height+0.375*p.cue.height;
%                                        0.5*res.width-0.25*p.cue.width 0.5*res.height-0.05*p.cue.height 0.5*res.width+0.25*p.cue.width 0.5*res.height+0.45*p.cue.height;
%                                        0.5*res.width-0.5*p.cue.width 0.5*res.height-0.35*p.cue.height 0.5*res.width+0.5*p.cue.width 0.5*res.height+0.65*p.cue.height;
%                                        ];
        p.ptb.cue_win              =  [0.5*res.width-0.125*p.cue.width 0.5*res.height-0.165*p.cue.height 0.5*res.width+0.125*p.cue.width 0.5*res.height+0.085*p.cue.height;
                                       0.5*res.width-0.25*p.cue.width 0.5*res.height-0.33*p.cue.height 0.5*res.width+0.25*p.cue.width 0.5*res.height+0.17*p.cue.height;
                                       0.5*res.width-0.5*p.cue.width 0.5*res.height-0.66*p.cue.height 0.5*res.width+0.5*p.cue.width 0.5*res.height+0.34*p.cue.height;
                                       ];

        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.cuerect               = [ p.ptb.midpoint(1)-p.cue.width/2 p.ptb.midpoint(2)-p.cue.height/2 p.ptb.midpoint(1)-p.cue.width/2+p.cue.width p.ptb.midpoint(2)-p.cue.height/2+p.cue.height];
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.ptb.midpoint(1)-p.stim.width/2+p.stim.width p.ptb.midpoint(2)-p.stim.height/2+p.stim.height];
        p.ptb.cross_shift           = [0 0];%[180 -120]./2.5;%incremental upper and lower cross positions
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%bb(1);%always the same
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2)+p.ptb.cross_shift;%bb(1);%always the same
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        p.ptb.fc_size               = 10;
        %
        %%
        %priorityLevel=MaxPriority(['GetSecs'],['KbCheck'],['KbWait'],['GetClicks']);
        Priority(MaxPriority(p.ptb.w));
        %this is necessary for the Eyelink calibration
        %InitializePsychSound(0)
        %sound('Open')
        %         Beeper(1000)
        LoadPsychHID
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.
        p.ptb.device        = [];
        %get all the required keys in a vector
        p.ptb.keysOfInterest = [];for i = fields(p.keys)';p.ptb.keysOfInterest = [p.ptb.keysOfInterest p.keys.(i{1})];end
        fprintf('Key listening will be restricted to %d\n',p.ptb.keysOfInterest)
        RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        %create a queue sensitive to only relevant keys.
        % KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %prepare parallel port communication. This relies on cogent i
        %think. We could do it with PTB as well.
%         if ismac
%             config_io64;
%             outp(p.com.lpt.address,0);
%             if( cogent.io.status ~= 0 )
%                 error('inp/outp installation failed');
%             end
%         end
        if ~strcmp(p.hostname,'Sepideh-PC')
            config_io;
            outp(p.com.lpt.address,0);
            outp(p.com.lpt.thermode,0);   % closes all channels - thermode LPT
            if( cogent.io.status ~= 0 )
                error('inp/outp installation failed');
            end
        end        
        %CORRECT
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %test whether CED receives the triggers correctly...        
        k = 0;
        while ~(k == 25 | k == 86 );
            pause(0.1);
            outp(p.com.lpt.address,128);% index for start of the experiment
            fprintf('=================\nDid the trigger test work?\n\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\nPress c to send it again, v to continue...\n')
            [~, k] = KbStrokeWait(p.ptb.device,GetSecs+2);
            if isempty(k)
                k = 25;
            else
                k = find(k);
            end
        end        
        fprintf('Continuing...\n');
        %
        p.rating.rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100]'
%         p.rating.crect       = [p.ptb.width*0.31-35  p.ptb.height*0.195 p.ptb.width*0.41-35 p.ptb.height*0.505]'+20;
        p.rating.crect       =[300 170 400 410]';
%         p.ptb.rateDiam   = 0.33*p.ptb.height;
%         p.rating.crect       = [ p.ptb.midpoint(1)-p.ptb.rateDiam/2 p.ptb.midpoint(2)-p.ptb.rateDiam/2 p.ptb.midpoint(1)-p.ptb.rateDiam/2+p.ptb.rateDiam p.ptb.midpoint(2)-p.ptb.rateDiam/2+p.ptb.rateDiam];

        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the pictures to the memory.
        p.ptb.stim_sprites     = CreateStimSprites(p.stim.files);%                        
        %%
        function [out]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:p.stim.tFile
                fprintf('Making PTB Texture for stimulus %i of %i\n',nStim,p.stim.tFile);
                filename       = files(nStim,:);
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
    end
    function [t]=StopEyelinkRecording
        Eyelink('StopRecording');
        t = GetSecs;
        %this is the end of the trial scope.
        WaitSecs(0.01);
        Eyelink('Message', 'TRIAL_RESULT 0');
        %
        WaitSecs(0.01);
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('Command', 'clear_screen %d', 0);
        Screen('Textsize', p.ptb.w,p.text.fontsize);
        Log(t,8,NaN);
    end

    function [t]=StartEyelinkRecording(nTrial,nStim,phase,pain,fix)
        t = [];
        nStim = double(nStim);
        Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, FILE: %04d, pain: %04d, FIXX: %04d, FIXY %04d', nTrial, phase, nStim, double(pain),fix(1),fix(2));
        Eyelink('Message', 'FX Onset at %d %d',fix(1),fix(2));
        % an integration message so that an image can be loaded as
        % overlay background when performing Data Viewer analysis.
        WaitSecs(0.01);
        %return
        if nStim~=0
            Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p.stim.files(nStim,:), p.ptb.midpoint(1), p.ptb.midpoint(2));
        end
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('Command', 'record_status_message "Stim: %02d, Phase: %d"', nStim, phase);
        %
        %Put the tracker offline and draw the stimuli.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        %draw the image on the screen but also the two crosses
        if (nStim <= 16 && nStim>0)
            %Eyelink('ImageTransfer',p.stim.files24(nStim,:),p.ptb.imrect(1),p.ptb.imrect(2),p.stim.width,p.stim.height,p.ptb.imrect(1),p.ptb.imrect(2),0);
        end
        Eyelink('Command', 'draw_cross %d %d 15',fix(1),fix(2));
        Eyelink('Command', 'draw_cross %d %d 15',fix(1),fix(2)+diff(p.ptb.cross_shift));        
        
        %
        %drift correction
        %EyelinkDoDriftCorrection(el,crosspositionx,crosspositiony,0,0);
        %start recording following mode transition and a short pause.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('StartRecording');
        t = GetSecs;
        Log(t,2,NaN);
    end
    function [shuffled idx] = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [~, idx]        = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end
    function Buzz
        outp(p.com.lpt.thermode, 2 ); %D1 on LPT1
        WaitSecs(p.duration.pain);
        outp(p.com.lpt.thermode, 0);
%         WaitSecs(p.duration.intershockpulse);
    end
    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end
    function InitEyeLink
        %
        if EyelinkInit(0)%use 0 to init normaly
            fprintf('=================\nEyelink initialized correctly...\n')
        else
            fprintf('=================\nThere is problem in Eyelink initialization\n')
            keyboard;
        end
        %
        WaitSecs(0.5);
        [~, vs] = Eyelink('GetTrackerVersion');
        fprintf('=================\nRunning experiment on a ''%s'' tracker.\n', vs );
        
        %load 24bits pictures for eyelink...
        dummy = dir([p.path.stim24 '*.bmp']);
        p.stim.files24    = [repmat([fileparts(p.path.stim24) filesep],length(dummy),1) vertcat(dummy(:).name)];
        %
        el                          = EyelinkInitDefaults(p.ptb.w);
        %update the defaults of the eyelink tracker
        el.backgroundcolour         = p.stim.bg;
        el.msgfontcolour            = WhiteIndex(el.window);
        el.imgtitlecolour           = WhiteIndex(el.window);
        el.targetbeep               = 0;
        el.calibrationtargetcolour  = WhiteIndex(el.window);
        el.calibrationtargetsize    = 1.5;
        el.calibrationtargetwidth   = 0.5;
        el.displayCalResults        = 1;
        el.eyeimgsize               = 50;
        el.waitformodereadytime     = 25;%ms
        el.msgfont                  = 'Times New Roman';
        el.cal_target_beep          =  [0 0 0];%[1250 0.6 0.05];
        %shut all sounds off
        el.drift_correction_target_beep = [0 0 0];
        el.calibration_failed_beep      = [0 0 0];
        el.calibration_success_beep     = [0 0 0];
        el.drift_correction_failed_beep = [0 0 0];
        el.drift_correction_success_beep= [0 0 0];
        EyelinkUpdateDefaults(el);
        PsychEyelinkDispatchCallback(el);
        
        % open file.
        res = Eyelink('Openfile', p.path.edf);
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearAmy Experiment (Selim Onat)''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
        Eyelink('command','auto_calibration_messages = YES');
        Eyelink('command', 'calibration_type = HV13');
        Eyelink('command', 'select_parser_configuration = 1');
        %what do we want to record
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'use_ellipse_fitter = no');
        % set sample rate in camera setup screen
        Eyelink('command', 'sample_rate = %d',1000);
    end
    function StopEyelink(filename)
        try
            fprintf('Trying to stop the Eyelink system with StopEyelink\n');
            Eyelink('StopRecording');
            Log(t,8,NaN);
            WaitSecs(0.5);
            Eyelink('Closefile');
            display('receiving the EDF file...');
            Eyelink('ReceiveFile',filename,p.path.path_edf,1);
            display('...finished!')
            % Shutdown Eyelink:
            Eyelink('Shutdown');
        catch
            display('StopEyeLink routine didn''t really run well');
        end
    end
    function cleanup
        % Close window:
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'triostim1')
            %            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        commandwindow;
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
    end
    function CalibrateEL
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p.var.ExpPhase  = 0;
        ShowInstruction(0,1);
        EyelinkDoTrackerSetup(el);
        %Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s',messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')
    end
    function Log(ptb_time, event_type, event_info)
        %Phases:
        %Instruction          :     0
        %Test                 :     1
        %Rating               :     5
        %Calibration          :     0
        %
        %event types are as follows:
        %
        %Pulse Detection      :     0    info: NaN;
        %Tracker Onset        :     1
        %Cross Onset          :     2    info: position
        %Stimulus Onset       :     3    info: dist_id
        %Cross Movement       :     4    info: NaN;
        %pain Delivery         :     5    info: NaN;
        %Stimulus Offset      :     6    info: NaN;
        %Key Presses          :     7    info: NaN;
        %Tracker Offset       :     8    info: NaN;
        %
        %Text on the screen   :     -1    info: Which Text?
        %RatingScreen Onset   :     -2    info: NaN;
        for iii = 1:length(ptb_time)
            p.var.event_count                = p.var.event_count + 1;
            p.out.log(p.var.event_count,:)   = [ptb_time(iii) event_type event_info(iii) p.var.ExpPhase];
        end
        %         plot(p.out.log(1:p.var.event_count,1) - p.out.log(1,1),p.out.log(1:p.var.event_count,2),'o','markersize',10);
        %         ylim([-2 8]);
        %         set(gca,'ytick',[-2:8],'yticklabel',{'Rating On','Text','Pulse','Tracker+','Cross+','Stim+','CrossMov','pain','Stim-','Key+','Tracker-'});
        %         grid on
        %         drawnow;
        
    end
    function [secs]=WaitPulse(keycode,n)
        %[secs]=WaitPulse(keycode,n)
        %
        %   This function waits for the Nth upcoming pulse. If N=1, it will wait for
        %   the very next pulse to arrive. 1 MEANS NEXT PULSE. So if you wish to wait
        %   for 6 full dummy scans, you should use N = 7 to be sure that at least 6
        %   full acquisitions are finished.
        %
        %   The function avoids KbCheck, KbWait functions, but relies on the OS
        %   level event queues, which are much less likely to skip short events. A
        %   nice discussion on the topic can be found here:
        %   http://ftp.tuebingen.mpg.de/pub/pub_dahl/stmdev10_D/Matlab6/Toolboxes/Psychtoolbox/PsychDocumentation/KbQueue.html
        
        %KbQueueFlush;KbQueueStop;KbQueueRelease;WaitSecs(1);
        fprintf('Will wait for %i dummy pulses...\n',n);
        if n ~= 0
            secs  = nan(1,n);
            pulse = 0;
            dummy = [];
            while pulse < n
                dummy         = KbTriggerWait(keycode,p.ptb.device);
                pulse         = pulse + 1;
                secs(pulse+1) = dummy;
                Log(dummy,0,NaN);
            end
        else
            secs = GetSecs;
        end
    end
    function [keycode, secs] = KbQueueDump;
        %[keycode, secs] = KbQueueDump
        %   Will dump all the events accumulated in the queue.
        
        keycode = [];
        secs    = [];
        pressed = [];
        %fprintf('there are %03d events\n',KbEventAvail(p.ptb.device));
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet(p.ptb.device);
            n          = n + 1;
            keycode(n) = evt.Keycode;
            pressed(n) = evt.Pressed;
            secs(n)    = evt.Time;
         %   fprintf('Event is: %d\n',keycode(n));
        end
        i           = pressed == 1;
        keycode(~i) = [];
        secs(~i)    = [];
        %fprintf('there are %03d events found...\n',length(keycode));
    end
    function [z] = mymod(x,y)
        z=mod(x,y);
        if ~z
            z=y;
        end
    end
end
