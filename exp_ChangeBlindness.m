function [p]=exp_ChangeBlindness(subject)

phase   = 1;
debug   = 0;%debug mode => 1: transparent window enabling viewing the background.
EyelinkWanted = 1;%is Eyelink wanted?
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

%
if EyelinkWanted
    CalibrateEL;
end
%% Vormessung
p.var.ExpPhase  = phase;%set this after the calibration, because there it's set to zero
k = 0;
while ~(k == p.keys.el_calib);
    pause(0.1);
    fprintf('Experimenter!! press V key when you want to start.\n');
    [~, k] = KbStrokeWait(p.ptb.device);
    k = find(k);
end
fprintf('Continuing...\n');
%%
ShowInstruction(1,1);
ShowInstruction(2,1);
PresentStimuli;

ShowInstruction(4,0,4);
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
if EyelinkWanted
    %rename the edf file to data.edf
    movefile([p.path.path_edf p.path.edf],[p.path.path_edf 'data.edf'],'f');
end
movefile(p.path.subject,p.path.finalsubject);
%close everything down
cleanup;

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
        TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        for nTrial  = 1:p.presentation.tTrial;
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            ISI          = p.presentation.ISI(nTrial);
            prestimdur   = p.duration.prestim+rand(1)*.25;
            dist         = p.presentation.dist(nTrial);
            %
            OnsetTime     = TimeEndStim + ISI-p.duration.stim - p.ptb.slack;
            fprintf('%03d of %03d, S: %d, ISI: %d, OnsetTime: %f secs, ',nTrial,p.presentation.tTrial,stim_id,ISI,OnsetTime);
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim] = Trial(nTrial,OnsetTime, prestimdur, stim_id);
            %(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist )
            fprintf('OffsetTime: %f secs, Difference of %f secs\n',TimeEndStim,TimeEndStim-OnsetTime);
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
            if nTrial == 1
                ShowInstruction(3,1);
                k = 0;
                while ~(k == p.keys.el_calib);
                    pause(0.1);
                    fprintf('Subject is OK, are you? Press v to start!......');
                    [~, k] = KbStrokeWait(p.ptb.device);
                    k = find(k);
                end
                KbQueueFlush(p.ptb.device)
                fprintf('Subject and experimenter confirmed. Starting experiment!\n');
                TimeEndStim = GetSecs + 3;
            end
        end
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
%         if p.var.ExpPhase > 0
%             WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%
%             fprintf('OK!! Stop the Scanner\n');
%         end
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
    function [TimeEndStim]=Trial(nTrial,FirstOnset ,prestimdur, stim_id)
        %get all the times
        TimeCrossOnset        = FirstOnset  - prestimdur;
        TimeStimOnset(1)      = FirstOnset;
        TimeFlip(1)           = FirstOnset  + p.duration.stim;
        for n = 2:p.duration.nChanges
            TimeStimOnset(n)      = TimeStimOnset(n-1)+p.duration.stim+p.duration.blank;
            TimeFlip(n)           = TimeFlip(n-1)+p.duration.stim+p.duration.blank;
            %             TimeEndStim           = TimeStimOnset  + p.duration.stim- p.ptb.slack;
        end
        TimeTrackerOff        = max([TimeStimOnset TimeFlip])  + p.duration.keep_recording;
        %% Fixation Cross Onset
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);
        Log(TimeCrossOn,1,fix(1));%cross onset.
        %turn the eye tracker on
        StartEyelinkRecording(nTrial,stim_id,phase);%I would be cautious here, the first trial is never recorded in the EDF file, reason yet unknown.
        %% microTrial Loop: Change from A 2 B as often as needed
        for nnTrial = 1:p.duration.nChanges
                if mod(nnTrial,2)== 1 %% for odd number (1,3,5,..) show A, for even number (2,4,..) show B
                    image_id = stim_id;
                else
                    image_id = stim_id+1;
                end                
                Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(image_id));
                %% STIMULUS ONSET
                ActualOnset  = Screen('Flip',p.ptb.w,TimeStimOnset(nnTrial),0);%asap and dont clear
                %update the image on ET screen, so we can see the change
                %there
                %send eyelink marker
                if nnTrial == 1
                    Log(ActualOnset,3,stim_id);%log the stimulus onset with file_number
                    if EyelinkWanted % I would send it only at the beginning, not for every change from blank to picture.
                        Eyelink('Message', 'Stim Onset');
                        Eyelink('Message', 'SYNCTIME');
                    end
                end
                Log(ActualOnset,13,image_id); % Log all MicroOnsets
                %% flip to blank
                FlipOnset = Screen('Flip',p.ptb.w,TimeFlip(nnTrial),0);
                Log(FlipOnset,16,image_id);%log the stimulus offset
