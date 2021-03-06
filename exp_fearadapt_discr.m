function [p]=exp_fearadapt_discr(subject,phase,PainThreshold)

% Same/different discrimination task estimating the perceptual threshold alpha of an
% observer's underlying Psychometric Function (PF), using the method of constant stimuli.
% Input:
% subject = subject number
% phase   = phase number, will only name the logfile folder
% csp     = CS+ Face as ID (i.e. 1 to 8)
%
% Note: Two "chains" are run intertwinedly, i.e. trials for CS+ are mixed
% with trials for CS-. Chain 1 refers to CS+, Chain 2 to CS-.
%
% adapted by LK in 10/2016 for use on any computer

EyelinkWanted   = 0; %is Eyelink wanted?
fixcross        = 0; %want to have fixcrossin ITI?
sim_response    = 0; %simulate response by ObserverResponseFunction
debug           = 0;
lab           = '204';
%(see variable fix_start).

% make a break every ....th Trial
breakpoint      = 25;

ListenChar(2);%disable unwanted keypresses
commandwindow;
%clear everything
clear mex global functions
cgshut;
global cogent;
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);

el = [];
p  = [];
SetParams;
SetPTB;

if EyelinkWanted
    InitEyeLink;
    WaitSecs(2);
    ShowInstruction(1,1);
    CalibrateEL;
else
    WaitSecs(2);
    ShowInstruction(11,1);
end
if phase == 1
    ShowInstruction(5,1);
    ConfirmIntensity;
    RateShockIntensity;
    ShowInstruction(504,1);% Final confirmation to start (subject's job).
end
SetupLog;
%save the parameter file once now
save(p.path.path_param,'p');
if EyelinkWanted
    ShowInstruction(3,1);
end
% counter for within chain trials (cc) and global trials (tt)
% cc = zeros(1,tchain);
tt = 0;
%trialID is counting every single face (2 per Trial_YN), need that for
%Eyelink
trialID = 0;
for nTrial = 1:p.presentation.total_trials
    tt=tt+1;
    % enter in break loop
    if (tt~=1 && mod(tt,breakpoint)==1);
        save(p.path.path_param,'p');
        ShowInstruction(4,0,3);
        DeliverCostShocks(nTrial);
        ShowInstruction(7,1);
        %calibrate if Eyelink
        if EyelinkWanted 
            CalibrateEL;
        end
    end
    fprintf('Starting Trial %03d/%03d.\n',tt,p.presentation.total_trials)

    [out] = Trial_YN(nTrial,p.presentation.cond(nTrial));
    % ask subject for answer
    fprintf('Rating.\n')
    Screen('Textsize', p.ptb.w,p.text.fontsize);
    % put Rating there
    message1 = 'Waren die Formen unterschiedlich oder gleich?\n';
    message2 = 'Bewegen Sie den "Zeiger" mit der rechten und linken Pfeiltaste\n und best�tigen Sie Ihre Einsch�tzung mit der Leertaste.';
    
    rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
    secs0=GetSecs;
    if sim_response ==1
        [ response_subj] = ObserverResponseFunction(@PAL_CumulativeNormal,mean(p.presentation.delta),1/.01,.1,.05,p.presentation.delta(nTrial));
        %quick fix
        if response_subj == 0;
            response_subj = 2;
        end
    else
        [response_subj]  = RatingSlider(rect,2,Shuffle(1:2,1),p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'unterschiedlich' 'gleich'},message1,message2,0);
    end
    RT = GetSecs-secs0;
    if p.presentation.cond(nTrial)==1 || p.presentation.cond(nTrial) ==10
        signal=0;
    else
        signal=1;
    end
    
    % THIS PART WAS CHANGED AS COMPARED TO EXP_TREATGEN_PMF, because there
    % repsonses were reversed.. came from exp_painthreshold, I guess. Didnt
    % matter there bc of binary output, but here with shockIntensityRating
    % 1-10, it would have been a problem.
    
    
    sdt = NaN;
    if (response_subj == 1 && signal == 1)
        response = 1;
        fprintf('...Hit. \n')
        sdt=1;
        wrong = 0;
    elseif (response_subj==2 && signal == 1)
        response = 0;
        fprintf('...Miss. \n')
        sdt=3;
        wrong = 1;
    elseif (response_subj == 1 && signal ==0)
        response = 1;
        fprintf('...False Alarm. \n')
        sdt=2;
        wrong = 1;
    elseif (response_subj == 2 && signal == 0)
        response = 0;
        fprintf('...Correct Rejection. \n')
        sdt=4;
        wrong = 0;
    else
        warning('error in the answer algorithm! \n')
    end
    
    % store everything in the Log
    SetLog(nTrial,response,signal,sdt,RT,wrong)
    
end
ShowInstruction(4,0,3);
DeliverCostShocks(nTrial);
%final save of parameter-/logfile
save(p.path.path_param,'p');


%end of Experiment, show text to subject
ShowInstruction(2,0,2);
%get the eyelink file back to this computer
if EyelinkWanted
    StopEyelink(p.path.edf);
end

