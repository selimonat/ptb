function [p]=exp_FearGen_DecisionMaking(subject,phase,csp,PainThreshold,CurrentGains,world)
%[p]=exp_FearGen_DecisionMaking(subject,phase,csp,PainThreshold,CurrentGains)
%
% !!! ISSUES TO SOLVE: first trial in eyelink and first pulse in CED are
% not recorded/
% Move StartTrial to the begninng of the experiment.
% preload kbcheck kbwait
%




debug         = 0;          %debug mode => 1: transparent window enabling viewing the background.
EyelinkWanted = 0;          %is Eyelink wanted?

if ~IsWindows               %replace parallel port function with a dummy function    
    %outp = @(x,y) 1;
end

if nargin ~= 6
    fprintf('Wrong number of inputs\n');
    return;
end

commandwindow;              %focus on the command window, so that output is not written on the editor
%clear everything
clear mex global functions; %clear all before we start.

if IsWindows                %clear cogent if we are in Windows and rely on Cogent for outp.
    cgshut;
    config_io
    global cogent;    
end
GetSecs;                    %load the GETSECS mex files so call them at least once
WaitSecs(0.001);
% init all the variables
el        = [];             %eye-tracker variable
p         = [];             %parameter structure that contains all info about the experiment.
s         = [];
t                         = [];
TimeEndStim               = [];
TimeStartShock            = [];
TimeTrackerOff            = [];
TimeCrossOn               = [];
ZeroPoint                 = [];
nTrial                    = 0;
p.var.event_count         = 0;
%
SetParams;                  %set parameters of the experiment
SetPTB;                     %set visualization parameters.
InitEyeLink;
KbQueueStop(p.ptb.device);
KbQueueRelease(p.ptb.device);
WaitSecs(2);
%
%%
%save again the parameter file
save(p.path.path_param,'p');
if phase == 1
    %
    p.mrt.dummy_scan = 0;%for the training we don't want any pulses
    p.var.ExpPhase = phase;
    %UCS check
%     ShowInstruction(4,1);
%     ConfirmIntensity;
    %test
%     ShowInstruction(1,1);
%     ShowInstruction(2,1);
    for ninst = [101]
        ShowInstruction(ninst,1);
    end
    PresentStimuli;    
elseif phase > 1
    %
    if EyelinkWanted
        CalibrateEL;    
        ShowInstruction(299,0,5);
    end
    %% Vormessung
    p.var.ExpPhase  = phase;%set this after the calibration;
%     k = 0;
%     while ~(k == p.keys.el_calib);
%         pause(0.1);
%         fprintf('Experimenter!! press V key when the vormessung is finished.\n');
%         [~, k] = KbStrokeWait(p.ptb.device);
%         k = find(k);
%     end
    fprintf('Continuing...\n');
    %%
    if phase == 2
        for ninst = [102]
            ShowInstruction(ninst,1);
        end
    elseif phase == 3
        for ninst = [103]
            ShowInstruction(ninst,1);
        end
    end
    PresentStimuli;
