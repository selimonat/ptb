function [p]=exp_FearGen_ForAll(subject,Nseq,phase,csp,PainThreshold)
%[p]=exp_FearGen_ForAll(subject,phase,csp,PainThreshold)

%
%
%   This code is based on the exp_FearAmy.m, adapted to run the initial FearGen
%   experiment (Onat & Buechel, 2015).
%
%   When the experiment starts as experimenter you will have to pass through
%   few sanity checks (press (V)alidate to continue). Once these are
%   passed, some text will be shown to the participant. You can also pass
%   these stages by pressing V (normally the subject has to read them and
%   press confirm key). These instructions for participants are shown using
%   the ShowInstruction function, where you precise instructions by their
%   id number. All instructions are stored in the GetText function by these
%   ids. So if you would like to change instructions you will need to
%   modify that function.
%
%   The experiment starts with PHASE = 1. Here I set the shock intensity
%   while the participant is in the scanner. The shock threshold is
%   measured outside the scanner. This is here just to validate the shock
%   intensity that will be used during the experiment, it is obtained by
%   the PAINTHRESHOLD (given as input) times P.OUT.SHOCKFACTOR (defined
%   below). PAINTHRESHOLD is only painful half of the time by definition,
%   and we would like to give a shock which is more painful but still
%   bearable by the participant. That is, I ask the participant to confirm
%   the shock is PAINFUL and BEARABLE. If the shock is not bearable the
%   program will propose a lower amplitude and the same question will be
%   repeated until these two conditions are fulfilled. It is always good to
%   stay in oral communication with the participant though. The phase = 1 
%   continues with a short presentation of faces, where I evaluate whether
%   they 1/ follow the fixation cross as instructed and 2/ detect the
%   oddball target. If they fail in any of these, phase 1 is repeated. This
%   phase also helps people to familiarize with the faces if no other task
%   has yet been carried out before.
%
%   The phase 2 is baseline. All faces are shown, but non predicts the
%   shock. Instead shocks are delivered after a shock symbol. This phase
%   ends with ratings.
%
%   Phase 3 is conditioning. Only CS+ and CS- are shown and CS+ is shocked
%   at about 30% of the cases.
%
%   Phase 4 is similar to baseline, all faces are shown, but shock follows
%   the CS+ face to avoid extinction. Following this phase, there is the
%   detection task.
%
%   
%   The current experiment can fully work with the Eyelink
%   eye-tracker. This is however now disabled. If you intent to record
%   eye-movements turn the EyelinkWanted flag to 1.
%
%   The parallel communication currently relies on the cogent's OUTP
%   function. It is used to deliver shocks and to send event pulses to the
%   physio computer. If you intend to use a Windows systems you can install
%   cogent and outp function, then you would be able to directly use this
%   code. Or take the extra mile and code the outp equivalent in PTB (that
%   would be nice).
%
%   To do before you start:
%   Set the baselocation for the experiment in SetParams around line 420:
%   p.path.baselocation variable. this location will be used to save
%   the experiment-related data for the current subject.
%
%   
%   Example usage:
%   exp_FearGen_ForAll(12,3,4,1,8.43); runs the Conditioning paradigm (3) for
%   participant 12, using the stimulus sequence 4 where the CS+ face is
%   face number 1 for a participant who has a shock intensity of 8.43.
%
%
%   Selim Onat

debug   = 1;%debug mode => 1: transparent window enabling viewing the background.
EyelinkWanted = 0;%is Eyelink wanted?
%replace parallel port function with a dummy function
if ~IsWindows
    %OUTP.m is used to communicate with the parallel port, mainly to send
    %triggers to the physio-computer or Digitimer device (which is used to give
    %shocks). OUTP is a cogent function, so it only works with Windows. In
    %Unix the same functionality can also be obtained with PTB, but it is not
    %coded in this program yet. So to communicate via the parallel port, there
    %are two options: 1/install cogent + outp, or 2/ use equivalent of OUTP
    %in PTB. This presentation will now replace the OUTP.m function with
    %the following code, which simply does nothing but allows the program
    %run.
    
    %% outp = @(x,y) 1;
end
if nargin ~= 5
    fprintf('Wrong number of inputs\n');
    keyboard;
end

csn   = mod( csp + 8/2-1, 8)+1;%obtain CS- from the CS+ faces
commandwindow;%focus on the command window, so that output is not written on the editor
%clear everything
clear mex global functions;%clear all before we start.

if IsWindows%clear cogent if we are in Windows and rely on Cogent for outp.
    cgshut;
    global cogent;