%close everything down
cleanup;
%move the folder to appropriate location
copyfile(p.path.subject,p.path.finalsubject);


    function    [out] = Trial_YN(trialID,trialtype)
        %         [test_face,ref_face,signal,trialID] = Trial_YN(trialID,ref_stim,test_stim,last_face_of_circle,tt)
        % data=[TrialType,i,delta, timeCue1,timeMask1,timeISI,timeCue2,timeMask2,timeChoice,KeyResp,KeyTime,diff,corr,RT,tEnd];
        
        [ind1,ind2,ref] = trialtype2stimuli(trialtype);
        Screen('Textsize', p.ptb.w,p.text.fixsize);
        
        %Define onsets
        % 1) Stim1
        % 2) Mask1
        % 3) blank
        % 4) Stim2
        % 5) Mask2
        % 6) Choice
        
        onsets = 0.25+GetSecs+p.duration.iti;          %stim1 on      . possibly add a Jitter here or do it by ITI.
        onsets = [onsets onsets(end)+p.duration.stim]; %mask1 on
        onsets = [onsets onsets(end)+p.duration.mask]; %blank on
        onsets = [onsets onsets(end)+p.duration.isi];  %stim2 on
        onsets = [onsets onsets(end)+p.duration.stim]; %mask2 on
        onsets = [onsets onsets(end)+p.duration.mask]; %mask2 off
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Actual stimulus presentation pipeline (without rating)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if EyelinkWanted
            StartEyelinkRecording(trialID,phase,cc(current_chain),tt,current_chain,isref(1),trial(1),delta_ref(1),delta_csp(1),abs_FGangle(1),fix(1),fix(2));
        end
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        TimeCrossOn  = Screen('Flip',p.ptb.w,0);
        end
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');%draw the prestimus cross atop    
        % 1) Stim1
        Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(ind1),[],p.ptb.rect2draw);
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        end
        Screen('Flip',p.ptb.w,onsets(1),0);
        MarkCED(p.com.lpt.address,p.com.lpt.StimOnset);
        if EyelinkWanted
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        Log(GetSecs,2,ind1);
        % 2) Mask1
        Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(ind1+p.stim.tFile),[],p.ptb.rect2draw)
%         Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(end),[],p.ptb.rect2draw);
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        end
        Screen('Flip',p.ptb.w,onsets(2),0);
        Log(GetSecs,3,NaN);
        % 3) blank
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        end
        Screen('Flip',p.ptb.w,onsets(3),0);
        Log(GetSecs,4,NaN);
        % 4) Stim2
        Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(ind2),[],p.ptb.rect2draw);
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        end
        Screen('Flip',p.ptb.w,onsets(4),0);
        MarkCED(p.com.lpt.address,p.com.lpt.StimOnset);
        Log(GetSecs,2,ind2);
        if EyelinkWanted
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        % 5) Mask2
        Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(ind2+2*p.stim.tFile),[],p.ptb.rect2draw)
        %         Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(end),[],p.ptb.rect2draw);
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        end
        Screen('Flip',p.ptb.w,onsets(5),0);
        Log(GetSecs,3,NaN);
        if fixcross==1
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.centralFixCross');
        end
        while GetSecs<onsets(end)
        end
        Screen('Flip',p.ptb.w,onsets(end),0);
        if EyelinkWanted
            StopEyelinkRecording;
        end
        out = [onsets ind1 ind2 ref];
    end

    function [ind1,ind2,ref] = trialtype2stimuli(trialtype)
        if trialtype <=9
            imgA = 'CSplus1_p000.png';%ref pic;
        else
            imgA = 'CSplus2_p000.png';%other pic;
        end
        
        switch trialtype
            case 1
                imgB = 'CSplus1_p000.png';
            case 2
                imgB = 'CSplus1_p050.png';
            case 3
                imgB = 'CSplus1_p075.png';
            case 4
                imgB = 'CSplus1_p100.png';
            case 5
                imgB = 'CSplus1_p150.png';
            case 6
                imgB = 'CSplus1_n050.png';
            case 7
                imgB = 'CSplus1_n075.png';
            case 8
                imgB = 'CSplus1_n100.png';
            case 9
                imgB = 'CSplus1_n150.png';
            case 10
                imgB = 'CSplus2_p000.png';
            case 11
                imgB = 'CSplus2_p050.png';
            case 12
                imgB = 'CSplus2_p075.png';
            case 13
                imgB = 'CSplus2_p100.png';
            case 14
                imgB = 'CSplus2_p150.png';
            case 15
                imgB = 'CSplus2_n050.png';
            case 16
                imgB = 'CSplus2_n075.png';
            case 17
                imgB = 'CSplus2_n100.png';
            case 18
                imgB = 'CSplus2_n150.png';
        end
        
        indA = find(strcmp(p.stim.label,imgA));
        indB = find(strcmp(p.stim.label,imgB));
        rdm = rand;
        ref = (rdm>=.5)+1; %index when the reference stimulus is presented. 1=1st, 2=2nd;
        if ref == 1
            ind1 = indA;
            ind2 = indB;
        elseif ref == 2
            ind1 = indB;
            ind2 = indA;
        end
    end
    function SetPTB
        
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
        % LK here
        % Make a screen asking for button press.
        %
        
        k = 0;
        while ~(k == p.keys.el_calib);%press V to continue
            pause(0.1);
            MarkCED(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
%             keyboard
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('/ Did the trigger test work?\n\n\nTurn on the Digitimer then press V to continue experiment or C to continue sending test pulses...\n')
            [~, k] = KbStrokeWait([]);
            k = find(k);
            Log(GetSecs,7,k);
        end
        fprintf('Continuing...\n');
        
        
        %Open a graphics window using PTB
        screens       =  Screen('Screens');
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        p.ptb.screenNumber=max(screens);
        
        %make everything transparent for debuggin purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        %
        res = Screen('resolution',p.ptb.screenNumber);
        HideCursor(p.ptb.screenNumber);%make sure that the mouse is not shown at the participant's monitor
        %spit out the resolution,
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        if sum([p.ptb.width p.ptb.height] - [1280 960]) ~= 0
            fprintf('SET THE CORRECT SCREEN RESOLUTION\n');
        end
        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        p.ptb.res                   = res;
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.imrect                = round([ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.stim.width p.stim.height]);
        p.ptb.cross_shift           = round([180 -120]./(1000/p.stim.height));%incremental upper and lower cross positions
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%always the same
        p.ptb.CrossPosition_y       = [p.ptb.midpoint(2)+p.ptb.cross_shift];
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)+p.ptb.cross_shift];
        p.ptb.fc_size              = 20;
        p.ptb.fc_width              = 4;
        p.ptb.fc_color              = [0 0 0];
        p.ptb.startY                = p.ptb.midpoint(2); %I guess this allows putting it higher, if coil covers parts of the screen.
        fix          = [p.ptb.midpoint(1) p.ptb.startY]; % yaxis is 1/4 of total yaxis
        p.ptb.centralFixCross     = [fix(1)-p.ptb.fc_width,fix(2)-p.ptb.fc_size,fix(1)+p.ptb.fc_width,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-p.ptb.fc_width,fix(1)+p.ptb.fc_size,fix(2)+p.ptb.fc_width];
        p.ptb.imagesize           = [808 606];%[900 675]; %how big we want it.
