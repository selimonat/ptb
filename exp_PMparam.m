function [p] = remi3_fmri(subject,run,group)

    if nargin == 0
        subject = 99; run = 1; group = 1;
    end

    if group == 1
        name = 'NaCl';
    elseif group == 2
        name = 'Remi50';
    elseif goup == 3
        name = 'Remi100';
    end
    fprintf(['Sub' num2str(subject) '\nRun' num2str(run) '\nGroup: ' name '\n']);



    %%%%%%%%%%%%%%%%%%%%%%%%%%% Put in your experiment choices here
    debug       = 1;                                                           % Use this function to have a transparent screen
    p_mri_on    = 0;                                                           % If on, waits for pulses and useses BrainVision Recorder marking BEFORE it marks CED. Otherwise, it only uses CED marking and sets BVR to 0
    p_slave_on  = 0;                                                           % If on, waits for pulse from master and starts presentation at the same time.


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                 Initialize Experiment Environment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %ListenChar(2);                                                             % Disable pressed keys to printed out; Ctrl+C reenables keyboard
    commandwindow;
    %clear everything without using 'clear all'
    clear mex global functions

    %%%%%%%%%%%%%%%%%%%%%%%%%%% Load the GETSECS mex files so call them at
    %%%%%%%%%%%%%%%%%%%%%%%%%%% least oncec
    GetSecs;
    WaitSecs(0.001); %?? Why?

    SetParameters;

    if strcmp(p.hostname,'triostim1')                                          % Automatically disable debug mode if run from fMRI server
        debug = 0;
    end

    SetPTB;


    %%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize all variables
    nTrial                          = 0; %?? why are some grey? Bc they are used later on? No...
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
    p_presentation_TrialList        = p.trialList;
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
    fprintf(['=================\n=================\nStart thermode protocol ' num2str(p.presentation.stimSequence) '!!!!\n']);

    % Show Instructions;
    ShowInstruction;

    % Wait for Dummy Scans
    %firstScannerPulseTime = WaitPulse(p.keys.trigger,p.mri.dummyScan); %??
    %TEMP REMOVAL
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
        p.subinfo.run                  = run;
        %         p.subinfo.trialList            = trialList;
        
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% relative paths to stim and experiments
        [~, hostname] = system('hostname');
        p.hostname                     = deblank(hostname);
        p.hostaddress = java.net.InetAddress.getLocalHost ;
        p.hostIPaddress = char( p.hostaddress.getHostAddress);
        if strcmp(p.hostname,'triostim1')
            p.path.experiment          = 'C:\USER\horing\PMParametric\';
            p.monitor.Xaxis                = 1024; % stim PC resolution
            p.monitor.Yaxis                = 768; % stim PC resolution
        else
            p.path.experiment        = 'C:\Users\Bjoern\Google Drive\_STUDIEN (2014+)\2016_parametric pain matrix\m files\';
            p.monitor.Xaxis                = 1920; % stim PC resolution
            p.monitor.Yaxis                = 1200; % stim PC resolution
        end
        %
        p.subID                        = sprintf('sub%02d',subject);
        p.timestamp                    = datestr(now,30);
       
        %define and create subject folder path        
        p.path.subject                 = [p.path.experiment 'logs/' p.subID '/'];
        mkdir(p.path.subject);
        
        %??Why doesn't this folder need to be created, too?
        %define subfolder of subject folder for current trial number/run
        p.path.save                    = [p.path.subject  p.subID '_run' num2str(p.subinfo.run) '_' p.timestamp ];    
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% font size, background gray level, monitor settings
        p.text.fontname                = 'Arial';
        p.text.fontsize                = 20; %30; %18;
        p.text.linespace               = 10;
        p.stim.white                   = [255 255 255];
        p.stim.red                     = [255 0 0];
        p.stim.backgr                  = [70 70 70];
        p.stim.widthCross              = 3;
        p.stim.sizeCross               = 20;
        p.MoodRating                   = []; %?? How is this a monitor setting?
        p.Rating1                      = []; %?? How is this a monitor setting?
        p.Rating2                      = []; %?? How is this a monitor setting?
        
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
        iti                             = [24 24.5 25 25.5 26 26 26.5 27 27.5 28];
