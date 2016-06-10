function [p] = remi3_fmri_all(subject,run,group)

if nargin == 0
    subject = 96; run = 1; group = 1;
end

if group == 1
    name = 'NaCl';
elseif group == 2
    name = 'Remi50';
elseif goup == 3
    name = 'Remi100';
end
fprintf('Sub%02d\nRun%d\nGroup: %s\n',subject,run,name);



%%%%%%%%%%%%%%%%%%%%%%%%%%% Put in your experiment choices here
debug       = 1;                                                           % Use this function to have a transparent screen
p_mri_on    = 0;                                                           % If on, waits for pulses and useses BrainVision Recorder marking BEFORE it marks CED. Otherwise, it only uses CED marking and sets BVR to 0
p_slave_on  = 0;                                                           % If on, waits for pulse from master and starts presentation at the same time.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 Initialize Experiment Environment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ListenChar(2);                                                             % Disable pressed keys to printed out
commandwindow;
%clear everything without using 'clear all'
clear mex global functions

%%%%%%%%%%%%%%%%%%%%%%%%%%% Load the GETSECS mex files so call them at
%%%%%%%%%%%%%%%%%%%%%%%%%%% least oncec
GetSecs;
WaitSecs(0.001);

SetParameters;

if strcmp(p.hostname,'triostim1')
    debug = 0;
end

SetPTB;


%%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize all variables
nTrial                          = 0;
stimName                        = [];
itiDuration                     = [];
CueDuration                     = [];
TimeCrossOn                     = [];
TimeCueOn                       = [];
TimeHeatOn                      = [];
TimeStarOn                      = [];
TimeBlankOn                     = [];
TimeBreathOn                    = [];
p_stim_white                    = p.stim.white;
p_stim_red                      = p.stim.red;
p_stim_backgr                   = p.stim.backgr;
p_stim_sizeCross                = p.stim.sizeCross;
p_stim_widthCross               = p.stim.widthCross;
p_monitor_nx                    = p.monitor.Xaxis; % pixel x-axis
p_monitor_ny                    = p.monitor.Yaxis; % pixel y-axis
p_com_lpt_CEDaddress            = p.com.lpt.CEDaddress;
p_com_lpt_CEDduration           = p.com.lpt.CEDduration;
p_com_lpt_scannerPulseOnset     = p.com.lpt.scannerPulseOnset;
p_com_lpt_ITIOnset              = p.com.lpt.ITIOnset;
% p_com_lpt_CueOnset              = p.com.lpt.CueOnset;
p_com_lpt_HeatOnset             = p.com.lpt.HeatOnset;
p_com_lpt_VASOnset              = p.com.lpt.VASOnset;
p_presentation_itiDuration      = p.presentation.itiDuration;
p_presentation_CueDuration      = p.presentation.CueDuration;
p_presentation_stimDuration     = p.presentation.stimDuration;
p_presentation_blankDuration    = p.presentation.blankDuration;
p_presentation_stimSequence     = p.presentation.stimSequence;
p_presentation_TrialList        = p.presentation.trialList;
p_presentation_scaleDuration    = p.presentation.scaleDuration;
p_keys_trigger                  = p.keys.trigger;
p_keys_nextStep                 = p.keys.nextStep;
p_mri_tr                        = p.mri.tr;
p_ptb_w                         = p.ptb.w;
p_ptb_midpoint                  = p.ptb.midpoint;
p_ptb_midpoint_y                = p.ptb.midpoint(2);
p_ptb_rect                      = p.ptb.rect;
p_ptb_startY                    = p.ptb.startY;
p_text_linespace                = p.text.linespace;
p_ptb_lineheight                = p.ptb.lineheight;

% save again the parameter file
save(p.path.save ,'p');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                  Run Experiment
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

putLog(GetSecs, 'Experiment Start');
fprintf(['=================\n=================\nStart thermode protocol ' num2str(p_presentation_stimSequence) '!!!!\n']);

% Show Instructions;
ShowInstruction;

% Wait for Dummy Scans
firstScannerPulseTime = WaitPulse(p.keys.trigger,p.mri.dummyScan);
commandwindow;
p.log.mriExpStartTime = firstScannerPulseTime(end);
putLog(p.log.mriExpStartTime, 'FirstMRPulse_ExpStart');

% Actual stimulus presentation
runExperiment;

% Show SessionEnd
ShowEndSessionText;

