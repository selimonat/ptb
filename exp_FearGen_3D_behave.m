function [p] = exp_FearGen_3D_behave(subject,phase,cspNum,PainThreshold)
%function [p] = exp_FearGen_3D_behave(subject,phase,cspNum,nstim,PainThreshold)
%
%credit: Basically an adapted version of Selim Onat's script: "exp_FearAmy.m"
%minus the MRI part
%is supposed to run the experiment FearGen_3D, using facial stimuli that
%differ on three dimensions to see how conditioned fear responses
%generalize along these dimensions.
%
%expected input:
%   subject:    running number of subject. will complain if you try to use
%               the same number more than once using the same
%               scenario(considering eyelink and mrt)
%
%   phase:      where to start the experiment.     
%
%   cspNum:     which stimulus is the cs+? Uses position of the cs+ in the 
%               sequence, not the actual number of it. So if face no. 4 is 
%               what you want and it is the first selected CS+ (not all are 
%               eligible). This is especially important since we're not 
%               using all stimuli for each subject
%   
%   PainThreshold: Output from exp_PainThreshold. Indicates the strength of
%                  electrical current that is being perceived as painful in
%                  50 % of trials by subjects.
%
%Differences to exp_FearAmy:
%   1
%   Stimuli are not on a circle, but on a sphere. Thus, the presentation of
%   stimuli in the end has to be different and is a grid of 16 or 20
%   faces(depending on stimlist)
%   2
%   Ratings are not only in the end, but there are "online" ratings every
%   five microblocks. This is to analyze the temporal modulation of the
%   explizit generalization gradient. 
%   3
%   kicked out the MRI stuff for behavioral piloting in the eyelab
%
%WHILE PROGRAMMING PRESS CTRL*F AND SEARCH FOR "PLATZHALTER" TO LOOK FOR
%UNSOLVED ISSUES
%% handle arguments/general preparations
debug   = 1; %debugging mode uses a transparant window among other things
pilot   = 1; %indicate piloting - will save in another folder
p = [];
    
if debug
    [subject,p.exp.cspNum,cspNum,p.exp.phase,PainThreshold]  = deal(randi(8));
    [el]      = deal([]);
     p.nstim     = 32;
    [p.exp.phase,phase] = deal(0);
elseif ~debug    
    p.exp.phase     = phase;
    p.exp.cspNum    = cspNum;
    p.nstim     = 32;
end

%since parallel port communication is (kind of) relying on cogent:
cgshut;
global cogent;

clear mex global functions;
commandwindow;

%call GETSECS mex-file for quicker use later on.
GetSecs;
WaitSecs(0.001);

%% Run first level functions depending on arguments

SetParams; %preallocate variables, define stuff, etc.
SetPTB; %initialize stuff for the visual presentation part of the experiment

%for now just copy all the stuff and l8er kick out what's not needed
%init all the variables
t                         = [];
nTrial                    = 0;
%Time Storage
TimeEndStim               = [];
TimeStartShock            = [];
TimeTrackerOff            = [];
TimeCrossOn               = [];

if eyelab
    InitEyeLink; %Get the eye tracker running and set the parameters for it
end

WaitSecs(2);
KbQueueStop(p.ptb.device);
KbQueueRelease(p.ptb.device);
save(p.path.path_param,'p');
    
if phase == 0
    p.var.ExpPhase = phase;
    %UCS check
    ShowInstruction(4,1);
    ConfirmIntensity;
    %test
    ShowInstruction(1,1);
    ShowInstruction(2,1);
    PresentStimuli;
elseif phase == 1
    if eyelab
        CalibrateEL;
    end
    p.var.ExpPhase  = phase;%set this after the calibration;
%     ShowInstruction(299,0,5);    %this is the Vormessung stuff which we
%     won't need for the behavioral pilot
%     % Vormessung
%     k = 0;
%     while ~(k == 25 || k == 86 );
%             pause(0.1);            
%             fprintf('Experimenter!! press V key when the vormessung is finished.\n');
%             [~, k] = KbStrokeWait(p.ptb.device);
%             k = find(k);
%     end        
    fprintf('Continuing...\n');
    for ninst = [3 301:305]
        ShowInstruction(ninst,1);
    end
    PresentStimuli;
    WaitSecs(2.5);
    AskStimRating(5);
    if eyelab
        CalibrateEL;
    end
    AskDetectionSelectable;    
end

if eyelab
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

p.path.tarname = [p.path.finalsubject(1:end-1) '.tar'];
tar(p.path.tarname,p.path.finalsubject);
fprintf('Don''t forget to copy the data to neuronas including SCR and Eyelinkdata ');
cleanup;