end
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);
%
el        = [];%eye-tracker variable
p         = [];%parameter structure that contains all info about the experiment.
s         = [];
SetParams;%set parameters of the experiment
SetPTB;%set visualization parameters.
%
%init all the variables
t                         = [];
nTrial                    = 0;
%%
%Time Storage
TimeEndStim               = [];
TimeStartShock            = [];
TimeTrackerOff            = [];
TimeCrossOn               = [];
p.var.event_count         = 0;
%%
InitEyeLink;
WaitSecs(2);
KbQueueStop(p.ptb.device);
KbQueueRelease(p.ptb.device);
%save again the parameter file
save(p.path.path_param,'p');
if phase == 1
    %
    p.mrt.dummy_scan = 0;%for the training we don't want any pulses
    p.var.ExpPhase = phase;
    %UCS check
    ShowInstruction(4,1);
    ConfirmIntensity;
    %test
    ShowInstruction(1,1);
    ShowInstruction(2,1);
    PresentStimuli;
    
elseif phase > 1%baseline, conditioning and test phases
    %
    if EyelinkWanted
        CalibrateEL;    
        ShowInstruction(299,0,5);
    end
    %% Vormessung
    p.var.ExpPhase  = phase;%set this after the calibration;
    k = 0;
    while ~(k == p.keys.el_calib);
        pause(0.1);
        fprintf('Experimenter!! press V key when the vormessung is finished.\n');
        [~, k] = KbStrokeWait(p.ptb.device);
        k = find(k);
    end
    fprintf('Continuing...\n');
    %%
    for ninst = [3 301:306]
        ShowInstruction(ninst,1);
    end
    PresentStimuli;
    WaitSecs(2.5);
    if phase == 4
     AskStimRating;%make sure that scanner doesnt stop prematurely asa the stim offset
     if EyelinkWanted
        CalibrateEL;
        AskDetection;
     end
     AskDetectionSelectable;
    end
end