%                 if  KbQueueCheck(p.ptb.device)
%                     TimeTrackerOff = GetSecs + p.duration.keep_recording;
%                     break
%                 end
        end
        %% STIM OFF immediately
        TimeEndStim = Screen('Flip',p.ptb.w);
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
        TimeEndStim       = GetSecs;
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
        if ismac
        p.path.baselocation           = '/Users/onat/Documents/Experiments/NoS/data';
        else
            p.path.baselocation           = 'C:\Users\Lea\Documents\Experiments\NoS\data';
        end
        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0
            mkdir(p.path.baselocation);
        end
        
        p.path.experiment             = [p.path.baselocation  filesep];
        p.path.stim                  = [fileparts(which('exp_ChangeBlindness.m')) filesep 'bin' filesep 'CB_Stimuli' filesep];
        p.path.stim24                 = [p.path.stim '24bit' filesep];%location of 24bit stimuli, useful only to send it to the eyelink system
        
        %
        p.subID                       = sprintf('s%02d',subject);%subject id
        timestamp                     = datestr(now,30);%the time_stamp of the current experiment.
        p.path.subject                = [p.path.experiment  'tmp' filesep p.subID '_' timestamp filesep sprintf('run%03d',phase) filesep];%subject folder, first we save it to the temp folder.
%         p.path.subject           = [p.path.subject sprintf('run%03d',phase) filesep];
        p.path.finalsubject           = [p.path.experiment  sprintf('sub%03d',subject) filesep];%final location of the subject folder
        p.path.path_edf               = [p.path.subject  'eye' filesep];%location of the edf file in the eyelink computer
        p.path.edf                    = sprintf([p.subID 'p%02d.edf' ],phase);%EDF file in the stimulus computer
        p.path.path_param             = [p.path.subject 'stimulation' filesep 'data.mat'];%location of the paradigm file.
        %create folder hierarchy for this subject