%% Define first level functions


    function [] = SetParams
        %will count the number of events to be logged
        p.var.event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]   = system('hostname');
        p.hostname      = deblank(hostname);
        
        %stimulus pc in eyetracking lab or Lukas' computer - change it to
        %the desired directory if you use another computer for this script
        if strcmp(p.hostname,'isnfc3fd8824cfb');
            p.path.baselocation     = 'C:\Users\neugebauer\Documents\Experiments\FearGen';
            eyelab                  = 0; %logical indicating wether you'll use an eyetracker or not to avoid error messages 
        elseif strcmp(p.hostname,'etpc');
            p.path.baselocation     = 'C:\Users\neugebauer\Experiments\FearGen';
            eyelab                  = 1;
        end
        p.path.experiment   = [p.path.baselocation,filesep];
        p.path.bin          = [fileparts(which('exp_FearGen_3D_behave.m')),filesep,'bin',filesep];
        p.path.stim         = [p.path.bin,'Stimuli_FearGen_3D',filesep];        
        p.path.stim24       = [p.path.stim,'24bit',filesep];
        p.path.stim_cut     = [p.path.stim,'cut',filesep];
        p.subID             = sprintf('s%02d',subject);
        timestamp           = datestr(now,30);
        p.path.subject      = [p.path.experiment,'tmp',filesep,p.subID,'_',timestamp,filesep];
        p.path.finalsubject = [p.path.experiment,p.subID,'_',timestamp,filesep ];
        p.path.path_edf     = [p.path.subject,'eye',filesep];
        p.path.edf          = sprintf([p.subID,'p%02d.edf' ],phase);
        p.path.path_param   = [p.path.subject,'stimulation',filesep,'data.mat'];
        
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject,'scr']);
        mkdir([p.path.subject,'eye']);
        mkdir([p.path.subject,'stimulation']);
        mkdir([p.path.subject,'midlevel']);
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load stimulus sequence, define some relevant things
        if phase == 0
            seq(subject,cspNum).cond_id         = Shuffle([datasample(0:p.nstim,p.nstim/2,'Replace',false),p.nstim+1]);
            seq(subject,cspNum).tTrial          = length(seq(subject,cspNum).cond_id);
            seq(subject,cspNum).ucs             = zeros(1,seq(subject,cspNum).tTrial);
            seq(subject,cspNum).oddball         = seq(subject,cspNum).cond_id == p.nstim+1;
            seq(subject,cspNum).isi             = PsychRandSample([3 4.5],[1 seq(subject,cspNum).tTrial]);
            seq(subject,cspNum).stim_id         = seq(subject,cspNum).cond_id;
            seq(subject,cspNum).dist            = 1:seq(subject,cspNum).tTrial;
            seq(subject,cspNum).CrossPosition   = ones(1,seq(subject,cspNum).tTrial);
            seq(subject,cspNum).mblock          = ones(1,seq(subject,cspNum).tTrial);
            seq(subject,cspNum).stimlist        = unique(seq(subject,cspNum).stim_id);
            seq(subject,cspNum).dist2csp        = randi(10,size(seq(subject,cspNum).stimlist));
        elseif phase == 1
            load([fileparts(which('exp_FearGen_3D.m')),filesep,'bin',filesep,'sequences_FearGen_3d.mat']);
        end
        
        %elements indicating special events
        p.stim.oddballID    = p.nstim + 1;
        p.stim.ucsID        = 99;
        p.stim.nullID       = 0;
        
        %this will deal all the presentation sequence related information
        p.presentation  = seq(subject,p.exp.cspNum);
        clear seq;      
        p.stim.stimID   = unique(p.presentation.stim_id);
        p.stim.stimID   = p.stim.stimID(~ismember(p.stim.stimID,[p.stim.ucsID,p.stim.nullID]));    
        p.stim.stimIndex    = [p.stim.stimID',(1:numel(p.stim.stimID))'];
        
        %frequency of ratings - will be asked more frequently than before
        %define how often this should be the case
        p.presentation.rating   = zeros(size(p.presentation.mblock));
        
        if phase == 1
            p.stim.rateFreq     = 7; %let's say every 10 microblocks
            nMicro              = max(p.presentation.mblock); %how many microblocks are there?
            rateIndMicro        = p.stim.rateFreq:p.stim.rateFreq:nMicro;
            %don't ask for rating within the last few microblocks
            if nMicro - rateIndMicro(end) < 5
                rateIndMicro(end) = [];
            end
            trialPerBlock       = sum(p.presentation.mblock == 1);
            rateIndTrial        = rateIndMicro * trialPerBlock;
            if debug
                rateIndTrial    = [5 rateIndTrial];
            end
            p.presentation.rating(rateIndTrial)     = 1;
            p.out.rating_seq.phase1     = [];
            p.out.pos1_seq.phase1       = [];
            p.var.ratingCount           = 0; %count ratings for indexing in output structure
        end
        
        %get stim files - important addition: only take the stimuli that
        %are needed.
        [p.stim.files,p.stim.label]   = FileMatrix([p.path.stim '*.bmp']);
        [p.stim.files_cut,p.stim.label_cut]   = FileMatrix([p.path.stim_cut '*.bmp']);
        usedNames   = cell(numel(p.stim.stimID),1); %which stimuli are being used for the respective CSP
        for s = 1:numel(p.stim.stimID)
            usedNames{s}  = sprintf('%03d.bmp',p.stim.stimID(s));
        end
        usedIndex   = ismember(p.stim.label,usedNames);
        [p.stim.files,p.stim.label]   = deal(p.stim.files(usedIndex,:),{p.stim.label{usedIndex}});
        p.stim.tFile                  = size(p.stim.files,1);%number of different files (including the oddball face)
        p.stim.tFace                  = numel(p.stim.stimID);%number of faces.
        clear usedNames usedIndex;
        
        %which is the number of the CSP?
        p.stim.cs_plus      = p.presentation.stim_id(find(p.presentation.ucs,1));
        disp([mat2str(p.stim.tFile) ' kept for usage.']);
        
        %set the background gray according to the background of the stimuli
        bg      = zeros(p.stim.tFace,1);
        for i = 1:p.stim.tFace
            im                        = imread(p.stim.files(i,:));
            bg(i)                     = im(1,1,1);
        end
        %is all the captured bg values the same?
        if sum(diff(bg))==0
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
        %rating business
        p.rating.division              = 10;%number of divisions for the rating slider
        %% get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        clear info;
        %% keys to be used during the experiment
        KbName('UnifyKeyNames'); %use generalized nomenclature for keys
        
        if strcmp(p.hostname,'triostiml')
            p.keys.confirm  = KbName('4$');
            p.keys.increase = KbName('1!');
            p.keys.decrease = KbName('3#');
        else %key settings for regular keyboard - debugging and piloting
            p.keys.confirm  = KbName('upArrow');
            p.keys.increase = KbName('rightArrow');
            p.keys.decrease = KbName('leftArrow');
        end
        p.keys.pulse                   = KbName('5%');
        p.keys.el_calib                = KbName('v');
        p.keys.el_valid                = KbName('c');
        p.keys.escape                  = KbName('escape');
        p.keys.enter                   = KbName('return');
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address = 888;
        %codes for different events                
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
        
        %% create the randomized design
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        p.out.rating                  = [];
        p.out.log                     = zeros(1000000,4).*NaN;
        p.out.response                = zeros(p.presentation.tTrial,1);
        p.out.ShockFactor             = 1.5; %pain threshold times shockfactor is the strenght of UCS used
        p.out.PainThreshold           = PainThreshold;
        p.var.current_bg              = p.stim.bg;%current background to be used.
        %Save the stuff
        save(p.path.path_param,'p');
        
    end
    
    function [] = SetPTB
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
        
        %Make everything transparent for debugging purposes. Otherwise hide
        %cursor.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        else
            HideCursor(p.ptb.screenNumber);        
        end
                
        %set the resolution correctly and report it
        res = Screen('resolution',p.ptb.screenNumber);
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        [p.ptb.w,p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        %Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width,p.ptb.height]  = Screen('WindowSize', p.ptb.screenNumber);
        
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
        %this is necessary for the Eyelink calibration (following three
        %lines were commented out, so maybe unnecssary. I don't really get
        %it since there is no sound.)