%get the eyelink file back to this computer
StopEyelink(p.path.edf);
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
cleanup;

    function AskDetectionSelectable
        %asks subjects to select the face that was associated with a shocks
        positions          = circshift(1:8,[1 Shuffle(1:8,1)]);%position of the marker
        p.var.ExpPhase = 4;
        ShowInstruction(8,1);
        %%
        increment([p.keys.increase p.keys.decrease]) = [1 -1];%key to increment mapping
        %%
        ok                 = 1;
        while ok
            DrawCircle;
            Screen('FrameOval', p.ptb.w, [1 1 0], p.stim.circle_rect(positions(1),:), 2);%draw the marker circle somewhere random initially.
            Screen('Flip',p.ptb.w);
            [~, keyCode, ~]  = KbStrokeWait(p.ptb.device);%observe key presses
            keyCode          = find(keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                if (keyCode == p.keys.increase) || (keyCode == p.keys.decrease)
                    positions  = circshift(positions,[0 increment(keyCode)]);
                elseif keyCode == p.keys.confirm
                    WaitSecs(0.1);
                    ok = 0;
                end
            end
        end
        %%
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect );
        Screen('Flip',p.ptb.w);
        ShowInstruction(14,0,10);
        p.out.selectedface = p.stim.circle_order(positions(1));
    end
    function DrawCircle
        for npos = 1:p.stim.tFace
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(p.stim.circle_file_id(npos)),[],p.stim.circle_rect(npos,:));
            %Screen('DrawText', p.ptb.w, sprintf('%i_%i_%i',p.stim.circle_order(npos),p.stim.circle_file_id(npos),npos),mean(p.stim.circle_rect(npos,[1 3])) ,mean(p.stim.circle_rect(npos,[2 4])));
        end
    end

    function [myrect]=angle2rect(A)
        factor          = 1.9;%factor resize the images
        [x y]           = pol2cart(A./180*pi,280);%randomly shift the circle
        left            = x+p.ptb.midpoint(1)-p.stim.width/2/factor;
        top             = y+p.ptb.midpoint(2)-p.stim.height/2/factor;
        right           = left+p.stim.width/factor;
        bottom          = top+p.stim.height/factor;
        myrect          = [left top right bottom];
    end

    function AskDetection
        %
        p.var.ExpPhase = 3;
        ShowInstruction(801,1);
        %% show a fixation cross
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(1)];%show the fixation cross at the lip position to ease the subsequent drift correction.
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
        
        Screen('DrawingFinished',p.ptb.w,0);
        Screen('Flip',p.ptb.w);
        StartEyelinkRecording(1,0,p.var.ExpPhase,0,0,0,fix,0);
        WaitSecs(1.5);
        %%
        DrawCircle;
        %Stimulus onset
        Screen('Flip',p.ptb.w);
        if EyelinkWanted
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        %%
        WaitSecs(30);
        Screen('Flip',p.ptb.w);
        if EyelinkWanted
            Eyelink('Message', 'Stim Offset');
            Eyelink('Message', 'BLANK_SCREEN');
        end
        StopEyelinkRecording;
    end

    function ConfirmIntensity
        %Compute the intensity we want to deliver to the subject.
        p.var.ShockIntensity = p.out.PainThreshold*p.out.ShockFactor;
        %
        ShowInstruction(9,1);
        %
        fprintf([repmat('=',1,50) '\n']);
        fprintf('TEST SHOCK:\n');
        fprintf('!!! ADJUST THE SHOCK INTENSITY ON THE DIGITIMER !!!\n');
        fprintf('    The intensity is now: %g mA\n',p.var.ShockIntensity);
        fprintf('    Experimenter: Press any key to deliver a shock.\n');
        fprintf([repmat('=',1,50) '\n']);
        %
        [secs, keyCode, deltaSecs] = KbStrokeWait(p.ptb.device);
        ShowInstruction(10,0,1+rand(1));%shock is coming message...
        t = GetSecs + p.duration.shock;
        while GetSecs < t;
            Buzz;
        end
        %
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestï¿½tige deine Einschï¿½tzung mit der mit der oberen Pfeiltaste.';
        rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
        response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nertrï¿½glich' 'ertrï¿½glich'},message,0);
        if response == 2
            fprintf('All is fine :)\n');
            fprintf('Subject confirmed the shock intensity inside the scanner...\n');
            fprintf('INTENSITY TO BE USED FOR THE MAIN EXPERIMENT: %g mA\n',p.var.ShockIntensity);
            p.out.ShockIntensity = p.var.ShockIntensity;
            return;
        elseif response == 1
            fprintf('Shit... :(, %g is too much for the subject\n',p.var.ShockIntensity);
            fprintf('We will try a little milder intensity.\n');
            p.out.ShockFactor = p.out.ShockFactor - 0.05;
            ConfirmIntensity;
        end
        
        
    end
    function PresentStimuli
        %Enter the presentation loop and wait for the first pulse to
        %arrive.
        %wait for the dummy scans
        [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%will log it
        KbQueueStop(p.ptb.device);
        WaitSecs(.05);
        KbQueueCreate(p.ptb.device);
        KbQueueStart(p.ptb.device);%this means that from now on we are going to log pulses.
        %If the scanner by mistake had been started prior to this point
        %those pulses would have been not logged.
        %log the pulse timings.
        mblock_jumps    = logical([1 diff(p.presentation.mblock)]);
        TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        for nTrial  = 1:p.presentation.tTrial;
            
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            fix_y        = p.presentation.cross_position(nTrial);
            ISI          = (p.presentation.isi(nTrial)+1)*2;
            ucs          = p.presentation.ucs(nTrial);
            oddball      = p.presentation.oddball(nTrial);
            prestimdur   = p.duration.prestim+rand(1)*.25;
            dist         = p.presentation.dist(nTrial);
            mblock_jump  = mblock_jumps(nTrial);
            block_id     = p.presentation.mblock(nTrial);
            %prestimdur   = p_presentation_prestim_dur(nTrial);
            %
            OnsetTime     = TimeEndStim + ISI-p.duration.stim - p.ptb.slack;
            fprintf('%03d of %03d, S: %d, ISI: %d, UCS: %d, ODD: %d, OnsetTime: %f secs, ',nTrial,p.presentation.tTrial,stim_id,ISI,ucs,oddball, OnsetTime);
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim] = Trial(nTrial,OnsetTime, prestimdur, stim_id , ucs  , fix_y,  oddball,dist,mblock_jump,block_id);
            %(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist )
            fprintf('OffsetTime: %f secs, Difference of %f secs\n',TimeEndStim,TimeEndStim-OnsetTime-p.duration.stim);
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
            if any((keycode == p.keys.confirm) & (secs > OnsetTime) & (secs <= TimeEndStim))
                p.out.response(nTrial) = 1;
                fprintf('Subject Pressed the Hit Key!!\n');
            end
        end
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
        if p.var.ExpPhase > 0
            WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%
            fprintf('OK!! Stop the Scanner\n');
        end
        %dump the final events
        [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
        %log everything but "pulse keys" as pulses, not as keypresses.
        pulses          = (keycode == p.keys.pulse);
        if any(~pulses);%log keys presses if only there is one
            Log(secs(~pulses),7,keycode(~pulses));
        end
        if any(pulses);%log pulses if only there is one
            Log(secs(pulses),0,keycode(pulses));
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        WaitSecs(10);
    end
    function [TimeEndStim]=Trial(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist,microblock_jump,mblock_id)
        %get all the times
        TimeCrossOnset     = TimeStimOnset  - prestimdur;
        TimeCrossJump      = TimeStimOnset  + p.duration.stim/2;
        TimeEndStim        = TimeStimOnset  + p.duration.stim- p.ptb.slack;
        TimeStartShock     = TimeStimOnset  + p.duration.onset2shock;
        TimeTrackerOff     = TimeStimOnset  + p.duration.keep_recording;
        
        %% Fixation Onset
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
        
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);
        Log(TimeCrossOn,1,fix_i);%cross onset.
        %turn the eye tracker on
        StartEyelinkRecording(nTrial,stim_id,p.var.ExpPhase,dist,oddball,ucs,fix,mblock_id);%I would be cautious here, the first trial is never recorded in the EDF file, reason yet unknown.
        %% Draw the stimulus to the buffer
        if ~stim_id==0
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        end
        %draw also the fixation cross
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
        Screen('DrawingFinished',p.ptb.w,0);
        %% STIMULUS ONSET
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
        %send eyelink and ced a marker asap
        if EyelinkWanted
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset );%this actually didn't really work nicely.
        %the first stim onset pulse is always missing. This could be due to
        %the fact that the state of the port was already 1 and thus CED
        %didn't realize this command.
        if oddball
            MarkCED( p.com.lpt.address, p.com.lpt.oddball );
        end
        if ucs
            MarkCED(p.com.lpt.address, p.com.lpt.ucs);
        end
        if microblock_jump
            MarkCED( p.com.lpt.address, p.com.lpt.mBlock );
            Log(TimeStimOnset,9,mblock_id)
        end
        Log(TimeStimOnset,3,dist);%log the stimulus onset
        
        %% CROSS JUMPS (same as before but with a different fix position)
        if ~stim_id==0
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        end
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(setdiff(1:2,fix_i))];%take the other position
        %draw also the fixation cross
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossJump  = Screen('Flip',p.ptb.w,TimeCrossJump,0);%asap and dont clear
        Log(TimeCrossJump,4,0);%log the stimulus onset
        %%
        if ucs == 1
            %%%%%%%%%%%%%%%%%%%%%%%
            %Deliver shock and stim off immediately
            TimeStartShock = WaitSecs('UntilTime',TimeStartShock);
            if EyelinkWanted
                Eyelink('Message', 'UCS Onset');
            end
            
            while GetSecs < TimeEndStim;
                Buzz;%this is anyway sent to CED.
            end
        end
        
        %% STIM OFF immediately
        TimeEndStim = Screen('Flip',p.ptb.w,TimeEndStim,0);
        %send eyelink and ced a marker
        Log(TimeEndStim,6,stim_id);%log the stimulus offset
        %
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        if EyelinkWanted
            Eyelink('Message', 'Stim Offset');
            Eyelink('Message', 'BLANK_SCREEN');
        end
        TimeTrackerOff    = StopEyelinkRecording;
        
        
        if oddball == 1
            fprintf('This was an oddball trial!');
        end
        if ucs == 1
            fprintf('This was a UCS trial!');
            Log(TimeStartShock,5,NaN);%UCS delivery...This is done here to not waste time there
        end
        
    end

    function SetParams
        
        %mrt business
        p.mrt.dummy_scan              = 0;%this will wait until the 6th image is acquired.
        p.mrt.LastScans               = 0;%number of scans after the offset of the last stimulus
        p.mrt.tr                      = 2;%in seconds.
        %will count the number of events to be logged
        p.var.event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);
        p.path.baselocation           = 'C:\Users\...\Documents\Experiments\FearGen';
        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0
            mkdir(p.path.baselocation);
        end
        
        p.path.experiment             = [p.path.baselocation  filesep];
        p.path.stim                   = [fileparts(which('exp_FearGen_ForAll.m')) filesep 'bin' filesep 'FearGen_Stimuli' filesep];
        p.path.stim24                 = [p.path.stim '24bit' filesep];%location of 24bit stimuli, useful only to send it to the eyelink system
        p.path.stim_cut               = [p.path.stim 'cut' filesep];%stimuli without borders, necessary for the facecircle
        %
        p.subID                       = sprintf('s%02d',subject);%subject id
        timestamp                     = datestr(now,30);%the time_stamp of the current experiment.
        p.path.subject                = [p.path.experiment  'tmp' filesep p.subID '_' timestamp filesep ];%subject folder, first we save it to the temp folder.
        p.path.finalsubject           = [p.path.experiment  p.subID '_' timestamp filesep ];%final location of the subject folder
        p.path.path_edf               = [p.path.subject  'eye' filesep];%location of the edf file in the eyelink computer
        p.path.edf                    = sprintf([p.subID 'p%02d.edf' ],phase);%EDF file in the stimulus computer
        p.path.path_param             = [p.path.subject 'stimulation' filesep 'data.mat'];%location of the paradigm file.
        %create folder hierarchy for this subject
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);%location for the SCR data
        mkdir([p.path.subject 'eye']);%location for the edf file and eye-movement related data.
        mkdir([p.path.subject 'stimulation']);%location of the stimulus presentation paradigm
        mkdir([p.path.subject 'midlevel']);%other data.
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.bmp']);%read in the stimlus        
        p.stim.tFile                  = size(p.stim.files,1);%number of different files (including the UCS symbol)
        p.stim.tFace                  = 8;%number of faces.
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
        %set the background gray according to the background of the stimuli
        for i = 1:p.stim.tFace;
            im                        = imread(p.stim.files(i,:));
            bg(i)                     = im(1,1,1);
        end
        %is all the captured bg values the same?
        if sum(diff(bg))==0;
            %if so take it as the bg color
            p.stim.bg                   = double([bg(1) bg(1) bg(1)]);
        else
            fprintf('background luminance was not successfully detected...\n')
            keyboard;
        end
        %bg of the rating screen.
        p.stim.bg_rating               = p.stim.bg;
        p.stim.white                   = [255 255 255];
        %% font size and background gray level
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;%30;
        p.text.fixsize                 = 60;
        %rating business, how many ticks
        p.rating.division              = 10;%number of divisions for the rating slider
        p.rating.repetition            = 2;%how many times a given face has to be repeated...
        %% get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        %% keys to be used during the experiment:
        %This part is highly specific for your system and recording setup,
        %please enter the correct key identifiers. You can get this information calling the
        %KbName function and replacing the code below for the key below.
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner
        KbName('UnifyKeyNames');
        p.keys.confirm                 = KbName('4$');%
        p.keys.increase                = KbName('1!');
        p.keys.decrease                = KbName('3#');
        p.keys.pulse                   = KbName('5%');
        p.keys.el_calib                = KbName('v');
        p.keys.el_valid                = KbName('c');
        p.keys.escape                  = KbName('esc');
        p.keys.enter                   = KbName('return');
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address = 888;%parallel port of the computer.
        %codes for different events that are sent for logging in the
        %physiological computer.
        p.com.lpt.digitimer = 12;%8
        p.com.lpt.mBlock    = 128;
        p.com.lpt.StimOnset = 64;
        p.com.lpt.oddball   = 32;
        p.com.lpt.ucs       = 16;
        
        %
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 1.5;%2;%s
        p.duration.shock               = 0.1;%s;x
        p.duration.shockpulse          = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse     = 0.01;%ms; and the time between each pulse
        p.duration.onset2shock         = p.duration.stim - p.duration.shock;
        p.duration.crossmoves          = p.duration.stim./2;
        p.duration.keep_recording      = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.prestim             = .85;
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence: Explanation of the fields:
        s = load([fileparts(which('exp_FearGen_ForAll.m')) filesep 'bin' filesep 'feargen_seq.mat']);
        s = s.s;
        %Explanation of the fields:
        %.cond_id        => Condition id, this is the face to be loaded. 1-8: face id, 9 => oddball, 10 => UCS.
        %.UCS            => 1 if it is UCS trial, otherwise 0
        %.oddball        => 1 if it is an oddball trial
        %.stim_id        => same as cond_id, except for UCS stimuli, where the stim_id is the CS+. This is basically the index of the file that is gonna be read.
        %.dist           => The angular distance to CS+ face, this is the most important field for analysis
        %.cross_position => the position of the cross to be shown, could start from mouth and jump to eyes or vice versa. The exact position is computed in SetPTB.
        %.mblcok         => irrelevant for this experiment.
        %this will deal all the presentation sequence related information
        p.presentation                 = s(Nseq,csp).phase(phase).presentation;
        p.presentation.tTrial          = length(p.presentation.cond_id);%Total Trials
        p.presentation.mblock          = ones(1,p.presentation.tTrial);%irrelevant for the FearGen experiment but keeping it.
        p.presentation.dist            = MinimumAngle((p.presentation.stim_id-1)*45,(csp-1)*45);%infer distances to CS+
        %distances are only defined for the face conditions, for example
        %UCS, oddball and null trials do not have that.
        p.presentation.dist(p.presentation.cond_id == 9)  = 1001;
        p.presentation.dist(p.presentation.cond_id == 10) = 1002;
        clear s;
        %% create the randomized design
        p.stim.cs_plus                 = csp;%index of cs stimulus, this is the one paired to shock
        p.stim.cs_neg                  = csn;
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        p.out.rating                  = [];%will contain explicite ratings of UCS likelihood
        p.out.log                     = zeros(1000000,4).*NaN;%Experimental LOG.
        p.out.response                = zeros(p.presentation.tTrial,1);%
        p.out.PainThreshold           = PainThreshold;%the pain threshold (i.e. pain intensity where p(painful) = .5 for the subject, it is an input argument, must be computed before the experiment.
        p.out.ShockFactor             = 2;%factor to multiply the PainThreshold with, will use this factor to propose the experimenter the final shock intensity to be used during the FearGen Experiment.
        %%
        p.var.current_bg              = p.stim.bg;%current background to be used.
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
    function AskStimRating
        
        
        p.var.ExpPhase   = 5;
        p.var.current_bg = p.stim.bg_rating;
        %% create the order of presentation and balance the position of fixation cross
        nseq           = 0;
        rating_seq     = [];
        pos1_seq       = [];
        idx            = [];
        face_order     = 1:p.stim.tFace;
        while nseq < p.rating.repetition
            nseq                    = nseq + 1;
            [dummy idx]             = Shuffle( face_order );
            rating_seq              = [rating_seq dummy];
            %this balances both directions
            pos1_seq                = [pos1_seq ones(1,p.stim.tFace)];%+1 to make [0 1] --> [1 2]
        end
        rating_seq = rating_seq(:);
        pos1_seq   = pos1_seq(:);
        %%
        message     = GetText(11);
        SliderTextL = GetText(13);
        SliderTextR = GetText(12);
        % set the background to different color
        Screen('FillRect', p.ptb.w , p.var.current_bg );
        Screen('Flip',p.ptb.w);
        WaitSecs(2);
        %
        ShowInstruction(7,1);
        rect             = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];%for the rating slider
        tRatend          = length(rating_seq);
        %save the rating sequence just for security
        p.out.rating_seq = rating_seq;
        p.out.pos1_seq   = pos1_seq;
        
        %run over all the pictures to be rated.
        for nRatend = 1:tRatend;
            %
            %the variable that are used by Trial function
            stim_id      = rating_seq(nRatend);
            fix_y        = pos1_seq(nRatend);
            %
            next_stim_id = [];%this is a trick, otherwise a fixation cross appears right before the rating :(
            next_pos1    = [];
            %
            %to send know the distance here, little dummy setup:
            dummy        = -135:45:180;
            dist         = dummy(stim_id);
            % show the picture
            %Trial(nTrial     ,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist,microblock_jump,mblock_id)
            Trial(1000+nRatend,GetSecs+1,p.duration.prestim,stim_id,0,fix_y,0,dist,0,0);
            % show the slider
            rate(nRatend,1)  = RatingSlider(rect, p.rating.division, Shuffle(1:p.rating.division,1), p.keys.increase, p.keys.decrease, p.keys.confirm, {SliderTextL{1} SliderTextR{1}},message,1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Verbose the rating of the subject
            fprintf('============\nRating Results %d (%d/%d):\n', stim_id, nRatend, tRatend);
            dummy = rating_seq(1:nRatend);%trials shown so far
            for iii = 1:p.stim.tFace
                r = round(mean(rate(dummy == iii)));
                if isnan(r)
                    r = 0;
                end
                if iii == p.stim.cs_plus
                    fprintf('Stimulus %02d: * %s \n',iii,repmat('+',1,1+r));
                else
                    fprintf('Stimulus %02d:   %s \n',iii,repmat('+',1,1+r));
                end
            end
        end
        %sort the stim_ids and then sort the same the rates and make a
        %matrix out of that to store
        [~, i]       = sort(rating_seq);
        rate         = reshape(rate(i),p.rating.repetition,p.stim.tFace)';
        p.out.rating = rate;
        save(p.path.path_param,'p');
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        %
        save(p.path.path_param,'p');
    end
    function [rating] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
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
        ok = 1;
        while ok == 1
            
            [secs, keyCode, ~] = KbStrokeWait(p.ptb.device);
            keyCode = find(keyCode);
            Log(secs,7,keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys                
                if (keyCode == up) || (keyCode == down)
                    next = position + increment(keyCode);
                    if next < (tSection+1) && next > 0
                        position = position + increment(keyCode);
                    end
                    DrawSkala;
                elseif keyCode == confirm
                    WaitSecs(0.1);
                    ok = 0;
                    Screen('FillRect',p.ptb.w,p.var.current_bg);
                    t=Screen('Flip',p.ptb.w);
                end
            end
        end
        
        function DrawSkala
            %rating               = tSection - position + 1;
            rating               = position ;
            increment([up down]) = [1 -1];%delta
            tick_x               = linspace(rect(1),rect(1)+rect(3),tSection+1);%tick positions
            tick_size            = rect(3)./tSection;
            ss                   = tick_size/5*0.9;%slider size.
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
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
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            t = Screen('Flip',p.ptb.w);
            Log(t,-2,NaN);
        end
    end
    function ShowInstruction(nInstruct,waitforkeypress,varargin)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, ==> subject presses a button to proceed
        %if waitforkeypress is 0, ==> text is shown for VARARGIN seconds.
        
        
        [text]= GetText(nInstruct);
        ShowText(text);
        if waitforkeypress %and blank the screen as soon as the key is pressed
            KbStrokeWait(p.ptb.device);
        else
            WaitSecs(varargin{1});
        end
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        t = Screen('Flip',p.ptb.w);
        
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
            
        elseif nInstruct == 1%first Instr. of the training phase.
            text = ['Wir werden nun als erstes einen Übungsdurchgang machen,\n' ...
                'damit Sie sich an Ihre Aufgabe gewöhnen können.\n' ...
                'In diesem Durchgang können Sie sich vollkommen sicher fï¿½hlen,\n' ...
                'es werden keine elektrischen Reize verabreicht.\n' ...
                'Eine wichtige grundsätzliche Regel ist, dass Sie das Fixationskreuz (das +)\n' ...
                'wenn es zu sehen ist, mit Ihren Augen fixieren. \n' ...
                '\n'...
                'Drücken Sie die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 2%second Instr. of the training phase.
            text = ['Ein paar Bemerkungen zu den Zielreizen: \n' ...
                'Zur Erinnerung: Zielreize sind die verschwommenen Gesichter.\n' ...
                'Sobald ein solcher Zielreiz erscheint, \n' ...
                'sollen Sie schnellstmöglich die obere Taste drücken, \n' ...
                'und zwar bevor der Zielreiz wieder verschwunden ist \n' ...
                '(Sie müssen also sehr schnell und aufmerksam sein).\n\n' ...
                'Drücken Sie die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 299%short instruction before localizer
            text = ['Die Kalibrierung war erfolgreich.\n'...
                'Es startet nun eine kurze Vormessung (~2 min), während der Sie nichts tun müssen.\n\n'...
                ];
        elseif nInstruct == 3%third Instr. of the training phase.
            text = ['Wir sind jetzt kurz vor Beginn des Experiments.\n'...
                'Wir möchten Sie nun noch einmal an die wichtigsten Punkte erinnern.\n\n'...
                'Drücken Sie jeweils die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 301%third Instr. of the training phase.
            text = ['1/ Folgen Sie immer streng den Fixationskreuzen.\n'...
                ];
        elseif nInstruct == 302%third Instr. of the training phase.
            text = ['2/ Drücken Sie die Taste, sobald Sie den Zielreiz entdecken.\n'...
                ];
        elseif nInstruct == 303%third Instr. of the training phase.
            text = ['3/ Bewegen Sie sich nicht.\n'...
                ];
        elseif nInstruct == 304%third Instr. of the training phase.
            text = ['4/ Lassen Sie sich vom Scannergeschehen nicht stören.\n'...
                ];
        elseif nInstruct == 305%third Instr. of the training phase.
            text = ['5/ Nur eines der Gesichter wird mit elektrischen Reizen gepaart.\n'...
                ];
        elseif nInstruct == 306%third Instr. of the training phase.
            text = ['Drücken Sie jetzt die obere Taste, das Experiment startet dann in wenigen Sekunden.\n' ...
                ];
            
            
        elseif nInstruct == 4%third Instr. of the training phase.
            text = ['Vor dem Experiment legen wir nun \n' ...
                'die Schockintensität für den Rest des Experiments fest. \n' ...
                'Drücken Sie die obere Taste um fortzufahren.\n' ...
                ];
            
        elseif nInstruct == 7;%rating
            text = ['In dieser Phase hätten wir gerne, dass Sie die Gesichter\n'...
                'im Hinblick auf folgende Frage bewerten:\n'...
                '"Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?"\n'...
                'Bewegen Sie den Zeiger mit der rechten und linken Taste\n'...
                'und bestätigen Sie Ihre Einschätzung mit der oberen Taste.\n'...
                ];
        elseif nInstruct == 8;%AskDetectionSelectable
            text = ['Sie sehen nun noch einmal eine Übersicht der verschiedenen Gesichter.\n'...
                'Bitte geben Sie an, welches der Gesichter Ihrer Meinung nach\n mit dem Schock gepaart wurde.\n\n'...
                'Nutzen Sie die linke und rechte Taste, um die Markierung\n zum richtigen Gesicht zu navigieren,\n'...
                'und drücken Sie die obere Taste zum Bestätigen.\n\n'...
                'Bitte zum Starten die obere Taste drücken.\n'...
                ];
        elseif nInstruct == 801;%AskDetectionSelectable
            text = ['Sie sehen nun eine Übersicht der verschiedenen Gesichter.\n'...
                'Bitte schauen Sie sich die Gesichter aufmerksam an.\n'...
                'Bitte drücken Sie zum Start die obere Taste und\n' ...
                'fixieren Sie das anschließend erscheinende Fixationskreuz.\n'...
                ];
            
        elseif nInstruct == 9%
            %=================================================================================================================%
            text = ['Bitte geben Sie an, ob die Reizstärke des folgenden Schocks\n für Sie erträglich ist.\n'...
                '\n'...
                'Drücken Sie bitte die obere Taste um den Reiz zu bekommen.\n'...
                ];
            
        elseif nInstruct == 10%just before the shock
            text = ['Reiz kommt...\n'];
        elseif nInstruct == 11%this is the rating question
            text = ['Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?\n' ...
                'Bewegen Sie den "Zeiger" mit der rechten und linken Taste\n' ...
                'und bestätigen Sie Ihre Einschätzung mit der mit der oberen Taste'...
                ];
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
            text = {'Sehr\nwahrscheinlich'};
        elseif nInstruct == 13
            text = {'Überhaupt\nnicht\nwahrscheinlich'};
        elseif nInstruct == 14
            text = ['Danke. Den aktiven Teil des Experiment haben Sie nun geschafft.\n'...
                'Es folgt nun noch eine strukturelle Messung, die ca. 7 Minuten dauert.\n'...
                'Sie können dabei ruhig die Augen schließen und sich entspannen.\n'];
        else
            text = {''};
        end
    end
    function SetPTB        
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %%Find the number of the screen to be opened
        screens                     =  Screen('Screens');
        p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %set the resolution correctly
        res = Screen('resolution',p.ptb.screenNumber);
        HideCursor(p.ptb.screenNumber);%make sure that the mouse is not shown at the participant's monitor
        %spit out the resolution,
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        %Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        
        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.ptb.midpoint(1)-p.stim.width/2+p.stim.width p.ptb.midpoint(2)-p.stim.height/2+p.stim.height];
        p.ptb.cross_shift           = [180 -120]./2.5;%incremental upper and lower cross positions
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
        if IsWindows
            LoadPsychHID;
        end
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
        if IsWindows
            config_io;
            outp(p.com.lpt.address,0);
            if( cogent.io.status ~= 0 )
                error('inp/outp installation failed');
            end
        end
        
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Make final reminders to the experimenter to avoid false starts,
        %which are annoying. Here I specifically send test pulses to the
        %physio computer and check if everything OK.        
        k = 0;
        while ~(k == p.keys.el_calib);%press V to continue
            pause(0.1);
            outp(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('1/ Red cable has to be connected to the Cogent BOX\n');
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('2/ D2 Connection not to forget on the LPT panel\n');
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('3/ Switch the SCR cable\n');
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('4/ Button box has to be on\n');
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('5/ Did the trigger test work?\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\n\nPress V(alidate) to continue experiment or C to continue sending test pulses...\n')
            [~, k] = KbStrokeWait(p.ptb.device);
            k = find(k);
        end
        fprintf('Continuing...\n');
        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the pictures to the video memory.
        p.ptb.stim_sprites     = CreateStimSprites(p.stim.files);%        
        %% take care of the circle presentation
        %order of faces on the circle that will be shown at the end.
        if phase == 4
            circle_order = Shuffle(unique(p.presentation.dist(p.presentation.dist < 500)));%
            circle_order(end+1)=circle_order(1);
            while any(abs(diff(circle_order)) < 50);%check that neighbors will not be neighbors in the next order.
                circle_order        = Shuffle(unique(p.presentation.dist(p.presentation.dist < 500)));
                circle_order(end+1) = circle_order(1);%to be successful the check has to consider the circularity.
            end
            p.stim.circle_order   = circle_order(1:end-1);%conditions in distances from CSP, 0 = CS+, randomized
            p.stim.circle_angles  = sort(p.stim.circle_order);%this is just angles with steps of 45
            %transform the angles to rects
            for nc = 1:p.stim.tFace
                p.stim.circle_rect(nc,:)   = angle2rect(p.stim.circle_angles(nc));
                p.stim.circle_file_id(nc)  = unique(p.presentation.stim_id(p.presentation.dist == p.stim.circle_order(nc)));%the file that corresponds to different conditions
            end
            %one to one mappings:
            %now we have: circle_order ==> file_id
            %circle_angles ==> circle_rect
        end
        
        %%
        function [out]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:size(files,1)
                filename       = files(nStim,:);
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
    end
    function [t]=StopEyelinkRecording
        if EyelinkWanted
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
        else 
            t = GetSecs;
        end
    end

    function [t]=StartEyelinkRecording(nTrial,nStim,phase,dist,oddball,ucs,fix,block_id)
        if EyelinkWanted
            t = [];
            if isnan(dist)
                dist=3000;
            end
            nStim = double(nStim);
            Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, FILE: %04d, DELTACSP: %04d, ODDBALL: %04d, UCS: %04d, FIXX: %04d, FIXY %04d, MBLOCK %04d', nTrial, phase, nStim, dist, double(oddball), double(ucs),fix(1),fix(2),block_id);
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
                Eyelink('ImageTransfer',p.stim.files24(nStim,:),p.ptb.imrect(1),p.ptb.imrect(2),p.stim.width,p.stim.height,p.ptb.imrect(1),p.ptb.imrect(2),0);
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
        else
            t = GetSecs;
        end
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
        outp(p.com.lpt.address, p.com.lpt.digitimer );
        WaitSecs(p.duration.shockpulse);
        outp(p.com.lpt.address, 0);
        WaitSecs(p.duration.intershockpulse);
    end
    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end
    function InitEyeLink
        if EyelinkWanted
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
    end
    function StopEyelink(filename)
        if EyelinkWanted
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
        if EyelinkWanted
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
        %UCS Delivery         :     5    info: NaN;
        %Stimulus Offset      :     6    info: NaN;
        %Key Presses          :     7    info: NaN;
        %Tracker Offset       :     8    info: NaN;
        %MicroBlock			  :     9    info:rank
        %
        %Text on the screen   :     -1    info: Which Text?
        %RatingScreen Onset   :     -2    info: NaN;
        for iii = 1:length(ptb_time)
            p.var.event_count                = p.var.event_count + 1;
            p.out.log(p.var.event_count,:)   = [ptb_time(iii) event_type event_info(iii) p.var.ExpPhase];
        end
        %                 plot(p.out.log(1:p.var.event_count,1) - p.out.log(1,1),p.out.log(1:p.var.event_count,2),'o','markersize',10);
        %                 ylim([-2 8]);
        %                 set(gca,'ytick',[-2:8],'yticklabel',{'Rating On','Text','Pulse','Tracker+','Cross+','Stim+','CrossMov','UCS','Stim-','Key+','Tracker-'});
        %                 grid on
        %                 drawnow;
        
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
    function [a]=MinimumAngle(y,x);
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