%        trialLists                      = load([p.path.experiment 'trial_seq.mat']); %?? TEMP REMOVAL
%        trialLists                      = trialLists.trial_seq; %?? TEMP REMOVAL
trialLists=[1 2 3 4;1 2 4 3;2 1 3 4;2 1 4 3]; %HILFSKONSTRUKT
%        sequence                        = load([p.path.experiment 'rand_seq.mat']); %?? TEMP REMOVAL 
%        sequence                       = sequence.rand_seq; %?? TEMP REMOVAL
sequence=round((4-1).*rand(4,99)+1); %HILFSKONSTRUKT
        p.presentation.stimSequence     = sequence(run,subject);
        p.trialList                     = trialLists(:,p.presentation.stimSequence);
        p.presentation.tTrial           = length(p.trialList);  %number of trials
        p.presentation.itiDuration      = iti(randperm(length(iti)));
        p.presentation.CueDuration      = 4;
        p.presentation.scaleDuration    = 21;
        p.presentation.scaleBackColor   = p.stim.backgr;
        p.BreathRem                     = 3;
        p.starTime                      = 0.6;
        p.lastITI                       = 5;
        
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
        Screen('Preference', 'SkipSyncTests', 1);
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
        %         p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.stim.width p.stim.height];
        
        p.ptb.priorityLevel=MaxPriority('GetSecs','KbCheck','KbWait');
        Priority(MaxPriority(p.ptb.w));
        p.ptb.device        = [];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Parallel port communication.
        %config_io;%?? TEMP REMOVAL
        %outp(p.com.lpt.CEDaddress,0);%?? TEMP REMOVAL
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Functions collection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [secs]=WaitPulse(keyCode,n)
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
            while pulse < n %Listening loop
                keyboard
                dummy         = KbTriggerWait(keyCode,p.ptb.device);
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
            
            p.log.scaleDefaultVAS1(nTrial,1) = randi([20,81]);
            p.log.scaleDefaultVAS2(nTrial,1) = randi([20,81]);
            p.log.scaleDefaultMood(nTrial,1) = randi([3,6]);
            
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
        if p.presentation.stimSequence == 2 && nTrial == 2 || p.presentation.stimSequence == 2 && nTrial == 7 ||...   
            p.presentation.stimSequence == 4 && nTrial == 1 || p.presentation.stimSequence == 4 && nTrial == 6 
                DrawFormattedText(p_ptb_w, 'Im nächsten Durchgang bewerten Sie bitte', 'center',p_ptb_startY-100, p_stim_white);
                DrawFormattedText(p_ptb_w, 'die Schmerzhaftigkeit WÄHREND des Hitzereizes!', 'center',p_ptb_startY-70, p_stim_white);
        end
        
        Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1);
        Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);       
        TimeCueOn = Screen('Flip',p_ptb_w);
        putLog(TimeCueOn, 'CueOnset');
        p.reactionTime(nTrial) = getRT(p_presentation_CueDuration,TimeCueOn);  % check reaction time during cue
        if nTrial > 1
            if isnan(p.reactionTime(end)) && isnan(p.reactionTime(end-1))
                warning(sprintf('\n***********\n***********\nNo RT for 2 Trials!\nPlease check participant!!!\n***********\n***********\n'));
            end
        end
        
        %Pain
        %online rating scale
%         if p.presentation.stimSequence == 2 && nTrial == 2 || p.presentation.stimSequence == 2 && nTrial == 7 ||...   
%             p.presentation.stimSequence == 4 && nTrial == 1 || p.presentation.stimSequence == 4 && nTrial == 6 
            TimeHeatOn = GetSecs;
            putMark(p_com_lpt_HeatOnset);
            putLog(TimeHeatOn, 'HeatOnset');            
            [p.onrating.conRating,p.onrating.conTime,p.onrating.response] = onlineScale(p_ptb_w,p.ptb.rect,...
                p_presentation_stimDuration,p_stim_backgr,p_ptb_startY,p.keys,p.starTime); %
            putOnRatingLog(nTrial);
            