%     WaitSecs(2.5);
%     AskStimRating;%make sure that scanner doesnt stop prematurely asa the stim offset
%     if phase == 4
%         if EyelinkWanted
%             CalibrateEL;
%             AskDetection;
%         end
%         AskDetectionSelectable;
%     end
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
    function SetParams        
        p.participant.earning            = [];
        p.participant.earning_cumulative = CurrentGains;
        %% reward business        
        p.participant.reward_deserted    = 2;
        worlds                           = {4,8};
        p.participant.reward_inhabited   = worlds{world};
        p.participant.thief_punishment   = -4;
        p.participant.stimulus           = [];
        p.participant.response           = [];
        %mrt business
        p.mrt.dummy_scan              = 0;%this will wait until the 6th image is acquired.
        p.mrt.LastScans               = 0;%number of scans after the offset of the last stimulus
        p.mrt.tr                      = 1;%in seconds.
        %will count the number of events to be logged
        p.var.event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);        
        p.path.baselocation           = sprintf('%s/Documents/Experiments/FearGen_DecisionMaking/',homedir);
        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0
            mkdir(p.path.baselocation);
        end
        
        p.path.experiment             = [p.path.baselocation  filesep];
        if phase == 2 | phase == 3
            p.path.stim               = [fileparts(which('exp_FearGen_ForAll.m')) filesep 'bin' filesep 'FearGen_Instrumental' filesep];
        elseif phase == 1
            p.path.stim               = [fileparts(which('exp_FearGen_ForAll.m')) filesep 'bin' filesep 'FearGen_Instrumental_random' filesep];
        end
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
        p.text.fontsize                = 30;
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
        p.keys.confirm                 = KbName('UpArrow');%
        p.keys.increase                = KbName('RightArrow');
        p.keys.decrease                = KbName('LeftArrow');
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
        p.com.lpt.digitimer = 128;
        p.com.lpt.mBlock    = 32;
        p.com.lpt.StimOnset = 64;
        p.com.lpt.oddball   = 32;
        p.com.lpt.ucs       = 16;
        %%reset the sockets
        outp(p.com.lpt.address,0);
        %
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                   = 1.5;%2;%s
        p.duration.shock                  = 0.1;%s;x
        p.duration.shockpulse             = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse        = 0.01;%ms; and the time between each pulse
        p.duration.onset2shock            = p.duration.stim - p.duration.shock;
        p.duration.crossmoves             = p.duration.stim./2;
        p.duration.keep_recording         = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.prestim                = .85;
        p.duration.reward_screen_duration = 4;%seconds        
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
        %       
        p.stim.cs_plus                 = csp;%index of cs stimulus, this is the one paired to shock
        p.stim.cs_neg                  = mod( csp + 8/2-1, 8)+1;
        %% create the randomized design
        if phase == 1
            %%
            nrepeat                         = 1;
            RR                              = 0;
            SeqGen([1:8],nrepeat,RR);
        elseif phase == 2
            %%
            nrepeat                         = 8;
            RR                              = 1;
            SeqGen([p.stim.cs_plus p.stim.cs_neg],nrepeat,RR);                                                          
        elseif phase == 3
            %%
            nrepeat                         = 8;
            RR                              = 1;
            SeqGen([1:8],nrepeat,RR);
        end
        p.presentation
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
        function SeqGen(base_seq,nrepeat,RR)
            %%
            stim_perblock                   = length(base_seq);
            t_stim                          = nrepeat*stim_perblock;
            t_ucs                           = floor(nrepeat*RR);
            
            p.presentation.stim_id = [];
            for i = 1:nrepeat
                p.presentation.stim_id      = [p.presentation.stim_id Shuffle(base_seq)'];
            end                                                
            
            ucs_idx                         = Shuffle(find(p.presentation.stim_id == csp));
            ucs_idx                         = ucs_idx(1:t_ucs);
                        
            p.presentation.ucs              = zeros(1,length(p.presentation.stim_id));
            p.presentation.ucs(ucs_idx)     = 1;
            p.presentation.cond_id          = p.presentation.stim_id;
            p.presentation.cond_id(ucs_idx) = 9;
            
            p.presentation.isi              = RandSample([1:3]*p.mrt.tr, [1 t_stim]);
            p.presentation.time2reward      = RandSample([1:3]*p.mrt.tr, [1 t_stim]);
            
%             p.presentation.isi              = ceil(exprnd(4,[1 t_stim]));
%             p.presentation.time2reward      = ceil(exprnd(4,[1 t_stim]));
            
            p.presentation.mblock           = Vectorize(repmat([1:t_stim/stim_perblock],stim_perblock,1))';
            p.presentation.oddball          = zeros(1,t_stim);
            p.presentation.dist             = [MinimumAngle((p.presentation.stim_id-1)*45,(csp-1)*45)];
            p.presentation.cross_position   = repmat(2,[1,t_stim]);            
            
            p.presentation.tTrial           = length(p.presentation.cond_id);
            p.presentation.rr               = t_ucs/nrepeat;
            
            duration                        = sum(p.presentation.isi)+sum(p.presentation.time2reward)+t_stim*p.duration.reward_screen_duration+t_stim*p.duration.stim;
            duration2                       = sum(p.presentation.isi)+sum(p.presentation.time2reward)+t_stim*p.duration.reward_screen_duration+t_stim*.5;
            
                        
            fprintf('There are %d presentation of the CS+ face\n',t_stim);
            fprintf('There are %d UCS trials: Reinforcement rate is %f\n',t_ucs,t_ucs/nrepeat);
            
            fprintf('The duration of this phase is expected to last %d seconds %g minutes with the current stimulus duration...\n',duration,duration/60);
            fprintf('Otherwise %d seconds %g minutes assuming an average of .5 seconds reaction time...\n',duration2,duration2/60);
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
        p.ptb.screenNumber          =  1;%the maximum is the second monitor
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration(0,0.25);
%;
        end
        %set the resolution correctly
        res = Screen('resolution',p.ptb.screenNumber);
%         HideCursor(p.ptb.screenNumber);%make sure that the mouse is not shown at the participant's monitor
        %spit out the resolution,
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
%         [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg,[3840/2 0 3840 1200]);
        [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);%for transparency to work
        
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
                
        
        mid       = @(rect) [rect(3)-rect(1) rect(4)-rect(2)]/2;        %find midpoint
        midx      = @(rect) rect(1)+[rect(3)-rect(1)                ]/2;%find midpoint
        midy      = @(rect) rect(2)+[                rect(4)-rect(2)]/2;%find midpoint
        merge     = @(rect) [min(rect(:,1:2),[],1) max(rect(:,3:4),[],1)];%merge rects
        recenter  = @(rect,centerx,centery) rect + repmat([centerx centery]-mid(merge(rect)) , size(rect,1) ,2);%recenters rects 
        %find the mid position on the rect.
        p.ptb.midpoint              = mid(p.ptb.rect);
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.imrect                = [p.ptb.midpoint(1) - p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.ptb.midpoint(1)-p.stim.width/2+p.stim.width p.ptb.midpoint(2)-p.stim.height/2+p.stim.height];
        %% reward positions
        
        p.ptb.leftrect              =  p.ptb.imrect      - [p.stim.width 0 p.stim.width 0 ];
        p.ptb.rightrect             =  p.ptb.imrect      + [p.stim.width 0 p.stim.width 0 ];
        
        tiles                       =  RectMatrix(100,0, 4, p.participant.reward_deserted );
        p.ptb.leftrewardrect        =  recenter(tiles,midx(p.ptb.leftrect),midy(p.ptb.leftrect));

        tiles                       =  RectMatrix(100,0, 4, p.participant.reward_inhabited );
        p.ptb.rightrewardrect       =  recenter(tiles,midx(p.ptb.rightrect),midy(p.ptb.rightrect));
                
        %%
        p.ptb.cross_shift           = [180 -120]./2.5;%incremental upper and lower cross positions
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%bb(1);%always the same
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2)+p.ptb.cross_shift;%bb(1);%always the same
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        p.ptb.fc_size               = 10;
        %
        fix                         = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(1)];
        p.ptb.FixCross{1}           = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        fix                         = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(2)];%take the other position        
        p.ptb.FixCross{2}           = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
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
        fprintf('\n');
        fprintf('Key listening will be restricted to:');
        fprintf('%d, ',p.ptb.keysOfInterest);
        fprintf('\n');
        RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        p.ptb.keysToMonitor                                      = zeros(256,1);
        p.ptb.keysToMonitor(p.ptb.keysOfInterest)                = 1;
        p.ptb.keysForResponse                                    = zeros(256,1);
        p.ptb.keysForResponse([p.keys.increase p.keys.decrease]) = 1;
        %create a queue sensitive to only relevant keys.        
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
        [p.ptb.stim_sprites p.ptb.valley_sprites p.ptb.reward_sprites] = CreateStimSprites(p.stim.files);%        
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
        function [out out2 out3 out4]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:size(files,1)
                filename       = files(nStim,:);
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
            
            valley_path    = [fileparts(which('exp_FearGen_ForAll.m')) filesep 'bin' filesep 'FearGen_Instrumental' filesep];
            [im , ~, ~]    = imread([valley_path 'InhabitedValley.jpg']);
            out2(1)        = Screen('MakeTexture', p.ptb.w, im );
            
            [im , ~, ~]    = imread([valley_path 'DesertedValley.jpg']);
            out2(2)        = Screen('MakeTexture', p.ptb.w, im );
                        
            [im , ~, alpha] = imread([valley_path 'RewardToast.png']);
            im              = cat(3,im,alpha);
            out3(1)         = Screen('MakeTexture', p.ptb.w, im );
                        
        end
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
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und best�tige deine Einsch�tzung mit der oberen Pfeiltaste.';
        rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
        response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nertr�glich' 'ertr�glich'},message,0);
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
        [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);
        
        %start the queue for logging
        Queue('start');
        %If the scanner by mistake had been started prior to this point
        %those pulses would have been not logged.
        
        %take the first valid pulse the zero point
        ZeroPoint     = secs(end)- p.ptb.slack;
        
        RunTrials;
        
        %wait again for the BOLD/SCR/Pupil signal to come back to the baseline...
        if p.var.ExpPhase > 0
            WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%
            fprintf('OK!! Stop the Scanner\n');
        end                  
        Queue('stop')       
    end    
    function RunTrials
        %show one trial after another.
        
        for nTrial  = 1:p.presentation.tTrial;            
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            fix_y        = p.presentation.cross_position(nTrial);
            ISI          = p.presentation.isi(nTrial);
            ucs          = p.presentation.ucs(nTrial);
            oddball      = p.presentation.oddball(nTrial);
            prestimdur   = p.duration.prestim;
            dist         = p.presentation.dist(nTrial);            
            time2reward  = p.presentation.time2reward(nTrial);
            %
            OnsetTime    = ZeroPoint + ISI;            
                        
            fprintf('%03d of %03d, S: %d, ISI: %d, UCS: %d, ODD: %d, OnsetTime: %f secs, ',nTrial,p.presentation.tTrial,stim_id,ISI,ucs,oddball, OnsetTime);
            
            %Start with the trial, here is time-wise sensitive must be optimal
            [ZeroPoint]  = Trial(nTrial,OnsetTime, prestimdur, stim_id , ucs  , fix_y,  oddball, dist, time2reward);
            %zeropoint is the time of reward screen offset.
            
            %(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist )
            fprintf('OffsetTime: %f secs, Difference of %f secs\n',ZeroPoint,ZeroPoint-OnsetTime-p.duration.stim);
               
        end
    end
    function [ZeroPoint]=Trial(nTrial, TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist, time2reward)        
        %% compute time of different events
        keyCode            = [];        
        TimeCrossOnset     = TimeStimOnset    - prestimdur;
        TimeStimOffset     = TimeStimOnset    + p.duration.stim;
        TimeStartReward    = TimeStimOffset   + time2reward;        
        TimeEndReward      = TimeStartReward  + p.duration.reward_screen_duration;
        TimeStartShock     = TimeStartReward;
        TimeEndShock       = TimeStartReward  + p.duration.shock;
        %%
        if  phase == 1      %valley exploration
            ShowFace(1)
            RecordResponses()
            Feedback()
        elseif phase == 2   %sibling learning
            %passive stage, no key press required.
            ShowFace(0);%show face without valleys            
            ClearScreenAt(TimeStimOffset);
            UCS(ucs);
        elseif phase == 3   %combination
            ShowFace(1);
            RecordResponses();            
            Feedback();
        end
        ZeroPoint = GetSecs;        
        %%
        function ClearScreenAt(ThisTime)
            %turns screen off at THISTIME
            Screen('Flip',p.ptb.w,ThisTime,0);
        end
        function ShowFace(withvalleys)          
            %show prestimulus cross, face and valley if required
            Screen('FillRect'       ,p.ptb.w, p.stim.bg    );                        %create a gray background
            Screen('FillRect'       ,p.ptb.w, [255,255,255], p.ptb.FixCross{fix_i}');%draw the prestimus cross atop
            TimeCrossOnset          = Screen('Flip',p.ptb.w,TimeCrossOnset,0);       %     
            %
            Screen('DrawTexture'    , p.ptb.w, p.ptb.stim_sprites(stim_id),[],p.ptb.imrect);            
            if withvalleys
                 ShowValleys()
            end
            TimeStimOnset            = Screen('Flip',p.ptb.w,TimeStimOnset,0);       %asap and dont clear
            %
            Log(TimeCrossOnset, 1 ,fix_i);                                           %actual cross onset.
            Log(TimeStimOnset , 2 ,dist);                                            %log the stimulus onset
            
            function ShowValleys()
                %%
                Screen('DrawTexture'    , p.ptb.w, p.ptb.valley_sprites(1),[],p.ptb.rightrect);
                Screen('DrawTexture'    , p.ptb.w, p.ptb.valley_sprites(2),[],p.ptb.leftrect);
                %draw arrows
                Screen('DrawLine'       , p.ptb.w,[],p.ptb.leftrect(3),p.ptb.leftrect(2),p.ptb.leftrect(3)-200,p.ptb.leftrect(2)+200,7);
                Screen('DrawLine'       , p.ptb.w,[],p.ptb.leftrect(3)-200,p.ptb.leftrect(2)+200,p.ptb.leftrect(3),p.ptb.leftrect(4),7);
                Screen('DrawLine'       , p.ptb.w,[],p.ptb.rightrect(1),p.ptb.rightrect(2),p.ptb.rightrect(3)-200,p.ptb.rightrect(2)+200,7);
                Screen('DrawLine'       , p.ptb.w,[],p.ptb.rightrect(3)-200,p.ptb.rightrect(2)+200,p.ptb.rightrect(1),p.ptb.rightrect(4),7);
                %draw frames
                Screen('FrameRect'      , p.ptb.w, [255 255 255 .3] , p.ptb.leftrect,5);
                Screen('FrameRect'      , p.ptb.w, [255 255 255 .3] , p.ptb.rightrect,5);                
            end
        end
        function RecordResponses()            
            
            Screen('FillRect'   , p.ptb.w, p.stim.bg    , p.ptb.imrect );
            % Record key presses related to the valley selection
            while 1
                [ keyIsDown, secs, keyCode ] = KbCheck;
                if keyIsDown                   
                    if keyCode(p.keys.increase) | keyCode(p.keys.decrease)
                        break;
                    end                    
                end
            end            
            %turn screen off            
            TimeStimOffset = Screen('Flip',p.ptb.w);
            
            %log keypress and stim offset
            Log(TimeStimOffset , -2 ,dist);
            Log(secs,5,find(keyCode));
            % register responses
            p.participant.stimulus = [p.participant.stimulus dist         ];
            if find(keyCode) == p.keys.decrease %left
                p.participant.response = [p.participant.response 0];
                fprintf('Participant selected the deserted valley.\n',find(keyCode))
            else
                p.participant.response = [p.participant.response 1];
                fprintf('Participant selected the inhabited valley.\n',find(keyCode))
            end
            
            for stim = [-135:45:180]
                R = p.participant.response(p.participant.stimulus == stim);                
                fprintf('Face %04d (%03d): Mean: %3.5g, Responses: %s \n',stim,length(R),mean(R),mat2str(R))                
            end
            fprintf('Current number of foods owned by the participant: %05d\n',p.participant.earning_cumulative(end))
            
            %update time for reward screens
            TimeStartReward    = secs             + time2reward;
            TimeEndReward      = TimeStartReward  + p.duration.reward_screen_duration;
            TimeEndShock       = TimeStartReward  + p.duration.shock;
        end        
        function Feedback()
            %show the feedback screen, deliver UCS if necessary, update the
            %Bank.
            if keyCode(p.keys.increase) %% inhabited valley     
                if ucs
                   UCS(ucs);
                   return;
                else
                   DrawReward([255 255 255],5,.3,[0 255 0],25,1);
                   message=Earnings(p.participant.reward_inhabited,'Inhabited');                    
                end
            elseif keyCode(p.keys.decrease) %% uninhabited valley                
                DrawReward([0 255 0],25,1,[255 255 255],5,.3);
                message=Earnings(p.participant.reward_deserted,'Deserted');
            end            
            DrawFormattedText(p.ptb.w,message, 'center', 50,  [],[],[],[],2);
            Bank('gain');
            
            TimeStartReward  = Screen('Flip',p.ptb.w,TimeStartReward,0);%asap and dont clear             
            TimeEndReward    = Screen('Flip',p.ptb.w,TimeEndReward,0);
            
            Log(TimeStartReward, 3, dist);
            Log(TimeEndReward  ,-3, dist);
                                    
            function DrawReward(uColor,uThickness,uOpacity,iColor,iThickness,iOpacity)
                
                Screen('FrameRect'  , p.ptb.w, uColor , p.ptb.leftrect,uThickness);
                Screen('FrameRect'  , p.ptb.w, iColor , p.ptb.rightrect,iThickness);
                
                for n=1:p.participant.reward_deserted
                    Screen('DrawTexture', p.ptb.w, p.ptb.reward_sprites,[],p.ptb.leftrewardrect(n,:),[],[],uOpacity);
                end
                
                for n=1:p.participant.reward_inhabited
                    Screen('DrawTexture', p.ptb.w, p.ptb.reward_sprites,[],p.ptb.rightrewardrect(n,:),[],[],iOpacity);
                end                
            end                        
        end           
        function UCS(ucs)
            %TimeEndReward    = TimeStartReward + 4;            
            if ucs                
                TimeStartShock = WaitSecs('UntilTime',TimeStartReward);
                while GetSecs < TimeEndShock;
                    Buzz;%this is anyway sent to CED.
                end
                % message  = sprintf('Du bist dem Dieb begegnet, der dir einen Teil deiner Essenvorr�te geklaut hat.\nVERDIENT: %.2f Essensrationen.\n: GESAMTER ESSENSVORRAT:%.2f Essensrationen.',valley_type, p.participant.earning(end),p.participant.earning_cumulative(end));
                [message]=Earnings(p.participant.thief_punishment,'');
                %
                Bank('loss');
                DrawFormattedText(p.ptb.w,message, 'center', 'center',  [],[],[],[],2);
                TimeStartReward  = Screen('Flip',p.ptb.w,TimeStartReward,0);%asap and dont clear             
                TimeEndReward    = Screen('Flip',p.ptb.w,TimeEndReward,0);
                %
                Log(TimeStartShock ,-4, NaN);
                Log(TimeStartShock , 4, NaN);
                Log(TimeStartReward, 3, dist);
                Log(TimeEndReward  ,-3, dist);
            end
        end
        function [message]=Earnings(reward,valley_type)            
            p.participant.earning            = [p.participant.earning reward];
            p.participant.earning_cumulative = [p.participant.earning_cumulative p.participant.earning_cumulative(end) + p.participant.earning(end)];
            if reward > 0                
                message  = sprintf('Du hast dich f�r das: %s Tal entschieden.\nVERDIENT: %d Essensrationen.\nGESAMTER ESSENSVORRAT: %d Essensrationen.',valley_type, p.participant.earning(end),p.participant.earning_cumulative(end));
            else
                message  = sprintf('Du bist dem Dieb begegnet, der dir einen Teil deiner Essenvorr�te gestohlen hat.');
            end
        end        
        function Bank(gainORloss)
            %%
            p.ptb.bar_width   = 60;
            p.ptb.bar_height  = 4;
            p.ptb.bar_hspace  = 10;
            p.ptb.bar_vspace  = 1;
            rects            = [];
            for nbar = 0:max(p.participant.earning_cumulative(end-1:end))-1
                rects = [rects [p.ptb.rect(3)-p.ptb.bar_width-p.ptb.bar_hspace  ...
                    p.ptb.rect(4)-(p.ptb.bar_vspace+p.ptb.bar_height)*nbar ...
                    p.ptb.rect(3)-p.ptb.bar_hspace ...
                    p.ptb.rect(4)-(p.ptb.bar_vspace+p.ptb.bar_height)*nbar-p.ptb.bar_height]'];
            end
            
            if strcmp(gainORloss,'gain');
                new     = round(p.participant.earning(end));
                old     = round(p.participant.earning_cumulative(end-1));
                colors  = [repmat([255;255;255],1,old) repmat([0;255;0],1,new)];
            else strcmp(gainORloss,'loss');
                new     = abs(round(p.participant.earning(end)));
                old     = round(p.participant.earning_cumulative(end));
                colors = [repmat([255;255;255],1,old) repmat([255;0;0],1,new)];
            end
            %            
            Screen('FillRect'       ,p.ptb.w, colors, rects);%draw the prestimus cross atop
        end        
        %% compute times for all events
        mblock_id          = 0;                
                   
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
    function [rating,time_RatingOff] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
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
                    time_RatingOff=Screen('Flip',p.ptb.w);
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
    function [t]                     = ShowInstruction(nInstruct,waitforkeypress,varargin)
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
    function [text]                  = GetText(nInstruct)
        if nInstruct == 0%Eyetracking calibration
            
            text = ['Wir kalibrieren jetzt den Eye-Tracker.\n\n' ...
                'Bitte fixieren Sie die nun folgenden wei�en Kreise und \n' ...
                'bleiben so lange darauf, wie sie zu sehen sind.\n\n' ...
                'Nach der Kalibrierung d�rfen Sie Ihren Kopf nicht mehr bewegen.\n'...
                'Sollten Sie Ihre Position noch ver�ndern m�ssen, tun Sie dies jetzt.\n'...
                'Die beste Position ist meist die bequemste.\n\n'...
                'Bitte dr�cken Sie jetzt den oberen Knopf, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
            
        elseif nInstruct == 1%first Instr. of the training phase.
            text = ['Wir werden nun als erstes einen �bungsdurchgang machen,\n' ...
                'damit Sie sich an Ihre Aufgabe gew�hnen k�nnen.\n' ...
                'In diesem Durchgang k�nnen Sie sich vollkommen sicher f�hlen,\n' ...
                'es werden keine elektrischen Reize verabreicht.\n' ...
                'Eine wichtige grunds�tzliche Regel ist, dass Sie das Fixationskreuz (das +)\n' ...
                'wenn es zu sehen ist, mit Ihren Augen fixieren. \n' ...
                '\n'...
                'Dr�cken Sie die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 2%second Instr. of the training phase.
            text = ['Ein paar Bemerkungen zu den Zielreizen: \n' ...
                'Zur Erinnerung: Zielreize sind die verschwommenen Gesichter.\n' ...
                'Sobald ein solcher Zielreiz erscheint, \n' ...
                'sollen Sie schnellstm�glich die obere Taste dr�cken, \n' ...
                'und zwar bevor der Zielreiz wieder verschwunden ist \n' ...
                '(Sie m�ssen also sehr schnell und aufmerksam sein).\n\n' ...
                'Dr�cken Sie die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 299%short instruction before localizer
            text = ['Die Kalibrierung war erfolgreich.\n'...
                'Es startet nun eine kurze Vormessung (~2 min), w�hrend der Sie nichts tun m�ssen.\n\n'...
                ];
        elseif nInstruct == 3%third Instr. of the training phase.
            text = ['Wir sind jetzt kurz vor Beginn des Experiments.\n'...
                'Wir m�chten Sie nun noch einmal an die wichtigsten Punkte erinnern.\n\n'...
                'Dr�cken Sie jeweils die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 301%third Instr. of the training phase.
            text = ['Remember:\n There are ~2 times more food in the inhabited valley\nthan the deserted valley.'...
                ];
        elseif nInstruct == 302%third Instr. of the training phase.
            text = ['You will first see who is currently present in the inhabited valley.\n We will then ask you in which valley you would prefer to seek for food.'...
                ];
        elseif nInstruct == 303%third Instr. of the training phase.
            text = ['3/ Bewegen Sie sich nicht.\n'...
                ];
        elseif nInstruct == 304%third Instr. of the training phase.
            text = ['4/ Lassen Sie sich vom Scannergeschehen nicht st�ren.\n'...
                ];
        elseif nInstruct == 305%third Instr. of the training phase.
            text = ['5/ Nur eines der Gesichter wird mit elektrischen Reizen gepaart.\n'...
                ];
        elseif nInstruct == 306%third Instr. of the training phase.
            text = ['Dr�cken Sie jetzt die obere Taste, das Experiment startet dann in wenigen Sekunden.\n' ...
                ];
            
            
        elseif nInstruct == 4%third Instr. of the training phase.
            text = ['Vor dem Experiment legen wir nun \n' ...
                'die Schockintensit�t f�r den Rest des Experiments fest. \n' ...
                'Dr�cken Sie die obere Taste um fortzufahren.\n' ...
                ];
            
        elseif nInstruct == 7;%rating
            text = ['In dieser Phase h�tten wir gerne, dass Sie die Gesichter\n'...
                'im Hinblick auf folgende Frage bewerten:\n'...
                '"Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?"\n'...
                'Bewegen Sie den Zeiger mit der rechten und linken Taste\n'...
                'und best�tigen Sie Ihre Einsch�tzung mit der oberen Taste.\n'...
                ];
        elseif nInstruct == 8;%AskDetectionSelectable
            text = ['Sie sehen nun noch einmal eine �bersicht der verschiedenen Gesichter.\n'...
                'Bitte geben Sie an, welches der Gesichter Ihrer Meinung nach\n mit dem Schock gepaart wurde.\n\n'...
                'Nutzen Sie die linke und rechte Taste, um die Markierung\n zum richtigen Gesicht zu navigieren,\n'...
                'und dr�cken Sie die obere Taste zum Best�tigen.\n\n'...
                'Bitte zum Starten die obere Taste dr�cken.\n'...
                ];
        elseif nInstruct == 801;%AskDetectionSelectable
            text = ['Sie sehen nun eine �bersicht der verschiedenen Gesichter.\n'...
                'Bitte schauen Sie sich die Gesichter aufmerksam an.\n'...
                'Bitte dr�cken Sie zum Start die obere Taste und\n' ...
                'fixieren Sie das anschlie�end erscheinende Fixationskreuz.\n'...
                ];
            
        elseif nInstruct == 9%
            %=================================================================================================================%
            text = ['Bitte geben Sie an, ob die Reizst�rke des folgenden Schocks\n f�r Sie ertr�glich ist.\n'...
                '\n'...
                'Dr�cken Sie bitte die obere Taste um den Reiz zu bekommen.\n'...
                ];
            
        elseif nInstruct == 10%just before the shock
            text = ['Reiz kommt...\n'];
        elseif nInstruct == 11%this is the rating question
            text = ['Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?\n' ...
                'Bewegen Sie den "Zeiger" mit der rechten und linken Taste\n' ...
                'und best�tigen Sie Ihre Einsch�tzung mit der mit der oberen Taste'...
                ];
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
            text = {'Sehr\nwahrscheinlich'};
        elseif nInstruct == 13
            text = {'�berhaupt\nnicht\nwahrscheinlich'};
        elseif nInstruct == 111
            text = ['Please select now where you would like to forage for food.'];
        elseif nInstruct == 122 %These two below are the possible responses to the question in 11
            text = {'Deserted\nValley'};
        elseif nInstruct == 133
            text = {'Inhabited\nValley'};    
            
        elseif nInstruct == 14
            text = ['Danke. Den aktiven Teil des Experiment haben Sie nun geschafft.\n'...
                'Es folgt nun noch eine strukturelle Messung, die ca. 7 Minuten dauert.\n'...
                'Sie k�nnen dabei ruhig die Augen schlie�en und sich entspannen.\n'];
        elseif nInstruct == 101
            text = ['Auskundschaften der T�ler\n'...
                'Bitte w�hle mit der linken oder rechten Pfeiltaste aus in welchem Tal \n' ... 
                '(Bewohntem oder Verlassenem)\n'...
                'du gerne nach Essen suchen w�rdest.\n' ...
                'Die Person, der du im bewohnten Tal begegnen w�rdest\n' ...
                'wird auch angezeigt.\n'];;
        elseif nInstruct == 102
             text = ['Kennenlernen der Talbewohner\n'...
                     'Du wirst nun den Talbewohnern, die gerade im bewohnten Tal\n'...
                     'unterwegs sind begegnen.\n'...
                     'Einer dieser Bewohner ist ein Dieb und eine Begegnung mit ihm\n' ...
                     'resultiert in einem Schock UND einem Verlust an Essen\n' ...
                     'In diesem Durchgang m�ssen keine Tasten gedr�ckt werden.\n'...
                      ];       
        elseif nInstruct == 103
            text = [ 'Bitte w�hle mit der linken oder rechten Pfeiltaste aus in welchem Tal \n' ... 
                 '(Bewohntem oder Verlassenem)\n'...
                 'du gerne nach Essen suchen w�rdest.\n' ...
                 'Die Person, der du im bewohnten Tal begegnen w�rdest\n' ...
                 'wird auch angezeigt.\n'];
        else
            text = {''};
        end
    end
    
    function [t]                     = StopEyelinkRecording
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
    function [t]                     = StartEyelinkRecording(nTrial,nStim,phase,dist,oddball,ucs,fix,block_id)
        if EyelinkWanted
            t = [];
            if isnan(dist)
                dist=3000;
            end
            nStim = double(nStim);
            fix_x = p.ptb.CrossPosition_x;
            fix_y = p.ptb.CrossPosition_y(fix);
            Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, FILE: %04d, DELTACSP: %04d, ODDBALL: %04d, UCS: %04d, FIXX: %04d, FIXY %04d, MBLOCK %04d', nTrial, phase, nStim, dist, double(oddball), double(ucs),fix_x,fix_y,block_id);
            Eyelink('Message', 'FX_ONSET %d %d',fix_x,fix_y);
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
            Eyelink('Command', 'draw_cross %d %d 15',fix_x,fix_y);
%             Eyelink('Command', 'draw_cross %d %d 15',fix_x,fix(2)+diff(p.ptb.cross_shift));%not clear to me why this always works
            
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
            fprintf('\n=================\n=================\nEntering Eyelink Calibration\n')
            p.var.ExpPhase  = 0;
            ShowInstruction(0,1);
            EyelinkDoTrackerSetup(el);
            %Returns 'messageString' text associated with result of last calibration
            [~, messageString] = Eyelink('CalMessage');
            Eyelink('Message','%s',messageString);%
            WaitSecs(0.05);
            fprintf('\n=================\n=================\nNow we are done with the calibration\n')
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
        %Reward Onset         :     3/-3
        %Cross Onset          :     1/-1    info: position
        %Stimulus Onset       :     2/-2    info: dist_id        
        %UCS Delivery         :     4/-4    info: NaN;        
        %Key Presses          :     5    info: NaN;                
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
        function D=rad2deg(R)
            D = R*180/pi;
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
    function Queue(do)        
        if strcmp(do,'start')
            %starts queue
            KbQueueStop(p.ptb.device);
            WaitSecs(.05);
            KbQueueCreate(p.ptb.device,p.ptb.keysToMonitor);
            KbQueueStart(p.ptb.device);%this means that from now on we are going to log pulses.
        elseif strcmp(do,'stop')
            %stop the queues
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
        end
    end
    function DumpLogQueue
        %dumps the queue.
        
        [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
        
        %log everything but "pulse keys" as pulses, not as keypresses.
        pulses = (keycode == p.keys.pulse);
        if any(~pulses);%log keys presses if only there is one
            Log(secs(~pulses),7,keycode(~pulses));
        end
        if any(pulses);%log pulses if only there is one
            Log(secs(pulses),0,keycode(pulses));
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

    function r = exprnd(mu,varargin)       
        
        
        if nargin < 1
            error(message('stats:exprnd:TooFewInputs'));
        end
        
        [err, sizeOut] = statsizechk(1,mu,varargin{:});
        if err > 0
            error(message('stats:exprnd:InputSizeMismatch'));
        end
        
        % Return NaN for elements corresponding to illegal parameter values.
        mu(mu < 0) = NaN;
        
        % Generate uniform random values, and apply the exponential inverse CDF.
        r = -mu .* log(rand(sizeOut, 'like', mu)); % == expinv(u, mu)
    end

end