cleanup;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%               End of Experiment
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set all parameters relevant for the whole experiment and the specific subject
    function SetParameters
        p.mri.on                       = p_mri_on;
        p.mri.dummyScan                = 5;
        p.mri.tr                       = 2.65;
        p.slave                        = p_slave_on;
        p.subinfo.subID                = subject;
        p.subinfo.group                = group; % nacl 1 remi50 2 remi100 3
        p.subinfo.groupname            = name;  % nacl 1 remi50 2 remi100 3
        p.subinfo.run                  = run;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% create log structure
        p.log.mriExpStartTime          = 0;                                % Initialize as zero
        p.log.events                   = {{},{},{},{}}; % event count, real time, experiment duration, event string
        p.log.ratings1                 = []; % event count, real time, experiment duration, event string
        p.log.ratings2                 = [];
        p.log.eventCount               = 0;
        p.log.rating1EventCount        = 0;
        p.log.rating2EventCount        = 0;
        p.log.onratingEventCount       = 0;
        p.log.moodEventCount           = 0;
        p.log.scaleDefaultVAS1         = [];
        p.log.scaleDefaultVAS2         = [];
        p.log.PainOnset                = [];
        p.log.PainOnsetScan            = [];
        p.log.MoodRating               = [];
        p.log.Rating1                  = [];
        p.log.Rating2                  = [];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% relative paths to stim and experiments
        [~, hostname] = system('hostname');
        p.hostname                     = deblank(hostname);
        p.hostaddress = java.net.InetAddress.getLocalHost ;
        p.hostIPaddress = char( p.hostaddress.getHostAddress);
        if strcmp(p.hostname,'triostim1')
            p.path.experiment          = 'C:\USER\tinnermann\remi3\Paradigma_MRT\';
            p.monitor.Xaxis                = 1024; % stim PC resolution
            p.monitor.Yaxis                = 768; % stim PC resolution
        else
            p.path.experiment        = 'C:\Users\tinnermann\Documents\remi3\Paradigma_MRT\';
            p.monitor.Xaxis                = 1920; % stim PC resolution
            p.monitor.Yaxis                = 1200; % stim PC resolution
        end
        %
        p.subID                        = sprintf('sub%02d',subject);
        p.timestamp                    = datestr(now,30);
        
        p.path.subject                 = [p.path.experiment '/logs/' p.subID '/'];
        
        p.path.save                    = [p.path.subject  p.subID '_run' num2str(p.subinfo.run) '_' p.timestamp ];
        %create folder hierarchy
        mkdir(p.path.subject);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% font size, background gray level, monitor settings
        p.text.fontname                = 'Arial';
        p.text.fontsize                = 20; %30; %18;
        p.text.linespace               = 10;
        p.stim.white                   = [255 255 255];
        p.stim.red                     = [255 0 0];
        p.stim.backgr                  = [70 70 70];
        p.stim.widthCross              = 3;
        p.stim.sizeCross               = 20;
        
        if strcmp(p.hostname,'triostim1') % curdes button box single diamond (HID NAR 12345)
            p.keys.confirm             = KbName('3#'); % green button
            p.keys.right               = KbName('4$'); % red button
            p.keys.left                = KbName('2@'); % yellow button
            p.keys.esc                 = KbName('esc');
            p.keys.nextStep            = KbName('space');
            p.keys.trigger             = KbName('5%');
        else
            %All settings for laptop computer.
            KbName('UnifyKeyNames');
            p.keys.confirm             = KbName('Return');
            p.keys.right               = KbName('RightArrow');
            p.keys.left                = KbName('LeftArrow');
            p.keys.esc                 = KbName('Escape');
            p.keys.nextStep            = KbName('space');
            p.keys.trigger             = KbName('5');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Parallel port settings
        % Codes for different events
        % device Thermode: 4
        % Spike-channel 4 : 32
        % Spike-channel 5 : 64
        % Spike-channel 6 : 128
        
        if strcmp(p.hostname,'triostim1')
            p.com.lpt.scannerPulseOnset    = 224; % start of each run -> 32+64+128 (all 3 channels)
            p.com.lpt.HeatOnset            = 36;  % Cue (spike channel 4)
            p.com.lpt.VASOnset             = 64;  % Heat trigger for thermode plus spike channel 5
            p.com.lpt.ITIOnset             = 128;  % VAS/Mood scale on (Spike-channel 6)
            %             p.com.lpt.ITIOnset             = 192;  % white fixation cross  on channel 5 and 6
        else
            p.com.lpt.scannerPulseOnset    = 0; % start of each run -> 32+64+128 (all 3 channels)
            p.com.lpt.CueOnset             = 0;  % Cue (spike channel 4)
            p.com.lpt.HeatOnset            = 255;  % Heat trigger for thermode
            p.com.lpt.VASOnset             = 0;  % VAS/Mood scale on (Spike-channel 6)
            p.com.lpt.ITIOnset             = 0;  % white fixation cross
        end
        p.com.lpt.CEDaddress           = 888;
        p.com.lpt.CEDduration          = 0.005;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Stimulus sequence and startle timings
        p.presentation.stimDuration     = 17;
        p.presentation.blankDuration    = 0.5;
        iti                             = [19 20 21 22 22 23 24 25];
        trialLists                      = load([p.path.experiment 'trial_seq.mat']);
        trialLists                      = trialLists.trial_seq;
        sequence                        = load([p.path.experiment 'rand_seq.mat']);
        sequence                        = sequence.rand_seq;
        p.presentation.stimSequence     = sequence(run,subject);
        p.presentation.trialList        = trialLists(:,p.presentation.stimSequence);
        p.presentation.tTrial           = length(p.presentation.trialList);  %number of trials
        p.presentation.itiDuration      = iti(randperm(length(iti)));
        p.presentation.CueDuration      = 4;
        p.presentation.scaleDuration    = 8;
        p.presentation.scaleBackColor   = p.stim.backgr;
        p.presentation.BreathRem        = 2;
        p.presentation.starTime         = 0.6;
        p.presentation.lastITI          = 4;
        
        clearvars trialLists
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Save the parameters for this subject
        save(p.path.save ,'p');
    end