%         else % only showing cross during pain 
%             Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1); % no treatment condition
%             Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
%             TimeHeatOn = Screen('Flip',p_ptb_w);
%             putMark(p_com_lpt_HeatOnset);
%             putLog(TimeHeatOn, 'HeatOnset');
%             fprintf('Heat on\n');
%             while GetSecs < TimeHeatOn + (p_presentation_stimDuration/2.5) end % = WaitSecs(p_presentation_stimDuration);
%             %Show star for rating
%             Screen('TextSize',p_ptb_w,p.text.fontsize+40);
%             Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1); % no treatment condition
%             Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
%             Screen('DrawText', p_ptb_w,'*',p.ptb.midpoint(1)-14,p.ptb.startY-60,p_stim_white);
%             TimeStarOn = Screen('Flip',p_ptb_w);
%             putLog(TimeStarOn, 'StarOnset');
%             fprintf('Star on\n');
%             while GetSecs < TimeStarOn + p.starTime end
%             Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix1); % no treatment condition
%             Screen('FillRect', p_ptb_w, p_stim_red, p.ptb.whiteFix2);
%             TimeHeatOn2 = Screen('Flip',p_ptb_w);
%             
%             while GetSecs < TimeStarOn + (p_presentation_stimDuration - (p_presentation_stimDuration/2.5)) end % = WaitSecs(p_presentation_stimDuration);
%         end
        
        %blank screen
        TimeBlankOn = Screen('Flip',p_ptb_w);
        while GetSecs < TimeBlankOn + p_presentation_blankDuration end % = WaitSecs(p_presentation_blankDuration);
        putLog(TimeBlankOn, 'BlankOnset');
        
        %VAS T3
        putLog(GetSecs, 'VAS1Onset');
        putMark(p_com_lpt_VASOnset);
        fprintf('VAS_T3 on\n');
        
        [p.rating1.finalRating,p.rating1.reactionTime,p.rating1.response] = vasScaleT3(p_ptb_w,p.ptb.rect,...
            p_presentation_scaleDuration,p.log.scaleDefaultVAS1(nTrial,1),p_stim_backgr,p_ptb_startY,p.keys); %
        putRating1Log(nTrial);
        p.Rating1(nTrial) = p.rating1.finalRating;
        
        %blank screen
        TimeBlankOn = Screen('Flip',p_ptb_w);
        while GetSecs < TimeBlankOn + p_presentation_blankDuration end % = WaitSecs(p_presentation_blankDuration);
        putLog(TimeBlankOn, 'BlankOnset');
        
        %VAS peak
        putLog(GetSecs, 'VAS2Onset');
        putMark(p_com_lpt_VASOnset);
        fprintf('VAS_peak on\n');
        
        [p.rating2.finalRating,p.rating2.reactionTime,p.rating2.response] = vasScaleT2(p_ptb_w,p.ptb.rect,...
            p_presentation_scaleDuration,p.log.scaleDefaultVAS2(nTrial,1),p_stim_backgr,p_ptb_startY,p.keys,p.rating1.finalRating); %
        putRating2Log(nTrial);
        p.Rating2(nTrial) = p.rating2.finalRating;
        
        %blank screen
        TimeBlankOn = Screen('Flip',p_ptb_w);
        while GetSecs < TimeBlankOn + p_presentation_blankDuration end % = WaitSecs(p_presentation_blankDuration);
        putLog(TimeBlankOn, 'BlankOnset');
        
        %Mood
        putLog(GetSecs, 'MoodOnset');
        fprintf('Mood on\n');
        
        [p.mood.finalRating,p.mood.reactionTime,p.mood.response] = moodScale(p_ptb_w,p.ptb.rect,...
            p_presentation_scaleDuration,p.log.scaleDefaultMood(nTrial,1),p_stim_backgr,p_ptb_startY,p.keys); %p.log.scaleDefaultVAS(nTrial,1)
        putMoodLog(nTrial);
        p.MoodRating(nTrial) = p.mood.finalRating;
        if nTrial > 1
            if p.MoodRating(end)+3 <= p.MoodRating(end-1)
                warning(sprintf('\n***********\n***********\nParticipant rated 3 points less!\nPlease check participant!!!\n***********\n***********\n'));
            end
        end
        
%         %Breath 
%         Screen('TextSize',p_ptb_w,p.text.fontsize);
%         p_monitor_ny = p.monitor.Yaxis/4;
%         [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'Bitte achten Sie darauf,', 'center', p_monitor_ny, p_stim_white);
%         [p_monitor_nx, p_monitor_ny, textbounds]=DrawFormattedText(p_ptb_w, 'ruhig und gleichmäßig durch die Nase zu atmen.', 'center', p_monitor_ny+p_ptb_lineheight, p_stim_white);
%         
%         fprintf('Breath Reminder\n');
%         TimeBreathOn = Screen('Flip',p_ptb_w);       
%         putLog(TimeBreathOn, 'BreathOnset');
%         while GetSecs < TimeBreathOn + p.BreathRem end
        
        %ITI
        p.presentation.itiDurationReal(nTrial) = (itiDuration + p.lastITI) - (p.mood.reactionTime+p.rating1.reactionTime+p.rating2.reactionTime);
        
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
% %             p.presentation.itiDurationReal(nTrial) = p.presentation.itiDurationReal(nTrial) + abs(p.presentation.itiDurationReal(nTrial) - p.BreathRem);
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
       
       fprintf('=================\n=================\nInput "%s" required to continue...\n',p_keys_nextStep);
        
         while 1 %?? Listening loop
            [keyIsDown, ~, keyCode] = KbCheck();      % Start waiting 1/2 TR before JitterOnset for next pulse (this avoids collecting Pulses before). %?? what's with the tilde ~?
            if keyIsDown
                if find(keyCode) == p_keys_nextStep;
                    break;
                end
            end
        end
        
        %FlushEvents('keyDown'); %?? can't hurt, can it?
        
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