%         p.ptb.imagebox            = [p.ptb.res.width/2-p.ptb.imagesize(1)/2 p.ptb.res.height/2-p.ptb.imagesize(2)/2 p.ptb.midpoint(1)+p.ptb.imagesize(1) p.ptb.midpoint(2)+p.ptb.imagesize(2) ];
        p.ptb.rect2draw            =CenterRectOnPointd([0 0 p.ptb.imagesize], p.ptb.res.width / 2,p.ptb.res.height / 2); %taken from some demo.
        %
%         if fixjump == 0
%             p.ptb.CrossPositions   = FixationCrossPool;
%         end
        
        Priority(MaxPriority(p.ptb.w));
        
        
        
        
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

        
        %%
        for nStim = 1:p.stim.tFile
            filename       = p.stim.files(nStim,:);
            [im , ~, ~]    = imread(filename);
            if nStim<p.stim.tFile %this excludes the mask
                im = CenterStarfish(im);
            end
            %make the mask
%             im_rect = %get the rect in which the actual starfish is
%             star_roi  =CenterRectOnPointd([0 0 600 800], 900/2,1200/2);
            
            star_roi  =CenterRectOnPointd([0 0 680 900], 900/2,1200/2);
            clipped   = im(star_roi(1)+1:star_roi(3),star_roi(2)+1:star_roi(4),:);
            im_mask = ScrambleImage(clipped);
            im_mask_full = im;
            im_mask_full(star_roi(1)+1:star_roi(3),star_roi(2)+1:star_roi(4),:)=im_mask;
            
            % transform to grayscale if necessary
            %             if ndims(im) == 3
            %                 p.stim.stim(:,:,nStim)    = rgb2gray(im);
            %             else
            %                 p.stim.stim(:,:,nStim)    = im;
            %             end
            p.ptb.stim_sprites(nStim)                  = Screen('MakeTexture', p.ptb.w, im );
            p.ptb.stim_sprites(nStim+p.stim.tFile)     = Screen('MakeTexture', p.ptb.w, im_mask_full );
            im_mask_full_flipped = flipud(im_mask_full);
            p.ptb.stim_sprites(nStim+2*p.stim.tFile)   = Screen('MakeTexture', p.ptb.w, im_mask_full_flipped );
        end
        %         p.stim.delta = 360/p.stim.tFace;
        
        %create tukeywindow for the pink noise fadeout
        %         w  =.3;
        %         p.ptb.tw = tukeywin(p.stim.height,w)*tukeywin(p.stim.height,w)';
        
        %
        %         function  [cross_positions]=FixationCrossPool
        %             % please check the positions computed here, as
        %             % they depend on imagesize and resolution.
        %
        %             radius   = 290; %in px (around 14 degrees (37 px/deg))
        %             center   = [p.ptb.midpoint(1) p.ptb.midpoint(2)];
        %
        %             %setting up fixation cross pool vector of size
        %             % totaltrials x 4 (face_1_x face_1_y face_2_x face_2_y)
        %             cross_directions = round(rand(tchain*p.psi.presentation.numtrials_chain,2))*180;
        %             dummy            = cross_directions + rand(tchain*p.psi.presentation.numtrials_chain,2)*30-15;
        %             cross_positions  = [cosd(dummy(:,1))*radius+center(1) sind(dummy(:,1))*radius+center(2)...
        %                 cosd(dummy(:,2))*radius+center(1) sind(dummy(:,2))*radius+center(2)];
        %         end
    end



    function SetParams
        
        %
        p.var.timings                 = zeros(1,10);
        p.var.event_count             = 0;
        p.var.ExpPhase                = phase;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        elseif strcmp(p.hostname,'blab0')
            p.path.baselocation       = 'U:\kampermann\';
            addpath('U:\kampermann\Palamedes_1_8_2\Palamedes\');
        else %%please enter your path here
            p.path.baselocation       = 'C:\Users\Lea\Documents\Experiments\';
        end
        
        p.path.experiment             = [p.path.baselocation 'FearAdapt_Pilote\'];
        p.path.stim                   = [p.path.experiment 'discr_stim\'];
        p.path.seq                    = [p.path.experiment 'seq\discr\'];
        %         p.path.stim24                 = [p.path.stim '24bit' filesep];%location of 24bit stimuli, useful only to send it to the eyelink system
        %
        p.subID                       = sprintf('sub%02d',subject);
        p.path.edf                    = sprintf(['s%03dp%02d' ],subject,phase);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_pmf_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '\discr\'];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'stimulation']);       
        if EyelinkWanted
            mkdir([p.path.subject 'eye']);
        end
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\' 'p.mat']);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        
        dummy = dir([p.path.stim '*.png']);
        dummy = dummy([5:9,1:4,14:18,10:13]); %quick and dirty permutation so that filename row corresponds to cond_id.
        p.stim.files    = [repmat([fileparts(p.path.stim) filesep],length(dummy),1) vertcat(dummy(:).name)];
        p.stim.label = {dummy(:).name};
        
        
        p.stim.tFile                  = size(p.stim.files,1);%number of different files
%         p.stim.tShape                 = p.stim.tFile-1;%number of shapes (- mask)
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
        %set the background gray according to the background of the stimuli
        for i = 1:p.stim.tFile;
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
        %
        %font size and background gray level
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;%30;
        p.text.fixsize                 = 60;
        p.text.color                   = [0 0 0];
        %rating business
        p.rating.division              = 2;%number of divisions for the rating slider
        %
        p.rating.color                 = [0 0 0];
        p.stim.white                   = [255 255 255];
        %get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        
        if strcmp(p.hostname,'triostim1')
            p.keys.confirm                 = KbName('7');
            p.keys.increase                = KbName('8');
            p.keys.decrease                = KbName('6');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
            p.keys.el_calib                = KbName('v'); %for the trigger test to MarkCED
            p.keys.el_valid                = KbName('c');
        else
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('space');
            p.keys.increase                = KbName('right');
            p.keys.decrease                = KbName('left');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
            p.keys.el_calib                = KbName('v');
            p.keys.el_valid                = KbName('c');
        end
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        if strcmp(p.hostname,'blab0') && strcmp(lab,'204')
             p.com.lpt.address = 59392;%hex2dec('0378A');%parallel port of the computer.
        elseif strcmp(p.hostname,'blab0') && strcmp(lab,'201')
             p.com.lpt.address = hex2dec('0378A');
        else
            p.com.lpt.address = 888;%parallel port of the computer.
        end
        %codes for different events that are sent for logging in the
        %physiological computer.
        p.com.lpt.digitimer = 1;%12;%8
        p.com.lpt.StimOnset = 4;
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        %         1.5 0.5 0.5
        p.duration.stim                = 1.5;%s
        p.duration.fix                 = .7;
        p.duration.mask                = .5;
        p.duration.crossmoves          = p.duration.stim./2;
        p.duration.isi                 = 4.0;
        p.duration.iti                 = 2.5;
        p.duration.choice              = 2.5;
        p.duration.shock               = 0.1;%s;x
        p.duration.shockpulse          = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse     = 0.01;%ms; and the time between each pulse
        if sim_response ==1
            fn=fieldnames(p.duration);
            for k=1:numel(fn)-3
                p.duration.(fn{k}) = p.duration.(fn{k})/10;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        p.presentation = load([p.path.seq 'n100_5trials_random.mat']);
        p.presentation = p.presentation.seq(subject);
        p.presentation.seqid = subject;
        p.presentation.total_trials = length(p.presentation.cond);
        p.presentation.trial2break  = 25;
        p.presentation.block        = reshape(repmat([1 2 3 4],p.presentation.trial2break,1),1,p.presentation.total_trials);
        p.presentation.press2shock  = 5;
        p.out.PainThreshold           = PainThreshold;%the pain threshold (i.e. pain intensity where p(painful) = .5 for the subject, it is an input argument, must be computed before the experiment.
        p.out.ShockFactor             = 2;%factor to multiply the PainThreshold with, will use this factor to propose the experimenter the final shock intensity to be used during the FearGen Experiment.
        p.out.ShockIntensityRating     = nan(1,10);
        
        p.var.current_bg              = p.stim.bg;%current background to be used.
        %Save the stuff
        save(p.path.path_param,'p');
        %
        
    end
    function [rating]=RatingSlider(rect,tSection,position,up,down,confirm,labels,message1,message2,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [nx, ny, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.text.color,[],[],[],2);
            Screen('FillRect',p.ptb.w,p.stim.bg);
        end
        bb = max(bb);
        bb_size = bb(3)-bb(1);%vertical size of the bb.
        %
        DrawSkala;
        ok = 1;
        while ok == 1
            [secs, keyCode, deltaSecs] = KbStrokeWait;
            
            keyCode = find(keyCode);
            if (keyCode == up) | (keyCode == down)
                next = position + increment(keyCode);
                if next < (tSection+1) & next > 0
                    position = position + increment(keyCode);
%                     rating   = tSection - position + 1 %where did that come from?
                end
                DrawSkala;
            elseif keyCode == confirm
                WaitSecs(0.1);
                ok = 0;
                Screen('FillRect',p.ptb.w,p.stim.bg);
                Screen('Flip',p.ptb.w);
            end
        end
        
        function DrawSkala
            rating               = position; %tSection - position + 1; %WHERE and WHEN did this happen?
            increment([up down]) = [1 -1];%delta
            tick_x               = linspace(rect(1),rect(1)+rect(3),tSection+1);%tick positions
            tick_size            = rect(3)./tSection;
            ss                   = tick_size/5*0.9;%slider size.
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize./2);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p.text.color);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.6,rect(2), p.text.color);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.2,rect(2), p.text.color);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.rating.color, round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message1, 'center', p.ptb.midpoint(2)*0.2,  p.text.color,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize./2);
            DrawFormattedText(p.ptb.w,message2, 'center', p.ptb.midpoint(2)*0.4,  p.text.color,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            Screen('Flip',p.ptb.w);
        end
    end

    function [shuffled,idx] = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end

    function [a]=MinimumAngleQuartile(y,x)
        %[a]=MinimumAngle(x,y);
        %
        %finds the minimum angle between two angles given in degrees, the answer is
        %also in degrees. The clockwise distances from Y to X are considered as
        %positive. Opposite angles are considered as positive 180.
        
        x  = deg2rad(x);
        y  = deg2rad(y);
        
        a  = atan2(sin(x-y), cos(x-y));
        
        a  = -round(((180/pi)*a)*4)/4;
        
        if any(abs(a) == 180);
            a(abs(a) == 180) = 180;
        end
    end
    function centerput = CenterStarfish(imput)
        Nrows = size(imput,1); %this is x
        Ncols = size(imput,2); %this is y
        offset_x = 15; %this was determined via entering the clicking world.
        offset_y = 10;
        centerput = imput([(Nrows-offset_y):Nrows 1:(Nrows-offset_y-1)],[(offset_x+1):Ncols 1:offset_x],:);
    end
    function scramble = ScrambleImage(im0)
    %as done in Norbury et al. 2018
    
    blockSize = 10;
    
    nRows = size(im0, 1) / blockSize;
    nCols = size(im0, 2) / blockSize;
    scramble = mat2cell(im0, ones(1, nRows) * blockSize, ones(1, nCols) * blockSize, size(im0, 3));
    scramble = cell2mat(reshape(scramble(randperm(nRows * nCols)), nRows, nCols));

%save as desired
    end
    function ShowInstruction(nInstruct,waitforkeypress,varargin)
        
        [text]=GetText(nInstruct);
        ShowText(text);
        %let subject read it and ask confirmation to proceed.
        if waitforkeypress
            KbStrokeWait;
        else
           WaitSecs(varargin{1});
        end
        Screen('FillRect',p.ptb.w,p.stim.bg);
        Screen('Flip',p.ptb.w);
    end
    function ShowText(text)
        
        
        Screen('FillRect',p.ptb.w,p.stim.bg);
        %DrawFormattedText(p.ptb.w, text, p.text.start_x, 'center',p.text.color,[],[],[],2,[]);
        DrawFormattedText(p.ptb.w, text, 'center', 'center',p.text.color,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        
        %show the messages at the experimenter screen
        fprintf([repmat('=',1,50) '\n']);
        fprintf('Subject''s monitor:\n');
        fprintf(text);
        fprintf([repmat('=',1,50) '\n']);
        
    end


    function [text]=GetText(nInstruct)
        
        if nInstruct == 0%Eyetracking calibration
            
            text = ['Um Ihre Augenbewegungen zu messen, \n' ...
                'm�ssen wir jetzt den Eye-Tracker kalibrieren.\n' ...
                'Dazu zeigen wir Ihnen einige Punkte auf dem Bildschirm, \n' ...
                'bei denen Sie sich wie folgt verhalten:\n' ...
                'Bitte fixieren Sie den Fixationspunkt und \n' ...
                'bleiben Sie so lange darauf, wie er zu sehen ist.\n' ...
                'Bitte dr�cken Sie jetzt den oberen Knopf, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
            
        elseif nInstruct == 1
            text = ['In diesem Experiment sehen Sie nacheinander jeweils zwei Formen.\n'...
                'Danach werden Sie gefragt, ob die Formen unterschiedlich oder gleich waren.\n'...
                '\n'...
                'Benutzen Sie zum Antworten die Pfeiltasten (links, rechts) und die Leertaste zum Best�tigen.\n'...
                '\n'...
                'Sie erhalten in diesem Teil keine Schmerzreize.\n'...
                'Folgen Sie aber bitte auch hier streng den Fixationskreuzen!\n'...
                '\n'...
                'Sie werden alle ' num2str(breakpoint) ' Durchg�nge eine Pause machen k�nnen,\nnach der der Eyetracker neu kalibriert wird.\n'...
                'Das hei�t, Sie k�nnen in der Pause den Kopf ruhig aus der Kopfst�tze nehmen und sich entspannen. \n'...
                '\n'...
                'Wenn Sie noch Fragen haben, k�nnen Sie jetzt die Versuchsleiter/in fragen.\n'...
                '\n'...
                'Dr�cken Sie ansonsten die Leertaste,\n'...
                '   um das Experiment zu starten.\n' ...
                ];
        elseif nInstruct == 11
             text = ['In diesem Experiment sehen Sie nacheinander jeweils zwei Formen.\n'...
                'Danach werden Sie gefragt, ob die Formen unterschiedlich oder gleich waren.\n'...
                '\n'...
                'Benutzen Sie zum Antworten die Pfeiltasten (links, rechts) und die Leertaste zum Best�tigen.\n'...
                '\n'...
                'Die richtigen und falschen Antworten werden im Hintergrund registriert.\n'...
                '\n'...
                'Alle ' num2str(breakpoint) ' Durchg�nge erfolgt eine Pause. \n Hier erhalten Sie zun�chst die entsprechende Anzahl an elektr. Reizen, je nachdem wie oft Sie richtig oder falsch geantwortet haben.\n'...
                'Anschlie�end k�nnen Sie eine kurze Pause machen und sich entspannen. Danach starten Sie per Tastendruck den n�chsten Block.\n'...
                '\n'...
                'Hinweis: Bitte halten Sie die linke Hand so ruhig wie m�glich. Dies ist sehr wichtig f�r die Datenqualit�t der physiologischen Messung.\nWenn nicht anders m�glich, bewegen Sie diese bitte in der Pause zwischen den Bl�cken, nach den elektr. Reizen.\n'...
                '\n'...
                '\n'...
                'Dr�cken Sie die Leertaste um zu beginnen.\n'...
                ];
        elseif nInstruct == 3
            text = ['Der Eyetracker ist nun kalibiert.\n'...
                '\n'...
                'Bitte ver�ndern Sie Ihre Kopfposition nun nicht mehr.\n'...
                '\n'...
                'Zur Erinnerung: Im Experiment sehen Sie jeweils zwei Formen und geben anschlie�end an,\n'...
                '\n'...
                'ob die Formen gleich oder unterschiedlich waren.\n'...
                '\n'...
                'Benutzen Sie dazu die Pfeiltasten (links, rechts) und die Leertaste zum Best�tigen.\n'...
                '\n'...
                'Zus�tzlich folgen Sie auch hier immer den Fixationskreuzen.\n'...
                '\n'...
                'Dr�cken Sie nun die Leertaste,\n'...
                '   um das Experiment zu starten!\n' ...
                 '\n'...
                ];
        elseif nInstruct == 2%end
            text = 'Experiment beendet!\n';
        elseif nInstruct==4%end of block
            text = ['Ende des Blocks.\n'];     
        elseif nInstruct == 5%third Instr. of the training phase.
            text = ['Vor dem Experiment legen wir nun \n' ...
                'die Schockintensit�t f�r den Rest des Experiments fest. \n\n' ...
                'Dr�cken Sie die Leertaste um fortzufahren.\n' ...
                ];                      
        elseif nInstruct == 501%third Instr. of the training phase.
            text = ['Experimenter: Please confirm that you set the stimulating intensity. \n'];
        elseif nInstruct == 502%third Instr. of the training phase.
            text = ['Experimenter: Stimulation OK. \n'];
        elseif nInstruct == 503%third Instr. of the training phase.
            text = ['Experimenter: Adapt stimulation intensity. \n'];
          elseif nInstruct == 504%third Instr. of the training phase.
            text = ['Wir sind nun bereit, das Wahrnehmungsexperiment zu starten.\n'...
                  '\n'...
                'Wenn Sie noch Fragen haben, k�nnen Sie jetzt die Versuchsleiter/in fragen.\n'...
                '\n'...
                'Dr�cken Sie ansonsten die Leertaste,\n'...
                '   um das Experiment zu starten.\n'...
                ];    
        elseif nInstruct == 505
              text = ['Wir w�rden Sie nun noch einmal bitten zu bewerten, wie schmerzhaft Sie den elektr. Reiz finden.\n'...
                '\n'...
                'Dr�cken Sie die Leertaste, um den Reiz zu erhalten und anschlie�end auf einer Skala von 1 (nicht schmerzhaft) bis 10 (maximal schmerzhaft) zu bewerten.\n'...
                'Die Bewertung nehmen Sie wie gehabt mit Pfeiltasten und Leertaste zum Best�tigen vor.\n'...
                '\n'...
                'Dr�cken Sie bitte die Leertaste, wenn Sie bereit sind.\n'...
                ]; 
        elseif nInstruct == 9%
            text = ['Bitte geben Sie an, ob die Reizst�rke der folgenden elektr. Stimulation\n f�r Sie ertr�glich ist.\n'...
                '\n'...
                'Dr�cken Sie bitte die Leertaste, wenn Sie bereit sind.\n'...
                ];
        elseif nInstruct == 10%just before the shock
            text = ['Reiz kommt...\n'];
        elseif nInstruct==7%break
            text = [sprintf('Sie haben bereits %g von %g Durchg�ngen geschafft!\n',tt-1,p.presentation.total_trials)...
                'Machen Sie gerne eine kurze Pause.\n\n'...
                'Dr�cken Sie anschlie�end die Leertaste, um weiterzumachen.\n'];
        elseif nInstruct==6
            text = ['Experimenter: Check physio computer!\n Repeat with c, continue with v.\n'];
        end
    end
function ConfirmIntensity
        %Compute the intensity we want to deliver to the subject.
        p.var.ShockIntensity = p.out.PainThreshold*p.out.ShockFactor;
        %
        ShowInstruction(9,1);
        %
        if strcmp(p.hostname,'blab0') && strcmp(lab,'204')
            %
            ShowInstruction(501,1);% Experimenter message.
            WaitSecs(2);            
            ShowInstruction(10,0,1+rand(1));%shock is coming message...
            t = GetSecs + p.duration.shock;
            while GetSecs < t;
                Buzz;
            end
            %
            message1   = 'Bewegen Sie den "Zeiger" mit der rechten und linken Pfeiltaste\n und best�tigen Sie mit der Leertaste.';
            rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
            response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nertr�glich' 'ertr�glich'},message1,'',0);
            if response == 2
                ShowInstruction(502,1); % Stimulation OK.
                fprintf('All is fine :)\n');
                fprintf('Subject confirmed the shock intensity inside the scanner...\n');
                fprintf('INTENSITY TO BE USED FOR THE MAIN EXPERIMENT: %g mA\n',p.var.ShockIntensity);
                p.out.ShockIntensity = p.var.ShockIntensity;
                return;
            elseif response == 1
                ShowInstruction(503,1); % Stimulation not OK.
                fprintf('Shit... :(, %g is too much for the subject\n',p.var.ShockIntensity);
                fprintf('We will try a little milder intensity.\n');
                p.out.ShockFactor = p.out.ShockFactor - 0.05;
                ConfirmIntensity;
            end
           
        else
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
            message1   = 'Bewegen Sie bitte den "Zeiger" mit der rechten und linken Pfeiltaste\n und best�tigen Sie mit der Leertaste.';
            rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
            response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nertr�glich' 'ertr�glich'},message1,'',0);
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
end
    function RateShockIntensity
        
    ShowInstruction(505,1);
       %instruction has been shown already
       %
       %
       
       WaitSecs(2);
       ShowInstruction(10,0,1+rand(1));%shock is coming message...
       t = GetSecs + p.duration.shock;
       while GetSecs < t;
           Buzz;
       end
       %
       WaitSecs(2);
       message1   = 'Bewegen Sie den "Zeiger" mit der rechten und linken Pfeiltaste\n und best�tigen Sie dann mit der Leertaste.';
       rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
       response = RatingSlider(rect,10,Shuffle(1:10,1),p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'gar nicht\nschmerzhaft' 'maximal\nschmerzhaft'},message1,'',1);
       p.out.ShockIntensityRating(find(isnan(p.out.ShockIntensityRating),1)) = response;
       
       text = ['Subject Rating: ' num2str(response) '\n Continue with v, repeat with c?'];
       Screen('FillRect',p.ptb.w,p.var.current_bg);
       DrawFormattedText(p.ptb.w, text, 'center', 'center',p.text.color,[],[],[],2,[]);
       t=Screen('Flip',p.ptb.w);
       Log(t,-1,99);
       k = 0;
       [~, k] = KbStrokeWait([]);
       k = find(k);
       if k == p.keys.el_calib
           return
       else
           RateShockIntensity;
       end
       fprintf('Continuing...\n');
       
       Screen('FillRect',p.ptb.w,p.stim.bg);
       Screen('Flip',p.ptb.w);
       WaitSecs(2);
       
    end
    function DeliverCostShocks(nTrial)
        error_count = sum(p.psi.log.wrong(p.presentation.block == p.presentation.block(nTrial-1)));
        text = ['Sie haben ' num2str(error_count) ' mal falsch geantwortet.\n'...
            'Es folgt nun die entsprechende Anzahl an elektrischen Reizen.\n'...
            'Sie m�ssen hier nichts tun.\n'];
        pressesForShock = p.presentation.press2shock;
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center',p.text.color,[],[],[],2,[]);
        t=Screen('Flip',p.ptb.w);
        Log(t,-1,99);
        %show the messages at the experimenter screen
        fprintf('=========================================================\n');
        fprintf('Text shown to the subject:\n');
        fprintf(text);
        fprintf('=========================================================\n');
        WaitSecs(4);
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        t = Screen('Flip',p.ptb.w);
        nShocks=round(error_count/pressesForShock);
        fprintf('\n\n Subject will get a total of %d shocks.\n',nShocks)
        WaitSecs(rand(1)+2);
        if nShocks >=1;
            for i=1:nShocks
                now = GetSecs;
                TimeEnd = now + p.duration.shock;
                Log(now,5,99);
                fprintf('Shock No %d.',i)
                while GetSecs<TimeEnd
                    Buzz;
                end
                shjit = rand(1);
                fprintf('Waiting %4.2f secs between shocks.\n',5+shjit)
                WaitSecs(5+shjit);
            end
        end
        fprintf('All shocks done, short pause of 2 secs...\n')
        wait(2000)
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
    function SetupLog
        
        p.psi.log.nTrial   =  NaN(1,p.presentation.total_trials);
        p.psi.log.signal   =  NaN(1,p.presentation.total_trials);
        p.psi.log.x        =  NaN(1,p.presentation.total_trials);
        p.psi.log.x_abs    =  NaN(1,p.presentation.total_trials);
        p.psi.log.ref      =  NaN(1,p.presentation.total_trials);
        p.psi.log.response =  NaN(1,p.presentation.total_trials);
        p.psi.log.signal   =  NaN(1,p.presentation.total_trials);
        p.psi.log.sdt      =  NaN(1,p.presentation.total_trials);
        p.psi.log.RT       =  NaN(1,p.presentation.total_trials);
        p.psi.log.wrong    =  NaN(1,p.presentation.total_trials);
    end

    function SetLog(nTrial,response,signal,sdt,RT,wrong)
        p.psi.log.nTrial = nTrial;
        p.psi.log.signal(nTrial) = signal;
        p.psi.log.x(nTrial)          = p.presentation.sdelta(nTrial);
        p.psi.log.x_abs(nTrial)      = p.presentation.delta(nTrial);
        p.psi.log.ref(nTrial)        = p.presentation.nCS(nTrial);
        p.psi.log.response(nTrial)   = response;
        p.psi.log.signal(nTrial)     = signal;
        p.psi.log.sdt(nTrial)        = sdt;%1=hit 2=FA 3=miss 4=CR
        p.psi.log.RT(nTrial)         = RT;
        p.psi.log.wrong(nTrial)      = wrong;
        
        
    end
    function Log(ptb_time, event_type, event_info)
        %Phases:
        %Instruction          :     0
        %Test                 :     1
        %Rating               :     5
        %Calibration          :     0
        %
        %event types are as follows:
        %         %Pulse Detection      :     0    info: NaN;
        %         %Tracker Onset        :     1
        %         %Trial Start          :     1    info: nTrial
        %         %Stim Onset           :     2    info: index
        %         %Mask Onset           :     3    info: position
        %         %Cross (pain) Onset   :     3    info: position
        %         %Ramp down Onset      :     4    info: ror
        %         %Treatment Plateau    :     5    info: temp
        %         %Ramp back onset      :     6    info: ror;
        %         %Key Presses          :     7    info: keycode;
        %         %Tracker Offset       :     8    info: NaN;
        %         %Rate pain Onset		:     9    info: nTrial;
        %         %Rate pain Offset     :     10   info: nTrial;
        %         %Rate treat Onset     :     11   info: nTrial;
        %         %Rate treat Offset    :     12   info: nTrial;
        %         %Face Onset           :     13   info: dist;
        %         %Face Offset          :     14   info: dist;
        %         %FaceStim Fixcross    :     15   info: position
        %         %Tonic Pain reached   :     16   info: nTrial
        %         %FX Cross Jump        :     17   info: position
        %         %dummy fixflip        :     22   info: NaN;
        %         planned trialstart    :     30   info: NaN
        %         planned trialend      :     31   info: NaN
        %Text on the screen   :     -1    info: Which Text?
        %VAS Onset            :     -2    info: NaN;
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

    function [t]=StartEyelinkRecording(trialID,phase,cc,tt,current_chain,isref,file,delta_ref,delta_csp,abs_FGangle,fixx,fixy)
        
        t = [];
        
        
        Eyelink('Message', 'TRIALID:%04d, PHASE:%04d, CHAIN:%04d, CHAINTRIAL:%04d, TTRIAL:%04d, ISREF:%04d, FILE:%04d, DELTAREF:%04d, DELTACSP:%04d, FGDEG:%04d, FXX:%04d, FXY:%04d',trialID, phase,...
            current_chain, cc, tt, isref, file, delta_ref*100, delta_csp*100, abs_FGangle*100,fixx,fixy);
        % an integration message so that an image can be loaded as
        % overlay background when performing Data Viewer analysis.
        WaitSecs(0.01);
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p.stim.files(file,:), p.ptb.midpoint(1), p.ptb.midpoint(2));
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('Command', 'record_status_message "Stim: %d, Phase: %d"',file, phase);
        %
        %Put the tracker offline and draw the stimuli.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        %draw the image on the screen
        Eyelink('ImageTransfer',p.stim.files24(file,:),p.ptb.imrect(1),p.ptb.imrect(2),p.ptb.imrect(3),p.ptb.imrect(4),p.ptb.imrect(1),p.ptb.imrect(2));
        Eyelink('Command', 'draw_cross %d %d %d',p.ptb.midpoint(1),p.ptb.CrossPositionET_y(1),p.ptb.fc_size);
        Eyelink('Command', 'draw_cross %d %d %d',p.ptb.midpoint(1),p.ptb.CrossPositionET_y(2),p.ptb.fc_size);
        %
        %drift correction
        %EyelinkDoDriftCorrection(el,crosspositionx,crosspositiony,0,0);
        %start recording following mode transition and a short pause.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('StartRecording');
        
        t = GetSecs;
        Log(t,8,NaN);
    end

    function [t] = StopEyelinkRecording
        
        Eyelink('Message', 'Stim Offset');
        Eyelink('Message', 'BLANK_SCREEN');
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
        
        Log(t,-8,NaN);
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
        %         for i=1:32
        %         filename       = p.stim.files24(nStim,:);
        %                 [im , ~, ~]    = imread(filename);
        %         end
        %
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
        %PsychEyelinkDispatchCallback(el)
        
        % open file.
        res = Eyelink('Openfile', p.path.edf);
        if res == -3
            fprintf('File cannot be created!!!!\n');
            return;
        end
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearCloud Experiment''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
        Eyelink('command', 'calibration_type = HV5');
        Eyelink('command','auto_calibration_messages = YES');
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
            WaitSecs(0.5);
            Eyelink('Closefile');
            display('receiving the EDF file...');
            Eyelink('ReceiveFile',filename,[p.path.subject '\eye\'],1);
            display('...finished!')
            % Shutdown Eyelink:
            Eyelink('Shutdown');
        catch
            display('StopEyeLink routine didn''t really run well');
        end
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

    function cleanup
        
        % Close window:
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'triostim1')
            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        %         %IOPort('ConfigureSerialPort', p.com.serial,' StopBackgroundRead');
        %         %IOPort('Close',p.com.serial);
        %         commandwindow;
        %         ListenChar(0);
        %         KbQueueRelease(p_ptb_device);
    end

end