%% Set Up the PTB with parameters and initialize drivers
    function SetPTB
        screens                     =  Screen('Screens');                  % Find the number of the screen to be opened
        p.ptb.screenNumber          =  max(screens);                       % The maximum is the second monitor
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;                                 % Make everything transparent for debugging purposes.
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Default parameters
        Screen('Preference', 'SkipSyncTests', 0);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        %Screen('Preference', 'TextAntiAliasing',2);                       % Enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);                       % 0 disable all visual alerts
        %Screen('Preference', 'SkipSyncTests', 0);
        %Screen('Preference', 'SuppressAllWarnings', 0);
        if debug == 0;
            HideCursor(p.ptb.screenNumber);                                   % Hide the cursor
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.stim.backgr);
        %         Screen('TextStyle', p.ptb.w, 1);                                 % Make Text Bold
        Screen('Flip',p.ptb.w);                                            % Make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        %         [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        p.ptb.rect                  = [0 0 p.monitor.Xaxis p.monitor.Yaxis];
        p.ptb.width                 = p.monitor.Xaxis;
        p.ptb.height                = p.monitor.Yaxis;
        p.ptb.midpoint              = [p.ptb.width./2 p.ptb.height./2];   % Find the mid position on the screen.
        
        p.ptb.startY                = p.monitor.Yaxis/4;
        p.ptb.lineheight = p.text.fontsize + p.text.linespace;
        
        p.ptb.whiteFix1 = [p.ptb.midpoint(1)-p.stim.sizeCross p.ptb.startY-p.stim.widthCross p.ptb.midpoint(1)+p.stim.sizeCross p.ptb.startY+p.stim.widthCross];
        p.ptb.whiteFix2 = [p.ptb.midpoint(1)-p.stim.widthCross p.ptb.startY-p.stim.sizeCross p.ptb.midpoint(1)+p.stim.widthCross p.ptb.startY+p.stim.sizeCross];
        %         p.ptb.imrect                = [ p_ptb_midpoint(1)-p.stim.width/2 p_ptb_midpoint(2)-p.stim.height/2 p.stim.width p.stim.height];
        
        p.ptb.priorityLevel=MaxPriority('GetSecs','KbCheck','KbWait');
        Priority(MaxPriority(p.ptb.w));
        p.ptb.device        = [];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Parallel port communication.
        config_io;
        outp(p.com.lpt.CEDaddress,0);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Functions collection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                fprintf('Waiting for dummy scan %d\n',pulse);
                putLog(dummy,num2str(pulse));
            end
        else
            secs = GetSecs;
        end
    end

%% Start the actual experiment
    function runExperiment
        for nTrial  = 1:p.presentation.tTrial;                             % Enter the presentation loop
            stimName        = p_presentation_TrialList(nTrial);
            itiDuration     = p_presentation_itiDuration(nTrial);
            CueDuration     = p_presentation_CueDuration;
            
            if nTrial == 1                                                 % Turn on the fixation cross for the first trial. These have to be done before the main for loop.
                Screen('FillRect', p_ptb_w, p_stim_white, p.ptb.whiteFix1);
                Screen('FillRect', p_ptb_w, p_stim_white, p.ptb.whiteFix2);
                TimeCrossOn = Screen('Flip',p_ptb_w);                      % gets timing of event for putLog
                putMark(p_com_lpt_ITIOnset);                               % Mark Fixation Cross Onset
                putLog(TimeCrossOn, 'FirstITIOnset');                      % Log the cross onset...
                fprintf('=================\n=================\nFirst ITI, waiting for 5 seconds\n=================\n=================\n');
                while GetSecs < TimeCrossOn + 5 end
            end
            
            fprintf('%d of %d,  Stim: %d, CueDuration: %d, itiDuration: %d \n',nTrial,p.presentation.tTrial, stimName(1), CueDuration, itiDuration);
            
            p.log.scaleDefaultVAS1(nTrial,1) = randi([30,71]);
            p.log.scaleDefaultVAS2(nTrial,1) = randi([30,71]);
            p.log.scaleDefaultMood(nTrial,1) = randi([2,6]);
            
            Trial(itiDuration);
            
        end
        
        fprintf('=================\n=================\nWait for last scanner pulse of experiment!...\n');
        
        mriEnd = KbTriggerWait(p_keys_trigger,p.ptb.device);
        putLog(mriEnd, 'mriTrigger');
        putLog(GetSecs, 'ExpEnd');
    end

%% Present affective Picture
    function Trial(itiDuration) %Trial(stimID,stimName,stimStrlOnset,itiDuration,itiStrlOnset,jitter)
        
        %cue
        if p_presentation_stimSequence == 2 && nTrial == 2 || p_presentation_stimSequence == 2 && nTrial == 7 ||...
                p_presentation_stimSequence == 4 && nTrial == 1 || p_presentation_stimSequence == 4 && nTrial == 6
            DrawFormattedText(p_ptb_w, 'Im nächsten Durchgang bewerten Sie bitte', 'center',p_ptb_startY-100, p_stim_white);
            DrawFormattedText(p_ptb_w, 'die Schmerzhaftigkeit WÄHREND des Hitzereizes!', 'center',p_ptb_startY-70, p_stim_white);
        end
        
        Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1);
        Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
        TimeCueOn = Screen('Flip',p_ptb_w);
        putLog(TimeCueOn, 'CueOnset');
        p.log.reactionTime(nTrial) = getRT(p_presentation_CueDuration,TimeCueOn);  % check reaction time during cue
        if nTrial > 1
            if isnan(p.log.reactionTime(end)) && isnan(p.log.reactionTime(end-1))
                warning(sprintf('\n***********\n***********\nNo RT for 2 Trials!\nPlease check participant!!!\n***********\n***********\n'));
            end
        end
        
        %Pain
        %online rating scale
        if p_presentation_stimSequence == 2 && nTrial == 2 || p_presentation_stimSequence == 2 && nTrial == 7 ||...
                p_presentation_stimSequence == 4 && nTrial == 1 || p_presentation_stimSequence == 4 && nTrial == 6
            TimeHeatOn = GetSecs;
            putMark(p_com_lpt_HeatOnset);
            fprintf('Heat on\n');
            p.log.PainOnset(nTrial) = TimeHeatOn - p.log.mriExpStartTime;
            p.log.PainOnsetScan(nTrial) = (TimeHeatOn - p.log.mriExpStartTime)/p_mri_tr;
            putLog(TimeHeatOn, 'HeatOnset');
            [p.onrating.conRating,p.onrating.conTime,p.onrating.response] = onlineScale(p_ptb_w,p_ptb_rect,...
                p_presentation_stimDuration,p_stim_backgr,p_ptb_startY,p.keys,p.presentation.starTime); %
            putOnRatingLog(nTrial);
            
        else % only showing cross during pain
            Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1); % no treatment condition
            Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
            TimeHeatOn = Screen('Flip',p_ptb_w);
            putMark(p_com_lpt_HeatOnset);
            putLog(TimeHeatOn, 'HeatOnset');
            p.log.PainOnset(nTrial) = TimeHeatOn - p.log.mriExpStartTime;
            p.log.PainOnsetScan(nTrial) = (TimeHeatOn - p.log.mriExpStartTime)/p_mri_tr;
            fprintf('Heat on\n');
            while GetSecs < TimeHeatOn + (p_presentation_stimDuration/2.5) end % = WaitSecs(p_presentation_stimDuration);
            %Show star for rating
            Screen('TextSize',p_ptb_w,p.text.fontsize+40);
            Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1); % no treatment condition
            Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
            Screen('DrawText', p_ptb_w,'*',p_ptb_midpoint(1)-12,p.ptb.startY-60,p_stim_white);
            TimeStarOn = Screen('Flip',p_ptb_w);
            putLog(TimeStarOn, 'StarOnset');
            fprintf('Star on\n');
            while GetSecs < TimeStarOn + p.presentation.starTime end
            Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1); % no treatment condition
            Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
            TimeHeatOn = Screen('Flip',p_ptb_w);
            
            while GetSecs < TimeStarOn + (p_presentation_stimDuration - (p_presentation_stimDuration/2.5)) end % = WaitSecs(p_presentation_stimDuration);
        end
        
        %blank screen
        TimeBlankOn = Screen('Flip',p_ptb_w);
        while GetSecs < TimeBlankOn + p_presentation_blankDuration end % = WaitSecs(p_presentation_blankDuration);
        putLog(TimeBlankOn, 'BlankOnset');
        
        %VAS T2
        putLog(GetSecs, 'VAS1Onset');
        putMark(p_com_lpt_VASOnset);
        fprintf('VAS_T2 on\n');
        
        [p.rating1.finalRating,p.rating1.reactionTime,p.rating1.response] = vasScaleT2(p_ptb_w,p_ptb_rect,...
            p_presentation_scaleDuration,p.log.scaleDefaultVAS1(nTrial,1),p_stim_backgr,p_ptb_startY,p.keys); %
        putRating1Log(nTrial);
        p.log.Rating1(nTrial) = p.rating1.finalRating;
        
        %blank screen
        TimeBlankOn = Screen('Flip',p_ptb_w);
        while GetSecs < TimeBlankOn + p_presentation_blankDuration end % = WaitSecs(p_presentation_blankDuration);
        putLog(TimeBlankOn, 'BlankOnset');
        
        %VAS T3
        putLog(GetSecs, 'VAS2Onset');
        putMark(p_com_lpt_VASOnset);
        fprintf('VAS_T3 on\n');
        
        [p.rating2.finalRating,p.rating2.reactionTime,p.rating2.response] = vasScaleT3(p_ptb_w,p_ptb_rect,...
            p_presentation_scaleDuration-2,p.log.scaleDefaultVAS2(nTrial,1),p_stim_backgr,p_ptb_startY,p.keys,p.rating1.finalRating); %
        putRating2Log(nTrial);
        p.log.Rating2(nTrial) = p.rating2.finalRating;
        
        %blank screen
        TimeBlankOn = Screen('Flip',p_ptb_w);
        while GetSecs < TimeBlankOn + p_presentation_blankDuration end % = WaitSecs(p_presentation_blankDuration);
        putLog(TimeBlankOn, 'BlankOnset');
        
        %Mood
        putLog(GetSecs, 'MoodOnset');
        fprintf('Mood on\n');
        
        [p.mood.finalRating,p.mood.reactionTime,p.mood.response] = moodScale(p_ptb_w,p_ptb_rect,...
            p_presentation_scaleDuration-4,p.log.scaleDefaultMood(nTrial,1),p_stim_backgr,p_ptb_startY,p.keys); %p.log.scaleDefaultVAS(nTrial,1)
        putMoodLog(nTrial);
        p.log.MoodRating(nTrial) = p.mood.finalRating;
        if nTrial > 1
            if p.log.MoodRating(end)+2 <= p.log.MoodRating(end-1)
                warning(sprintf('\n***********\n***********\nParticipant rated 2 points less!\nPlease check participant!!!\n***********\n***********\n'));
            end
        end
        
        %Breath
        Screen('TextSize',p_ptb_w,p.text.fontsize);
        p_monitor_ny = p.monitor.Yaxis/4;
        [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Bitte atmen Sie ruhig und gleichmäßig', 'center', p_monitor_ny, p_stim_white);
        [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'durch die Nase.', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
        
        fprintf('Breath Reminder\n');
        TimeBreathOn = Screen('Flip',p_ptb_w);
        putLog(TimeBreathOn, 'BreathOnset');
        while GetSecs < TimeBreathOn + p.presentation.BreathRem end
        
        %ITI
        p.presentation.durVAS(nTrial) = p.mood.reactionTime+p.rating1.reactionTime+p.rating2.reactionTime+(2*p_presentation_blankDuration);
        p.presentation.itiDurationReal(nTrial) = (itiDuration + p.presentation.lastITI) - p.presentation.durVAS(nTrial);
        
        %         if p.presentation.itiDurationReal(nTrial) > 0
        Screen('FillRect', p_ptb_w, p_stim_white, p.ptb.whiteFix1);
        Screen('FillRect', p_ptb_w, p_stim_white, p.ptb.whiteFix2);
        TimeCrossOn = Screen('Flip',p_ptb_w);
        putMark(p_com_lpt_ITIOnset);
        putLog(TimeCrossOn, 'ITIOnset');
        fprintf(['Remaining ITI duration: ' num2str(p.presentation.itiDurationReal(nTrial)) '\n']);
        while GetSecs < (TimeCrossOn + p.presentation.itiDurationReal(nTrial)) end
        %         else
        %               Screen('FillRect', p_ptb_w, p_stim_white, p.ptb.whiteFix1);
        %               Screen('FillRect', p_ptb_w, p_stim_white, p.ptb.whiteFix2);
        %               TimeCrossOn = Screen('Flip',p_ptb_w);
        %               putLog(TimeCrossOn, 'ITIOnset');
        %         putMark(p_com_lpt_ITIOnset);
        %         while GetSecs < TimeCrossOn + 5 end
        % %             fprintf('adding seconds to ITI to show breathing reminder\n');
        % %             p.presentation.itiDurationReal(nTrial) = p.presentation.itiDurationReal(nTrial) + abs(p.presentation.itiDurationReal(nTrial) - p.presentation.BreathRem);
        %         end
        %
        save(p.path.save ,'p');
    end

%% Instruction Text
    function ShowInstruction
        if run == 1
            p_monitor_ny = p.monitor.Yaxis/8;
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Gleich beginnt das Experiment.', 'center', p_monitor_ny, p_stim_white);
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Bleiben Sie die ganze Zeit so ruhig wie möglich liegen!', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Haben Sie noch Fragen?', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Sonst geht es jetz los!', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
        else
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Es geht gleich los...', 'center', p.ptb.startY, p_stim_white);
        end
        
        introTextTime = Screen('Flip',p_ptb_w);
        putLog(introTextTime,'IntroTextOn');
        WaitSecs(1);
        
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();      % Start waiting 1/2 TR before JitterOnset for next pulse (this avoids collecting Pulses before).
            if keyIsDown
                if find(keyCode) == p_keys_nextStep;
                    break;
                end
            end
        end
        
        StartWaitTime = Screen('Flip',p_ptb_w);
        putLog(StartWaitTime, 'WaitForExpStartOnset');
        
        fprintf('=================\n=================\nAsk if subject is alright\nThen tell MTA to start scanner!!!!!!!!...\n');
        fprintf('=================\n=================\nWill wait %d volumes for dummy...\n',p.mri.dummyScan);
    end

%% End session Text
    function ShowEndSessionText
        Screen('TextSize',p_ptb_w,p.text.fontsize);
        if run == 8
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Das Experiment ist beendet.', 'center', p.ptb.start, p_stim_white);
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Vielen Dank!', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
        else
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Ende des Durchgangs.', 'center', p.ptb.startY, p_stim_white);
            [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Es geht gleich weiter!', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
        end
        
        endTextTime = Screen('Flip',p_ptb_w);
        putLog(endTextTime,'EndTextOn');
        
        WaitSecs(1);
        
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();      % Start waiting 1/2 TR before JitterOnset for next pulse (this avoids collecting Pulses before).
            if keyIsDown
                if find(keyCode) == p_keys_nextStep;
                    break;
                end
            end
        end
    end

%% get reaction time
    function reactionTime = getRT(durCue,startTime)
        response = 0;
        numberOfSecondsRemaining = durCue;
        while numberOfSecondsRemaining  > 0
            
            if response == 0
                
                [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                if keyIsDown % only if a key was pressed we check which key it was
                    response = 0; % predefine variable for confirmation button 'space'
                    if keyCode(p.keys.confirm)
                        response = 1;
                        reactionTime = secs - startTime;
                        disp(['Reaction Time: ' num2str(reactionTime)]);
                        flip_confKey = GetSecs;
                        SecondsRemaining = durCue-(flip_confKey-startTime);
                        WaitSecs(SecondsRemaining);
                        break;
                    end
                end
            end
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durCue - numberOfSecondsElapsed;
        end
        
        if  response == 0
            warning(sprintf('\n***********\n***********\nNo Response!\nPlease check participant!!!\n***********\n***********\n'));
            reactionTime = NaN;
        end
        
    end
%% Set Marker for CED and BrainVision Recorder
    function putMark(port)
        % Send pulse to CED for SCR, thermode, digitimer
        %       [handle, errmsg] = IOPort('OpenSerialport',num2str(port));
        outp(p_com_lpt_CEDaddress,port);
        WaitSecs(p_com_lpt_CEDduration);
        outp(p_com_lpt_CEDaddress,0);
        %         IOPort('CloseAll');
    end

%% Log all events
    function putLog(ptb_time, event_info)
        p.log.eventCount                    = p.log.eventCount + 1;
        p.log.events(p.log.eventCount,1)    = {p.log.eventCount};
        p.log.events(p.log.eventCount,2)    = {ptb_time};
        p.log.events(p.log.eventCount,3)    = {ptb_time-p.log.mriExpStartTime};
        p.log.events(p.log.eventCount,4)    = {event_info};
    end
    function putOnRatingLog(currentTrial)
        p.log.onratingEventCount                       = p.log.onratingEventCount + 1;
        p.log.onratings.conTrial(p.log.onratingEventCount,1)   = {currentTrial};
        p.log.onratings.conRating(:,p.log.onratingEventCount)  = {p.onrating.conRating};
        p.log.onratings.conTime(:,p.log.onratingEventCount)    = {p.onrating.conTime};
        p.log.onratings.conRes(p.log.onratingEventCount,1)     = {p.onrating.response};
    end
    function putRating1Log(currentTrial)
        p.log.rating1EventCount                      = p.log.rating1EventCount + 1;
        p.log.ratings1(p.log.rating1EventCount,1)    = currentTrial;
        p.log.ratings1(p.log.rating1EventCount,2)    = p.rating1.finalRating;
        p.log.ratings1(p.log.rating1EventCount,3)    = p.rating1.response;
        p.log.ratings1(p.log.rating1EventCount,4)    = p.rating1.reactionTime;
    end

    function putRating2Log(currentTrial)
        p.log.rating2EventCount                      = p.log.rating2EventCount + 1;
        p.log.ratings2(p.log.rating2EventCount,1)    = currentTrial;
        p.log.ratings2(p.log.rating2EventCount,2)    = p.rating2.finalRating;
        p.log.ratings2(p.log.rating2EventCount,3)    = p.rating2.response;
        p.log.ratings2(p.log.rating2EventCount,4)    = p.rating2.reactionTime;
    end

    function putMoodLog(currentTrial)
        p.log.moodEventCount                    = p.log.moodEventCount + 1;
        p.log.mood(p.log.moodEventCount,1)    = currentTrial;
        p.log.mood(p.log.moodEventCount,2)    = p.mood.finalRating;
        p.log.mood(p.log.moodEventCount,3)    = p.mood.response;
        p.log.mood(p.log.moodEventCount,4)    = p.mood.reactionTime;
    end

    function [finalRating,reactionTime,response,VASon,VASoff] = moodScale(window,windowRect,durRating,defaultRating,backgroundColor,StartY,keys)
        
        %% key settings
        KbName('UnifyKeyNames');
        lessKey =  keys.left; % yellow button
        moreKey =  keys.right; % red button
        confirmKey =  keys.confirm;  % green button
        escapeKey = keys.esc;
        
        if isempty(window); error('Please provide window pointer for likertScale!'); end
        if isempty(windowRect); error('Please provide window rect for likertScale!'); end
        if isempty(durRating); error('Duration length of rating has to be specified!'); end
        
        %% Default values
        nRatingSteps = 7;
        scaleWidth = 700;
        textSize = 20;
        lineWidth = 6;
        scaleColor = [255 255 255];
        activeColor = [255 0 0];
        ticTextGap = 8;
        tickHeight = 20;
        ratingLabels = {'-3','-2','-1','0','1','2','3'};
        if isempty(defaultRating); defaultRating = round(nRatingSteps/2); end
        if isempty(backgroundColor); backgroundColor = 0; end
        
        
        %% Calculate rects
        activeAddon_width = 0.6;
        activeAddon_height = 20;
        [xCenter, yCenter] = RectCenter(windowRect);
        yCenter = StartY;
        axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        
        % for j = 1:nRatingSteps
        %     Label(j,:) = round([axesRect(1)+((j-1)*scaleWidth/(nRatingSteps-1)),yCenter-20,axesRect(1)+((j-1)*scaleWidth/(nRatingSteps-1))+6,yCenter+20]);
        % end
        ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
        activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];
        ticRects = [ticPositions;ones(1,nRatingSteps)*yCenter;ticPositions + lineWidth;ones(1,nRatingSteps)*yCenter+tickHeight];
        
        Screen('TextSize',window,textSize);
        Screen('TextColor',window,[255 255 255]);
        Screen('TextFont', window, 'Arial');
        currentRating = defaultRating;
        finalRating = currentRating;
        reactionTime = 0;
        response = 0;
        first_flip  = 1;
        startTime = GetSecs;
        numberOfSecondsRemaining = durRating;
        nrbuttonpresses = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
        % tic; % control if timing is as long as durRating
        while numberOfSecondsRemaining  > 0
            loopTime = GetSecs;
            Screen('FillRect',window,backgroundColor);
            Screen('FillRect',window,scaleColor,axesRect);
            
            Screen('FillRect',window,scaleColor,activeTicRects)
            for j = 1:nRatingSteps
                textRect = Screen('TextBounds',window,ratingLabels{j});
                Screen('DrawText',window,ratingLabels{j},round(ticRects(1,j)-textRect(3)/2)+2,ticRects(4,j) + ticTextGap,scaleColor);
            end
            Screen('FillRect',window,scaleColor,activeTicRects)
            Screen('FillRect',window,activeColor,activeTicRects(:,currentRating));
            
            DrawFormattedText(window, 'Wie fühlen Sie sich gerade?', 'center',yCenter-100, scaleColor);
            
            Screen('DrawText',window,'sehr',axesRect(1)-17,yCenter+50,scaleColor);
            Screen('DrawText',window,'schlecht',axesRect(1)-30,yCenter+70,scaleColor);
            
            Screen('DrawText',window,'sehr',axesRect(3)-25,yCenter+50,scaleColor);
            Screen('DrawText',window,'gut',axesRect(3)-20,yCenter+70,scaleColor);
            
            
            if response == 0
                
                % set time 0 (for reaction time)
                if first_flip   == 1
                    secs0       = Screen('Flip', window); % output Flip -> starttime rating
                    first_flip  = 0;
                    % after 1st flip -> just flips without setting secs0 to null
                else
                    Screen('Flip', window);
                end
                
                
                [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                if keyIsDown % only if a key was pressed we check which key it was
                    response = 0; % predefine variable for confirmation button 'space'
                    nrbuttonpresses = nrbuttonpresses + 1;
                    if keyCode(moreKey) % if it was the key we named key1 at the top then...
                        currentRating = currentRating + 1;
                        finalRating = currentRating;
                        response = 0;
                        %                 disp(num2str(currentRating));
                        if currentRating > nRatingSteps
                            currentRating = nRatingSteps;
                        end
                        
                    elseif keyCode(lessKey)
                        currentRating = currentRating - 1;
                        finalRating = currentRating;
                        response = 0;
                        %                 disp(num2str(currentRating));
                        if currentRating < 1
                            currentRating = 1;
                        end
                        
                    elseif keyCode(escapeKey)
                        reactionTime = 99; % to differentiate between ESCAPE and timeout in logfile
                        VASoff = GetSecs-StartExp;
                        disp('***********');
                        disp('Abgebrochen');
                        disp('***********');
                        break;
                    elseif keyCode(confirmKey)
                        finalRating = currentRating-4;
                        disp(['Mood Rating: ' num2str(finalRating)]);
                        if finalRating < 0
                            warning(sprintf('\n***********\n***********\nParticipant does not feel good!\nPlease check participant!!!\n***********\n***********\n'));
                        end
                        response = 1;
                        reactionTime = secs - secs0;
                        
                        
                        Screen('FillRect', window, backgroundColor, windowRect);
                        Screen('Flip', window);
                        %                 flip_confKey = GetSecs; VASoff = GetSecs-StartExp;
                        %                 numberOfSecondsRemaining_sharp = durRating-(flip_confKey-startTime);
                        %                 WaitSecs(numberOfSecondsRemaining_sharp);
                        break;
                    end
                    WaitSecs(0.15);
                    disp(currentRating);disp(finalRating);
                end
            end
            
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
            
            %     if (GetSecs - loopTime) < 0.3
            %         disp(GetSecs - loopTime);
            %         WaitSecs(0.3 - loopTime);
            %     end
        end
        if nrbuttonpresses ~= 0 && response == 0
            finalRating = currentRating - 4;
            reactionTime = durRating;
            disp(['Mood Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\n***********\nNo Confirmation!!!\n***********\n***********\n'));
        elseif nrbuttonpresses == 0
            finalRating = NaN;
            reactionTime = durRating;
            disp(['Mood Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\n***********\nNo Response!\nPlease check participant!!!\n***********\n***********\n'));
        end
    end
%% T2 Rating
    function [finalRating,reactionTime,response] = vasScaleT2(window,windowRect,durRating,defaultRating,backgroundColor,StartY,keys)
        
        % key settings
        KbName('UnifyKeyNames');
        lessKey =  keys.left; % yellow button
        moreKey =  keys.right; % red button
        confirmKey =  keys.confirm;  % green button
        escapeKey = keys.esc;
        
        if isempty(window); error('Please provide window pointer for likertScale!'); end
        if isempty(windowRect); error('Please provide window rect for likertScale!'); end
        if isempty(durRating); error('Duration length of rating has to be specified!'); end
        
        % Default values
        nRatingSteps = 101;
        scaleWidth = 700;
        textSize = 20;
        lineWidth = 6;
        scaleColor = [255 255 255];
        activeColor = [255 0 0];
        
        if isempty(defaultRating); defaultRating = round(nRatingSteps/2); end
        if isempty(backgroundColor); backgroundColor = 0; end
        
        % if length(ratingLabels) ~= nRatingSteps
        %     error('Rating steps and label numbers do not match')
        % end
        
        %% Calculate rects
        activeAddon_width = 1.5;
        activeAddon_height = 20;
        [xCenter, yCenter] = RectCenter(windowRect);
        yCenter = StartY;
        axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        lowLabelRect = [axesRect(1),yCenter-20,axesRect(1)+6,yCenter+20];
        highLabelRect = [axesRect(3)-6,yCenter-20,axesRect(3),yCenter+20];
        ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
        % ticRects = [ticPositions;ones(1,nRatingSteps)*yCenter;ticPositions + lineWidth;ones(1,nRatingSteps)*yCenter+tickHeight];
        activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];
        % keyboard
        
        
        Screen('TextSize',window,textSize);
        Screen('TextColor',window,[255 255 255]);
        Screen('TextFont', window, 'Arial');
        currentRating = defaultRating;
        finalRating = currentRating;
        reactionTime = 0;
        response = 0;
        first_flip  = 1;
        startTime = GetSecs;
        numberOfSecondsRemaining = durRating;
        nrbuttonpresses = 0;
        
        
        %%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
        % tic; % control if timing is as long as durRating
        while numberOfSecondsRemaining  > 0
            Screen('FillRect',window,backgroundColor);
            Screen('FillRect',window,scaleColor,axesRect);
            Screen('FillRect',window,scaleColor,lowLabelRect);
            Screen('FillRect',window,scaleColor,highLabelRect);
            Screen('FillRect',window,activeColor,activeTicRects(:,currentRating));
            
            DrawFormattedText(window, 'Bitte bewerten Sie die Schmerzhaftigkeit', 'center',yCenter-100, scaleColor);
            DrawFormattedText(window, ' VOR dem Sternchen', 'center',yCenter-70, scaleColor);
            
            Screen('DrawText',window,'kein',axesRect(1)-17,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(1)-40,yCenter+45,scaleColor);
            
            Screen('DrawText',window,'unerträglicher',axesRect(3)-55,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(3)-40,yCenter+45,scaleColor);
            
            
            
            % Remove this line if a continuous key press should result in a continuous change of the scale
            %     while KbCheck; end
            
            if response == 0
                
                % set time 0 (for reaction time)
                if first_flip   == 1
                    secs0       = Screen('Flip', window); % output Flip -> starttime rating
                    first_flip  = 0;
                    % after 1st flip -> just flips without setting secs0 to null
                else
                    Screen('Flip', window);
                end
                
                [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                if keyIsDown % only if a key was pressed we check which key it was
                    response = 0; % predefine variable for confirmation button 'space'
                    nrbuttonpresses = nrbuttonpresses + 1;
                    if keyCode(moreKey) % if it was the key we named key1 at the top then...
                        currentRating = currentRating + 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating > nRatingSteps
                            currentRating = nRatingSteps;
                        end
                    elseif keyCode(lessKey)
                        currentRating = currentRating - 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating < 1
                            currentRating = 1;
                        end
                    elseif keyCode(escapeKey)
                        reactionTime = 99; % to differentiate between ESCAPE and timeout in logfile
                        VASoff = GetSecs-StartExp;
                        disp('***********');
                        disp('Abgebrochen');
                        disp('***********');
                        break;
                    elseif keyCode(confirmKey)
                        finalRating = currentRating-1;
                        disp(['VAS Rating: ' num2str(finalRating)]);
                        response = 1;
                        reactionTime = secs - secs0;
                        break;
                    end
                end
            end
            
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
            
        end
        if nrbuttonpresses ~= 0 && response == 0
            finalRating = currentRating - 1;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\n***********\nNo Confirmation!!!\n***********\n***********\n'));
        elseif nrbuttonpresses == 0
            finalRating = NaN;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\n***********\nNo Response!\nPlease check participant!!!\n***********\n***********\n'));
        end
    end
%%T3 Rating
    function [finalRating,reactionTime,response] = vasScaleT3(window,windowRect,durRating,defaultRating,backgroundColor,StartY,keys,prevRating)
        
        %% key settings
        KbName('UnifyKeyNames');
        lessKey =  keys.left; % yellow button
        moreKey =  keys.right; % red button
        confirmKey =  keys.confirm;  % green button
        escapeKey = keys.esc;
        
        if isempty(window); error('Please provide window pointer for likertScale!'); end
        if isempty(windowRect); error('Please provide window rect for likertScale!'); end
        if isempty(durRating); error('Duration length of rating has to be specified!'); end
        
        %% Default values
        nRatingSteps = 101;
        scaleWidth = 700;
        textSize = 20;
        lineWidth = 6;
        scaleColor = [255 255 255];
        prevColor = [255 128 128];
        activeColor = [255 0 0];
        if isempty(defaultRating); defaultRating = round(nRatingSteps/2); end
        if isempty(backgroundColor); backgroundColor = 0; end
        
        % if length(ratingLabels) ~= nRatingSteps
        %     error('Rating steps and label numbers do not match')
        % end
        
        %% Calculate rects
        activeAddon_width = 1.5;
        activeAddon_height = 20;
        [xCenter, yCenter] = RectCenter(windowRect);
        yCenter = StartY;
        axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        lowLabelRect = [axesRect(1),yCenter-20,axesRect(1)+6,yCenter+20];
        highLabelRect = [axesRect(3)-6,yCenter-20,axesRect(3),yCenter+20];
        ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
        % ticRects = [ticPositions;ones(1,nRatingSteps)*yCenter;ticPositions + lineWidth;ones(1,nRatingSteps)*yCenter+tickHeight];
        activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];
        % keyboard
        
        if isnan(prevRating)
            prevRating = 0;
        end
        
        Screen('TextSize',window,textSize);
        Screen('TextColor',window,[255 255 255]);
        Screen('TextFont', window, 'Arial');
        currentRating = defaultRating;
        finalRating = currentRating;
        reactionTime = 0;
        response = 0;
        first_flip  = 1;
        startTime = GetSecs;
        numberOfSecondsRemaining = durRating;
        nrbuttonpresses = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
        % tic; % control if timing is as long as durRating
        while numberOfSecondsRemaining  > 0
            Screen('FillRect',window,backgroundColor);
            Screen('FillRect',window,scaleColor,axesRect);
            Screen('FillRect',window,scaleColor,lowLabelRect);
            Screen('FillRect',window,scaleColor,highLabelRect);
            Screen('FillRect',window,prevColor,activeTicRects(:,prevRating+1));
            Screen('FillRect',window,activeColor,activeTicRects(:,currentRating));
            
            DrawFormattedText(window, 'Bitte bewerten Sie die Schmerzhaftigkeit', 'center',yCenter-100, scaleColor);
            DrawFormattedText(window, 'NACH dem Sternchen', 'center',yCenter-70, scaleColor);
            
            Screen('DrawText',window,'kein',axesRect(1)-17,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(1)-40,yCenter+45,scaleColor);
            
            Screen('DrawText',window,'unerträglicher',axesRect(3)-55,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(3)-40,yCenter+45,scaleColor);
            
            
            
            % Remove this line if a continuous key press should result in a continuous change of the scale
            %     while KbCheck; end
            
            if response == 0
                
                % set time 0 (for reaction time)
                if first_flip   == 1
                    secs0       = Screen('Flip', window); % output Flip -> starttime rating
                    first_flip  = 0;
                    % after 1st flip -> just flips without setting secs0 to null
                else
                    Screen('Flip', window);
                end
                
                [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                if keyIsDown % only if a key was pressed we check which key it was
                    response = 0; % predefine variable for confirmation button 'space'
                    nrbuttonpresses = nrbuttonpresses + 1;
                    if keyCode(moreKey) % if it was the key we named key1 at the top then...
                        currentRating = currentRating + 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating > nRatingSteps
                            currentRating = nRatingSteps;
                        end
                    elseif keyCode(lessKey)
                        currentRating = currentRating - 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating < 1
                            currentRating = 1;
                        end
                    elseif keyCode(escapeKey)
                        reactionTime = 99; % to differentiate between ESCAPE and timeout in logfile
                        VASoff = GetSecs-StartExp;
                        disp('***********');
                        disp('Abgebrochen');
                        disp('***********');
                        break;
                    elseif keyCode(confirmKey)
                        finalRating = currentRating-1;
                        disp(['VAS Rating: ' num2str(finalRating)]);
                        response = 1;
                        reactionTime = secs - secs0;
                        break;
                    end
                end
            end
            
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
            
        end
        % WaitSecs(0.3);
        if nrbuttonpresses ~= 0 && response == 0
            finalRating = currentRating - 1;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\n***********\nNo Confirmation!!!\n***********\n***********\n'));
        elseif nrbuttonpresses == 0
            finalRating = NaN;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\n***********\nNo Response!\nPlease check participant!!!\n***********\n***********\n'));
        end
    end
%%online rating
    function [conRating,conTime,response] = onlineScale(window,windowRect,durRating,backgroundColor,StartY,keys,starTime)
        
        %% key settings
        KbName('UnifyKeyNames');
        lessKey =  keys.left; % yellow button
        moreKey =  keys.right; % red button
        escapeKey = keys.nextStep;
        
        if isempty(window); error('Please provide window pointer for likertScale!'); end
        if isempty(windowRect); error('Please provide window rect for likertScale!'); end
        if isempty(durRating); error('Duration length of rating has to be specified!'); end
        
        %% Default values
        nRatingSteps = 101;
        scaleWidth = 700;
        textSize = 20;
        lineWidth = 6;
        scaleColor = [255 255 255];
        activeColor = [255 0 0];
        defaultRating = 1;
        if isempty(backgroundColor); backgroundColor = 0; end
        if isempty(starTime); starTime = 0; end
        
        % if length(ratingLabels) ~= nRatingSteps
        %     error('Rating steps and label numbers do not match')
        % end
        
        %% Calculate rects
        activeAddon_width = 1.5;
        activeAddon_height = 20;
        [xCenter, yCenter] = RectCenter(windowRect);
        yCenter = StartY;
        axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        lowLabelRect = [axesRect(1),yCenter-20,axesRect(1)+6,yCenter+20];
        highLabelRect = [axesRect(3)-6,yCenter-20,axesRect(3),yCenter+20];
        midLabelRect = [xCenter-3,yCenter-20,xCenter+3,yCenter+20];
        midlLabelRect = [xCenter-3-scaleWidth/4,yCenter-20,xCenter+3-scaleWidth/4,yCenter+20];
        midhLabelRect = [xCenter-3+ scaleWidth/4,yCenter-20,xCenter+3+scaleWidth/4,yCenter+20];
        ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
        activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];
        
        Screen('TextSize',window,textSize);
        Screen('TextColor',window,[255 255 255]);
        Screen('TextFont', window, 'Arial');
        currentRating = defaultRating;
        finalRating = currentRating;
        response = 0;
        
        numberOfSecondsRemaining = durRating;
        conRating = 0;
        conTime = 0;
        
        
        %%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
        % tic; % control if timing is as long as durRating
        
        startTime = GetSecs;
        while numberOfSecondsRemaining  > 0
            
            Screen('FillRect',window,backgroundColor);
            Screen('FillRect',window,activeColor,[activeTicRects(1,1)+3 activeTicRects(2,1)+ 5 activeTicRects(3,currentRating)-3 activeTicRects(4,1)-5]);
            Screen('FillRect',window,scaleColor,lowLabelRect);
            Screen('FillRect',window,scaleColor,highLabelRect);
            Screen('FillRect',window,scaleColor,midLabelRect);
            Screen('FillRect',window,scaleColor,midlLabelRect);
            Screen('FillRect',window,scaleColor,midhLabelRect);
            
            %     DrawFormattedText(window, 'Bitte bewerten Sie die Schmerzhaftigkeit', 'center',yCenter-100, scaleColor);
            %     DrawFormattedText(window, 'des Hitzereizes', 'center',yCenter-70, scaleColor);
            
            Screen('DrawText',window,'kein',axesRect(1)-17,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(1)-40,yCenter+45,scaleColor);
            
            Screen('DrawText',window,'unerträglicher',axesRect(3)-55,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(3)-40,yCenter+45,scaleColor);
            
            if (numberOfSecondsRemaining <= (durRating - (durRating/2.5) + 0.01)) && (numberOfSecondsRemaining >= (durRating - (durRating/2.5)- starTime - 0.01))
                %         disp(GetSecs-startTime);
                Screen('TextSize',window,70);
                Screen('DrawText',window,'*',xCenter-12,yCenter-70,scaleColor);
            end
            Screen('Flip', window);
            Screen('TextSize',window,textSize);
            
            [keyIsDown,secs,keyCode] = KbCheck; % this checks the keyboard very, very briefly.
            
            if keyIsDown % only if a key was pressed we check which key it was
                response = 1;
                if keyCode(moreKey) % if it was the key we named key1 at the top then...
                    currentRating = currentRating + 1;
                    if currentRating > nRatingSteps
                        currentRating = nRatingSteps;
                    end
                    finalRating = currentRating - 1;
                    conRating(end+1) = finalRating;
                    conTime(end+1) = GetSecs - startTime;
                elseif keyCode(lessKey)
                    currentRating = currentRating - 1;
                    if currentRating < 1
                        currentRating = 1;
                    end
                    finalRating = currentRating - 1;
                    conRating(end+1) = finalRating;
                    conTime(end+1) = GetSecs - startTime;
                    %             elseif keyCode(escapeKey)
                    %                 disp(['Middle Pain: ' num2str(GetSecs - startTime)]);
                end
            end
            
            conRating(end+1) = finalRating;
            conTime(end+1) = GetSecs - startTime;
            
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
            
        end
        % figure;plot(conTime,conRating);
        
    end
%% After experiment is over clean everything and close drivers
    function cleanup
        sca;                                                               % Close window:
        commandwindow;
        ListenChar(0);                                                     % Use keys again
        %KbQueueRelease(p_ptb_device);
        save(p.path.save ,'p');
        if run == 4
            diary off;
        end
    end


end