%       InitializePsychSound(0)
%       sound('Open')
%       Beeper(1000)
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
        KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %prepare parallel port communication.
        if ~ismac
            config_io;
            outp(p.com.lpt.address,0);
            if( cogent.io.status ~= 0 )
                error('inp/outp installation failed');
            end
        end
        
        %CORRECT
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        k = 0;
        %have to find out if we actually need to see 5 pulses if only
        %working in the eyelab. 
        while ~(k == 25 || k == 86 )
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
            fprintf('5/ Did the trigger test work?\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\n\nPress c to send it again, v to continue...\n')
            [~, k] = KbStrokeWait(p.ptb.device);
            k = find(k);
        end        
        fprintf('Continuing...\n');
    
        %load the pictures to the memory.
        p.ptb.stim_sprites     = CreateStimSprites(p.stim.files,p.ptb.w);%
        p.ptb.stim_sprites_cut = CreateStimSprites(p.stim.files_cut,p.ptb.w);%
        %% take care of the presentation - coordinates and relative position of stimuli 
        %size of the display here is 1080 x 1920 - if things are really
        %different in the eye lab or the scanner, have to change it
        if phase == 1
            dummy = []; %since we'll need some garbage variables on the way, let's put them in the same structure
            dummy.distBetStim  = 50; 
            dummy.stimsize  = p.stim.width./2;

            if p.nstim == 32
                %16 faces shown as 4 x 4
                dummy.left        = [p.ptb.midpoint(1) - 2 *dummy.stimsize - 1.5*dummy.distBetStim,p.ptb.midpoint(1) - 1*dummy.stimsize - 0.5*dummy.distBetStim, p.ptb.midpoint(1) + 0.5*dummy.distBetStim, p.ptb.midpoint(1) + 1*dummy.stimsize + 1.5*dummy.distBetStim];
                dummy.right       = dummy.left + dummy.stimsize;
                dummy.upper       = [p.ptb.midpoint(2) - 1.5 * dummy.distBetStim - 2*dummy.stimsize,p.ptb.midpoint(2) - 0.5 * dummy.distBetStim - dummy.stimsize, p.ptb.midpoint(2) + 0.5 * dummy.distBetStim, p.ptb.midpoint(2) + 1.5 * dummy.distBetStim + dummy.stimsize];
                dummy.lower       = dummy.upper + dummy.stimsize;
                %put it together as - left - top - right - bottom
                p.stim.chooseCoords(:,1) = repelem(dummy.left',4,1);
                p.stim.chooseCoords(:,3) = repelem(dummy.right',4,1);
                p.stim.chooseCoords(:,2) = repmat(dummy.upper',4,1);
                p.stim.chooseCoords(:,4) = repmat(dummy.lower',4,1);
            elseif p.nstim == 40
                %20 faces shown as 4 x 5
                dummy.left    = [p.ptb.midpoint(1) - 2.5 *dummy.stimsize - 2*dummy.distBetStim,p.ptb.midpoint(1) - 1.5*dummy.stimsize - 1*dummy.distBetStim, p.ptb.midpoint(1) - 0.5*dummy.stimsize,p.ptb.midpoint(1) + 0.5*dummy.stimsize + dummy.distBetStim,p.ptb.midpoint(1) + 1.5*dummy.stimsize + 2*dummy.distBetStim];
                dummy.right   = dummy.left + dummy.stimsize;
                dummy.upper   = [p.ptb.midpoint(2) - 1.5 * dummy.distBetStim - 2*dummy.stimsize,p.ptb.midpoint(2) - 0.5 * dummy.distBetStim - dummy.stimsize, p.ptb.midpoint(2) + 0.5 * dummy.distBetStim,p.ptb.midpoint(2) + 1.5 * dummy.distBetStim + dummy.stimsize];
                dummy.lower   = dummy.upper + dummy.stimsize;
                %put it together as - left - top - right - bottom
                p.stim.chooseCoords(:,1) = repelem(dummy.left',4,1);
                p.stim.chooseCoords(:,3) = repelem(dummy.right',4,1);
                p.stim.chooseCoords(:,2) = repmat(dummy.upper',5,1);
                p.stim.chooseCoords(:,4) = repmat(dummy.lower',5,1);
            end

            %next we need to check that neighbouring elements don't lie next to
            %each other on the sphere
            dummy.stims     = p.presentation.stimlist;
            dummy.nstims    = numel(dummy.stims);
            dummy.dists     = unique(round(p.presentation.allDist./5)*5);

            %maximal/minimal allowances
            dummy.minDistAllowed    = dummy.dists(4); 
            dummy.maxIter           = 5000; 

            if dummy.nstims == 16
                dummy.nrow    = 4;
                dummy.ncol    = 4;
            elseif dummy.nstims == 20
                dummy.nrow    = 4;
                dummy.ncol    = 5;
            end

            dummy.raster    = zeros(dummy.nrow+2,dummy.ncol+2);
            dummy.index     = (size(dummy.raster,1)+1) : numel(dummy.raster)-size(dummy.raster,1);
            dummy.index     = dummy.index(~ismember(mod(dummy.index,size(dummy.raster,1)),[0,1]))';
            dummy.allIndex  = [dummy.index,dummy.index + [(-1-(dummy.nrow+2)),-(dummy.nrow+2),(+1-(dummy.nrow+2)),-1,+1,(-1+(dummy.nrow+2)),+(dummy.nrow+2),(+(dummy.nrow+2)+1)]];
            dummy.ok = dummy.maxIter;
            dummy.secondOut       = 4; %be less conservative each time  
            %start again with maximally 1 allowed distance within the limit...
            dummy.maxNumContra    = 0; %how many neighbours per element are allowed to me within the lower limit of distance
            dummy.counter         = 1; %increases with every necessary change in criteria
            dummy.numContra       = ones(numel(dummy.index,1));  %how many neighbours that are too close than they should per element

            fprintf('Figuring out an arrangement of stimuli for the selection screen that minimizes neighbouring of sphere-neighbours.\n');
            while sum(dummy.numContra > dummy.maxNumContra) && dummy.ok 
                if dummy.ok == dummy.maxIter
                    fprintf('Run # %2d, min allowed distance: %6.2f, max allowed exceptions: %2d\n',dummy.counter,dummy.minDistAllowed,dummy.maxNumContra);
                end
                dummy.raster = padarray(reshape(Shuffle(dummy.stims),4,[]), [1,1]); %shuffle elements and pad the matrix with zeros
                for x = 1 : numel(dummy.index) 
                    %which stimuli are neighboring here?
                    dummy.reference     = dummy.raster(dummy.allIndex(x,1));
                    dummy.others        = dummy.raster(dummy.allIndex(x,2:end));
                    dummy.others(dummy.others == 0)   = []; %remove the zeros from the padding
                    dummy.distOneEl     = p.presentation.allDist(p.presentation.stimlist == dummy.reference,ismember(p.presentation.stimlist,dummy.others));
                    dummy.numContra(x)  = sum(dummy.distOneEl <= dummy.minDistAllowed);
                end
                dummy.ok = dummy.ok-1;
                if ~dummy.ok 
                    dummy.maxNumContra    = dummy.maxNumContra + 1;
                    if dummy.maxNumContra > 3 && dummy.secondOut >= 2
                        dummy.secondOut = dummy.secondOut - 1; %worst case: use 0 as least 
                        dummy.minDistAllowed = dummy.dists(dummy.secondOut); %be less conservative
                        fprintf('Couldn''t converge, new lower limit: %d\n',dummy.minDistAllowed);
                        dummy.maxNumContra = 0;
                    end
                    dummy.ok = dummy.maxIter; %another 1000 runs;
                    dummy.counter = dummy.counter + 1;
                end
            end
            p.stim.raster = dummy.raster(2:end-1,2:end-1); %use last solution without the 0-padding
            %add distances to it
            p.stim.rasterDist   = zeros(size(p.stim.raster));
            for x = 1:numel(p.stim.raster);
                p.stim.rasterDist(x)    = p.presentation.allDist(1,p.presentation.stimlist == p.stim.raster(x));
            end
            fprintf(['Solution based on run # %d - lower limit: %5.2f, allowed exeptions: %d\n',...
             '%d iterations were needed\n'],dummy.counter,dummy.minDistAllowed,dummy.maxNumContra,dummy.maxIter-dummy.ok);
            clear dummy; %get rid of the garbage
        end
            
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
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearGen_3D Experiment (Lukas Neugebauer, stolen from Selim Onat)''');
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
    
    function [t] = ShowInstruction(nInstruct,waitforkeypress,varargin)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, ==> subject presses a button to proceed
        %if waitforkeypress is 0, ==> text is shown for VARARGIN seconds.
        [text]= GetText(nInstruct);
        ShowText(text,nInstruct);        
        if waitforkeypress %and blank the screen as soon as the key is pressed
            KbStrokeWait(p.ptb.device);                        
        else
            WaitSecs(varargin{1});                
        end
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        t = Screen('Flip',p.ptb.w);
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
        [secs, keyCode, deltaSecs] = KbStrokeWait(p.ptb.device);
        ShowInstruction(10,0,1+rand(1));%shock is coming message...
        t = GetSecs + p.duration.shock;        
        while GetSecs < t;
            Buzz;
        end
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätige deine Einschätzung mit der mit der oberen Pfeiltaste.';
        rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
        response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nerträglich' 'erträglich'},message,0);
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
        %not necessary for behavioral piloting
%         [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%will log it
        secs = GetSecs;
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
            fix_y        = p.presentation.CrossPosition(nTrial);
            ISI          = p.presentation.isi(nTrial);
            ucs          = p.presentation.ucs(nTrial);
            oddball      = p.presentation.oddball(nTrial);
            prestimdur   = p.duration.prestim+rand(1)*.25;
            dist         = p.presentation.dist2csp(nTrial);            
            mblock_jump  = mblock_jumps(nTrial);
            block_id     = p.presentation.mblock(nTrial);            
            %prestimdur   = p_presentation_prestim_dur(nTrial);                       
            %
            OnsetTime     = TimeEndStim + ISI-p.duration.stim - p.ptb.slack;
            fprintf('%d of %d, S: %d, ISI: %d, UCS: %d, ODD: %d, OnsetTime: %05.8gs, ',nTrial,p.presentation.tTrial,stim_id,ISI,ucs,oddball, OnsetTime);
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim] = Trial(nTrial,OnsetTime, prestimdur, stim_id, ucs  , fix_y,  oddball,dist,mblock_jump,block_id);
            %(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist )
            fprintf('OffsetTime: %05.8gs, Difference of %05.8gs\n',TimeEndStim,TimeEndStim-OnsetTime-p.duration.stim);
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
        
        %not necessary for behavioral pilot
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

    function [TimeEndStim] = AskStimRating(phase)
        p.var.ExpPhase   = phase;%decides which message is being shown and wether there is an end message
        %phase
        p.var.current_bg = p.stim.bg_rating;
        %% create the order of presentation and balance the position of fixation cross
        nseq           = 0;
        rating_seq     = [];
        pos1_seq       = [];
        idx            = [];
        face_order     = p.presentation.stimlist;
        if p.var.ExpPhase == 5
           nReps    = 2;
           nIn      = 71;
        elseif p.var.ExpPhase == 1
           nReps    = 1;
           nIn      = 72;
        end
        while nseq < nReps
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
        ShowInstruction(nIn,1);
        rect             = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];%for the rating slider
        tRatend          = length(rating_seq);
        %save the rating sequence just for security
        if p.var.ExpPhase == 1
           p.var.ratingCount    = p.var.ratingCount + 1;
           p.out.rating_seq.phase1(:,p.var.ratingCount) = rating_seq;
           p.out.pos1_seq.phase1(:,p.var.ratingCount)   = pos1_seq;
        elseif p.var.ExpPhase == 5
           p.out.pos1_seq.phase5    = rating_seq; 
           p.out.rating_seq.phase5  = pos1_seq;
        end
        
        %run over all the pictures to be rated.
        for nRatend = 1:tRatend;
            
            %the variable that are used by Trial function
            stim_id     = rating_seq(nRatend);
            stimIndex    = p.stim.stimIndex(p.stim.stimID == stim_id,2);

            fix_y       = pos1_seq(nRatend);
            %
            next_stim_id = [];%this is a trick, otherwise a fixation cross appears right before the rating :(
            next_pos1    = [];
            %
            %to send know the distance here, little dummy setup:
            dist         = p.presentation.allDist(p.presentation.stimlist==stim_id,1);
            
            % show the picture
            %Trial(nTrial     ,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist,microblock_jump,mblock_id)
            Trial(1000+nRatend,GetSecs+1,p.duration.prestim,stim_id,0,fix_y,0,dist,0,0);
            % show the slider
            rate(nRatend,1)  = RatingSlider(rect, p.rating.division, datasample(1:p.rating.division,1), p.keys.increase, p.keys.decrease, p.keys.confirm, {SliderTextL{1} SliderTextR{1}},message,1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Verbose the rating of the subject
            fprintf('============\nRating Results %d (%d/%d):\n', stim_id, nRatend, tRatend);
            dummy = rating_seq(1:nRatend);%trials shown so far
            for iii = 1:p.stim.tFace-1 %account for fact that faces also counts
                stim_id_rate    = p.presentation.stimlist(iii);
                r = round(mean(rate(dummy == stim_id_rate)));
                if isnan(r)
                    r = 0;
                end
                if stim_id_rate == p.stim.cs_plus
                    fprintf('Stimulus %02d: * %s \n',stim_id_rate,repmat('+',1,1+r));
                else
                    fprintf('Stimulus %02d:   %s \n',stim_id_rate,repmat('+',1,1+r));
                end
            end
        end
        %sort the stim_ids and then sort the same the rates and make a
        %matrix out of that to store
        [~, i]       = sort(rating_seq);
        rate         = reshape(rate(i),nReps,p.stim.tFace-1)';
        %NEW: added stimulus ID to the rating output so that it is clear
        %which rating is for which stimulus
        p.out.rating = [sort(p.presentation.stimlist)',rate];
        save(p.path.path_param,'p');
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        %
        save(p.path.path_param,'p');
        %show end screen, wait for keypress and flip screen for new
        %timestamp if we're in the experimental phase
        if p.var.ExpPhase == 1
            TimeEndStim     = ShowInstruction(73,1);
        end
    end
    
    function AskDetectionSelectable
        %account for fact that matlab indexing goes vertically first
        positions       = reshape(1:p.stim.tFace,4,[])';positions = positions(:)';
        positions       = circshift(positions,PsychRandSample(positions,[1 1]));%position of the marker
        p.var.ExpPhase = 4;
        ShowInstruction(8,1);        
        %%                
        increment([p.keys.increase p.keys.decrease]) = [1 -1];%keys to change position of slider horiontically
        %%
        ok                 = 1;
        while ok                        
            DrawGrid; %used to be DrawCircle, but it is no longer a circle, so...
            Screen('FrameOval', p.ptb.w, [1 1 0], p.stim.chooseCoords(positions(1),:), 2);%draw the marker circle .
            Screen('Flip',p.ptb.w);                                    
            [~, keyCode, ~]  = KbStrokeWait(p.ptb.device);%observe key presses 
            keyCode          = find(keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                if (keyCode == p.keys.increase) || (keyCode == p.keys.decrease)
                    positions  = circshift(positions,increment(keyCode));
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
        p.out.selectedface = p.stim.raster(positions(1));
        p.out.selecteddist = p.stim.rasterDist(positions(1));
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

%% Define second and/or third level functions (functions used by other functions)
% In case you run the script and MATLAB tells you, that it can't find a
% function, missing second level functions might be the problem (especially
% if you evaluate it line by line instead of calling the function, e.g.
% when you're debugging

    function [FM,labels] = FileMatrix(path)
            %Takes a path with file extension associated to regexp (e.g.
            %C:\blabl\bla\*.bmp) returns the file matrix
            dummy = dir(path);
            FM    = [repmat([fileparts(path) filesep],length(dummy),1) vertcat(dummy(:).name)];
            labels = {dummy(:).name};
    end
    
    function [out]=CreateStimSprites(files,window)
    %loads all the stims to video memory
        for nStim = 1:p.stim.tFile
            filename       = files(nStim,:);
            [im , ~, ~]    = imread(filename);
            out(nStim)     = Screen('MakeTexture', window, im );
        end
    end

    function ShowText(text,nInstruct)
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
                'In diesem Durchgang können Sie sich vollkommen sicher fühlen,\n' ...
                'es werden keine elektrischen Reize verabreicht.\n' ...
                'Eine wichtige grundsätzliche Regel ist, dass Sie das Fixationskreuz (das „+“)\n' ...
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
            text = ['3/ Bewegen Sie sich möglichst wenig.\n'...
                ];
        elseif nInstruct == 304%third Instr. of the training phase.
            text = ['4/ Nur eines der Gesichter wird mit elektrischen Reizen gepaart.\n'...
                ];
%         elseif nInstruct == 305%third Instr. of the training phase.
%             text = ['5/ Nur eines der Gesichter wird mit elektrischen Reizen gepaart.\n'...
%                 ];
        elseif nInstruct == 305%third Instr. of the training phase.
            text = ['Drücken Sie jetzt die obere Taste, das Experiment startet dann in wenigen Sekunden.\n' ...
                ];
        elseif nInstruct == 4%third Instr. of the training phase.
            text = ['Vor dem Experiment legen wir nun \n' ...
                'die Schockintensität für den Rest des Experiments fest. \n' ...
                'Drücken Sie die obere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 71;%rating during distinct rating phase in the end 
            text = ['In dieser Phase hätten wir gerne, dass Sie die Gesichter\n'...
                'noch einmal im Hinblick auf folgende Frage bewerten:\n'...
                '„Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?“\n'...
                'Bewegen Sie den Zeiger mit der rechten und linken Taste\n'...
                'und bestätigen Sie Ihre Einschätzung mit der oberen Taste.\n'...
                ];
        elseif nInstruct == 72; %rating during the experiment
            text = ['Bitte bewerten Sie die Gesichter, die Sie nun sehen\n'...
                'sehen werden im Hinblick auf folgende Frage:\n'...
                '„Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                'einen elektrischen Schock zu erhalten?“\n'...
                'Bewegen Sie den Zeiger mit der rechten und linken Taste\n'...
                'und bestätigen Sie Ihre Einschätzung mit der oberen Taste.\n\n'...
                'Beginnen Sie mit der oberen Taste.\n'...
                ];
        elseif nInstruct == 73; %end of rating during short rating phases in between
            text = ['Vielen Dank für Ihre Einschätzung.\n',...
                    'Drücken Sie die obere Taste, um fortzufahren.\n'];
        elseif nInstruct == 8;%AskDetectionSelectable
            text = ['Sie sehen nun noch einmal eine Übersicht der verschiedenen Gesichter.\n'...
                'Bitte geben Sie an, welches der Gesichter Ihrer Meinung nach\n mit dem Schock gepaart wurde.\n\n'...
                'Nutzen Sie die linke und rechte Taste, um die Markierung\n zum richtigen Gesicht zu navigieren.\n'...
                'Betätigen Sie am Ende einer Zeile die rechte Taste, um in die nächste Zeile zu gelangen.\n'...
                'Umgekehrt kommen Sie in die vorherige Zeile, indem Sie am Anfang einer Zeile die linke Taste drücken.\n'...
                'und drücken Sie die obere Taste zum Bestätigen.\n\n'...
                'Bitte zum Starten die obere Taste drücken.\n'...
                ];
        elseif nInstruct == 801;%#ok<*NOSEL> %AskDetectionSelectable
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
                'einen elektrischen Schock zu erhalten?“\n' ...
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

    function Buzz
        outp(p.com.lpt.address, p.com.lpt.digitimer );
        WaitSecs(p.duration.shockpulse);
        outp(p.com.lpt.address, 0);
        WaitSecs(p.duration.intershockpulse);
    end

    function [rating] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
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
    
    function Log(ptb_time, event_type, event_info)
        
        %Phases:
        %Instruction          :     0
        %Test                 :     1
        %Rating               :     5   this is only for the seperate
        %   phase at the end, not the ratings in between
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
       
%plot(p.out.log(1:p.var.event_count,1) - p.out.log(1,1),p.out.log(1:p.var.event_count,2),'o','markersize',10);
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

    function [keycode, secs] = KbQueueDump
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
 
    function [TimeEndStim]=Trial(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist,microblock_jump,mblock_id)
        %get all the times
        TimeCrossOnset     = TimeStimOnset  - prestimdur;
        TimeCrossJump      = TimeStimOnset  + p.duration.stim/2;
        TimeEndStim        = TimeStimOnset  + p.duration.stim- p.ptb.slack;
        TimeStartShock     = TimeStimOnset  + p.duration.onset2shock;
        TimeTrackerOff     = TimeStimOnset  + p.duration.keep_recording;
        
        stimIndex    = p.stim.stimIndex(p.stim.stimID == stim_id,2);
        
        % Fixation Onset
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
        
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);        
        Log(TimeCrossOn,1,fix_i);%cross onset.
        %turn the eye tracker on
        if eyelab
            StartEyelinkRecording(nTrial,stim_id,p.var.ExpPhase,dist,oddball,ucs,fix,mblock_id);%I would be cautious here, the first trial is never recorded in the EDF file, reason yet unknown.
        end
        %% Draw the stimulus to the buffer
        if ~stim_id==0
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stimIndex));
        end
        %draw also the fixation cross
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
        Screen('DrawingFinished',p.ptb.w,0);
        %% STIMULUS ONSET
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
        %send eyelink and ced a marker asap
        if eyelab
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
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stimIndex));
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
            fprintf('Will deliver shock in %f seconds\n',round(TimeStartShock-GetSecs,2));
            TimeStartShock = WaitSecs('UntilTime',TimeStartShock);
            if eyelab
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
        if eyelab
            Eyelink('Message', 'Stim Offset');
            Eyelink('Message', 'BLANK_SCREEN');
            TimeTrackerOff    = StopEyelinkRecording;    
        end
        
        if oddball == 1
            fprintf('This was an oddball trial!\n');
        end
        if ucs == 1
            fprintf('This was a UCS trial!\n');
            Log(TimeStartShock,5,NaN);%UCS delivery...This is done here to not waste time there
        end
        
        %ask for rating of shock expectancy every few microblocks
        if p.presentation.rating(nTrial)
            TimeEndStim = AskStimRating(1);
        end
        
    end
    
    function [t]=StartEyelinkRecording(nTrial,nStim,phase,dist,oddball,ucs,fix,block_id)
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
    end

    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
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

    function DrawGrid        
        for npos = 1:p.stim.tFace
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites_cut(p.stim.raster(npos)),[],p.stim.chooseCoords(npos,:));
        end
    end

end