%         mkdir(p.path.subject);
        mkdir(p.path.subject);
        mkdir(p.path.finalsubject);
        mkdir([p.path.subject 'scr']);%location for the SCR data
        mkdir([p.path.subject 'eye']);%location for the edf file and eye-movement related data.
        mkdir([p.path.subject 'stimulation']);%location of the stimulus presentation paradigm
        mkdir([p.path.subject 'midlevel']);%other data.
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.jpg']);%read in the stimlus
        p.stim.tFile                  = size(p.stim.files,1);%number of different files
        p.stim.tFace                  = 9;%number of scenes.
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
        %set the background gray according to the background of the stimuli
        for i = 1:p.stim.tFace;
            im                        = imread(p.stim.files(i,:));
            bg(i)                     = im(1,1,1);
        end
        % set bg as mean of each channel.
        p.stim.bg                   =  [155 155 155];%squeeze(mean(mean(im),2));
        
        %bg of the rating screen.
        p.stim.bg_rating               = p.stim.bg;
        p.stim.white                   = [0 0 0];
        %% font size and background gray level
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 45;
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
        p.keys.confirm                 = KbName('space');%
        p.keys.increase                = KbName('1!');
        p.keys.decrease                = KbName('3#');
        p.keys.pulse                   = KbName('5%');
        p.keys.el_calib                = KbName('v');
        p.keys.el_valid                = KbName('c');
        p.keys.escape                  = KbName('ESCAPE');
        p.keys.enter                   = KbName('Return');
        
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
        p.duration.stim                = .25;%s
        p.duration.blank               = .25; %duration of blank screen when changing from A to B
        p.duration.shock               = 0.1;%s;x
        p.duration.shockpulse          = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse     = 0.01;%ms; and the time between each pulse
        p.duration.onset2shock         = p.duration.stim - p.duration.shock;
        p.duration.crossmoves          = p.duration.stim./2;
        p.duration.keep_recording      = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.prestim             = .85;
        p.duration.nChanges            = 40; %number of blanks during trial, i.e. changing from iamge A to B
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence: Explanation of the fields:
        %Explanation of the fields:
        %.cond_id        => Condition id, this is the face to be loaded. 1-8: face id, 9 => oddball, 10 => UCS.
        %.UCS            => 1 if it is UCS trial, otherwise 0
        %.oddball        => 1 if it is an oddball trial
        %.stim_id        => same as cond_id, except for UCS stimuli, where the stim_id is the CS+. This is basically the index of the file that is gonna be read.
        %.dist           => The angular distance to CS+ face, this is the most important field for analysis
        %.cross_position => the position of the cross to be shown, could start from mouth and jump to eyes or vice versa. The exact position is computed in SetPTB.
        %.mblcok         => irrelevant for this experiment.
        %this will deal all the presentation sequence related information
        % quickly create a seq for ChangeBlindness here:
        
        p.presentation.stim_id         = 1:2:p.stim.tFile;
        p.presentation.cond_id         = 1:2:p.stim.tFile;
        p.presentation.tTrial          = length(p.presentation.stim_id);%Total Trials
        p.presentation.dist            = nan(1,p.presentation.tTrial);
        p.presentation.cross_position  = ones(1,p.presentation.tTrial);
        p.presentation.ISI             = Shuffle([3 4 5 3 4 5 3 4 5 4]);
        
        
        %distances are only defined for the face conditions, for example
        
        %% create the randomized design
        p.stim.cs_plus                 = nan;%index of cs stimulus, this is the one paired to shock
        p.stim.cs_neg                  = nan;
        %Record which Phase are we going to run in this run.
        p.stim.phase                  = phase;
        p.out.rating                  = [];%will contain explicite ratings of UCS likelihood
        p.out.log                     = zeros(1000000,4).*NaN;%Experimental LOG.
        p.out.response                = zeros(p.presentation.tTrial,1);%
        
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
            DrawFormattedText(p.ptb.w, double(sprintf(text)), 'center', 'center',p.stim.white,[],[],[],2,[]);            
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
                'Bitte fixieren Sie die nun folgenden wei' sprintf('\x00df') 'en Kreise und \n' ...
                'bleiben so lange darauf, wie sie zu sehen sind.\n\n' ...
                'Nach der Kalibrierung d' sprintf('\x00fc') 'rfen Sie Ihren Kopf nicht mehr bewegen.\n'...
                'Sollten Sie Ihre Position noch ver' sprintf('\x00e4') 'ndern m' sprintf('\x00fc') 'ssen, tun Sie dies am besten jetzt.\n'...
                'Die beste Position ist meist die bequemste.\n\n'...
                'Bitte dr' sprintf('\x00fc') 'cken Sie jetzt die Leertaste, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
            
        elseif nInstruct == 1%Training phase.
            text = ['Wir werden nun als erstes einen ' sprintf('\x00dc') 'bungsdurchgang machen,\n' ...
                'damit Sie sich an Ihre Aufgabe gew' sprintf('\x00f6') 'hnen k' sprintf('\x00f6') 'nnen.\n' ...
                '\n'...
                'Dr' sprintf('\x00fc') 'cken Sie die Leertaste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 2;%AskDetectionSelectable
            text = ['Sie sehen nun verschiedene Bilder.\n'...
                'Irgendetwas im Bild ver' sprintf('\x00e4') 'ndert sich von Zeit zu Zeit.\n'...
                '\n'...
                'Finden Sie die Ver' sprintf('\x00e4') 'nderung?\n\n'...
                'Wenn Sie sie entdeckt haben, dr' sprintf('\x00fc') 'cken Sie die Leertaste! \n'...
                'Bitte zum Starten ebenfalls die Leertaste dr' sprintf('\x00fc') 'cken.\n'...
                ];
        elseif nInstruct == 3;%AskDetectionSelectable
            text = ['Alles klar?\n'...
                '\n'...
                'Wenn Sie noch Fragen haben, k' sprintf('\x00f6') 'nnen Sie diese jetzt gerne stellen.\n\n'...
                '\n'...
                'Ansonsten zum Starten bitte die Leertaste dr' sprintf('\x00fc') 'cken.\n'...
                ];
        elseif nInstruct == 4
            text = ['Das wars!\n'...
                '\n'...
                'Gut gemacht!\n'...
                ];
        elseif nInstruct == 801;%AskDetectionSelectable
            text = ['Sie sehen nun eine \u00dcbersicht der verschiedenen Gesichter.\n'...
                'Bitte schauen Sie sich die Gesichter aufmerksam an.\n'...
                'Bitte dr\u00fccken Sie zum Start die Leertaste und\n' ...
                'fixieren Sie das anschlie\u00dfend erscheinende Fixationskreuz.\n'...
                ];
            
        elseif nInstruct == 9%
            %=================================================================================================================%
            text = ['Bitte geben Sie an, ob die Reizst\u00e4rke des folgenden Schocks\n f\u00fcr Sie ertr\u00e4glich ist.\n'...
                '\n'...
                'Dr\u00fccken Sie bitte die Leertaste um den Reiz zu bekommen.\n'...
                ];
            
        elseif nInstruct == 10%just before the shock
            text = ['Reiz kommt...\n'];
        elseif nInstruct == 11%this is the rating question
            text = ['Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?\n' ...
                'Bewegen Sie den "Zeiger" mit der rechten und linken Taste\n' ...
                'und best\u00e4tigen Sie Ihre Einsch\u00e4tzung mit der mit der Leertaste'...
                ];
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
            text = {'Sehr\nwahrscheinlich'};
        elseif nInstruct == 13
            text = {'\u00dcberhaupt\nnicht\nwahrscheinlich'};
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
        Screen('Preference', 'TextEncodingLocale','UTF-8');
        Screen('Preference', 'TextAntiAliasing',1);%enable textantialiasing high quality
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
        p.ptb.cross_shift           = [0 0];%[180 -120]./2.5;%incremental upper and lower cross positions
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%bb(1);%always the same
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2)+p.ptb.cross_shift;%bb(1);%always the same
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        p.ptb.fc_size               = 20;
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
            %             pause(0.1);
            %             outp(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
            %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            %             fprintf('1/ Red cable has to be connected to the Cogent BOX\n');
            %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            %             fprintf('2/ D2 Connection not to forget on the LPT panel\n');
            %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            %             fprintf('3/ Switch the SCR cable\n');
            %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            %             fprintf('4/ Button box has to be on\n');
            %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!sc!!!!!!!!\n');
            %             fprintf('5/ Did the trigger test work?\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\n\nPress V(alidate) to continue experiment or C to continue sending test pulses...\n')
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('Are you ready to go? Press V to start experiment!\n');
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            
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
    function [t]=StartEyelinkRecording(nTrial,nStim,phase)
        if EyelinkWanted
            t = [];
            nStim = double(nStim);
            Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, FILE: %04d', nTrial, phase, nStim);
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
            if nStim>0                
                Eyelink('ImageTransfer',p.stim.files24(nStim,:),p.ptb.imrect(1),p.ptb.imrect(2),p.stim.width,p.stim.height,p.ptb.imrect(1),p.ptb.imrect(2),0);
            end            
            %
            %drift correction
            %EyelinkDoDriftCorrection(el,crosspositionx,crosspositiony,0,0);
            %start recording following mode transition and a short pause.
            Eyelink('Command', 'set_idle_mode');
            WaitSecs(0.25);
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
            Eyelink('command', 'calibration_type = HV5');
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
