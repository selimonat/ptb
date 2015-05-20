function [p]=exp_feargen_PFfitting_YN(subject,phase,csp_degree)

% Diskrimination Task estimating the Threshold alpha and Slope beta of an
% observer's underlying Psychometric Function (PF).
% Enter the subject Number as well as the CS+ Face in Degrees (where 00 is
% 1st face, and so)
simulation_mode = 0;

ListenChar(2);%disable pressed keys to be spitted around
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

InitEyeLink;
WaitSecs(2);
%calibrate if we are at the scanner computer.
if strcmp(p.hostname,'triostim1') || strcmp(p.hostname,'etpc');
     CalibrateEL;
end

%save again the parameter file
save(p.path.path_param,'p');

% make a break every ....th Trial
breakpoint=50;


% counter for within chain trials (cc) and global trials (tt)
cc=zeros(1,tchain);
tt=0; 


for nc = 1:tchain
%set up procedure
PM{nc} = PAL_AMPM_setupPM('priorAlphaRange',p.psi.prioraaRange,'priorBetaRange',...
    p.psi.priorBetaRange, 'priorLambdaRange', p.psi.priorLambdaRange,'priorGammaRange',...
    p.psi.priorGammaRange,'numtrials',p.psi.numtrials, 'PF' , p.psi.PFfit, 'stimRange',p.psi.stimRange,...
    'marginalize', [3 4]);

% 
PM{nc}.reference_face   = face_shift(nc);
PM{nc}.reference_circle = circle_shift(nc);
if p.psi.p0 ~= 0

shuffledummy=Shuffle(1:p.psi.numtrials);
p.psi.zerotrials(:,nc)=shuffledummy(1:ceil(p.psi.numtrials*p.psi.p0));
end
% set up Log Variable
SetupLog(nc);
end

ShowInstruction(1);

OK = 1;
while OK
    
    current_chain = RandSample(1:tchain,[1 1]);
    
    
    if PM{current_chain}.stop ~= 1
        tt=tt+1;
        % enter in break loop
            if (tt~=1 && mod(tt,breakpoint)==1 && simulation_mode==0);
                ShowInstruction(4);
                ShowInstruction(1);
                CalibrateEL;
            end
        cc(current_chain)=cc(current_chain)+1;
        fprintf('Chain %4.2f , Trial %02d\n',current_chain,cc(current_chain))
        fprintf('Original PM.x: %4.2f \n',PM{current_chain}.x(cc(current_chain)))
        % manually force x=0 trial, if it fits the zerotrial condition
        if p.psi.p0 ~= 0
           if any(p.psi.zerotrials(:,current_chain)==cc(current_chain))
             fprintf('Forcing x=0 Trial...\n')
             PM{current_chain}.xCurrent=0;
             PM{current_chain}.x(cc(current_chain))=0;
            
           end
        end
        fprintf('PM.x is now %4.2f \n',PM{current_chain}.x(cc(current_chain)))
       
        %Present trial here at stimulus intensity PM.xCurrent and collect
        %response
        direction = RandSample([-1 1],[1 1]);
        test      = PM{current_chain}.xCurrent * direction + PM{current_chain}.reference_face + csp_degree + PM{current_chain}.reference_circle;
        dummy = test;
        % the computed degree has to stay in the same circle:
        % whenever it goes left from the 00 degrees (360 at foreign),
        % there's a problem
        % for chain 1 and 2, values below 0  have to be shifted 360 degrees,
        % for chain 3 and 4, values below 360 have to be shifted 360 degrees
        % e.g., -45 has to be 315 in chain 1; 315 has to be 675 in chain 3
        % was done using mod... adding (0 0 360 360) (this is the last part)
        test      = mod(test,360)+ PM{current_chain}.reference_circle;
        
        % the reference is one of the four faces
        %(cs+ local, cs- local, cs+ foreign, cs- forein)
        ref       = PM{current_chain}.reference_face + csp_degree + PM{current_chain}.reference_circle;
        ref       = mod(ref,360)+ PM{current_chain}.reference_circle;
        
        % fprintf('Chain: %03d\nxCurrent: %6.2f\nDirection:%6.2f\n %6.2f -> %6.2f vs. %6.2f\n',current_chain,PM{current_chain}.xCurrent,direction,dummy,test,ref);
        % start Trial
        fprintf('Starting Trial %03d/%03d.\n',tt,tchain*p.psi.numtrials)
      
        [test_face, ref_face, signal] = Trial_YN(ref,test,circle_id(current_chain),tt);
      
        fprintf('Rating.\n')
        %Rating Slider
        %
        message1 = 'Waren die Gesichter unterschiedlich oder gleich?\n';
        message2 = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätige deine Einschätzung mit der oberen Pfeiltaste.';
        if ~simulation_mode
            [response_subj]      = RatingSlider(p.ptb.rect,2,Shuffle(1:2,1),p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'unterschiedlich' 'gleich'},message1,message2,0);
            
            % see if subject found the different pair of faces...
            % buttonpress left (Yes) is response_subj=2, right alternative (No) outputs a 1.
            if (response_subj == 2 && signal == 1)
                response=1;
%                 fprintf('...Hit. \n')
            elseif (response_subj==1 && signal == 1)
                response=0;
%                 fprintf('...Miss. \n')
            elseif (response_subj == 2 && signal==0)
                response=1;
%                 fprintf('...False Alarm. \n')
            elseif (response_subj == 1 && signal == 0)
                response=0;
%                 fprintf('...Correct Rejection. \n')
            else
%                 fprintf('error in the answer algorithm! \n')
            end
            
        else
            true_a = 45;
            true_s = 10;
            true_g = 0.2;
            true_l = 0.02;
            response = ObserverResponseFunction(p.psi.PFfit,true_a,1/true_s,true_g,true_l,PM{current_chain}.xCurrent);
            
                    
                       
        end
        
  
     
        % store everything in the Log
        row                                     = round(PM{current_chain}.xCurrent/p.stim.delta+1);
        p.psi.log.trial_counter(row,current_chain)    = p.psi.log.trial_counter(row,current_chain) + 1;
        p.psi.log.xrounded(row,p.psi.log.trial_counter(row,current_chain),current_chain) = response;
        
    
        %updating PM
        PM{current_chain} = PAL_AMPM_updatePM(PM{current_chain},response);
        SetLog;
        %iteration control
        dummy = cell2mat(PM);
        OK    = sum([dummy(:).stop]) ~= tchain;
    end
    
    
    %save Logfile here
    
    %save([p.path.path_param 'Log' num2str(subject) '.mat'],'p.psi.log');
    
    %save again the parameter file
    save(p.path.path_param,'p');

end
ShowInstruction(2);
%Print summary of results to screen
for chain=1:tchain
fprintf('Chain %g: Estimated Threshold (alpha): %4.2f \n',chain,PM{chain}.threshold(end));
fprintf('Chain %g: Estimated Slope (beta): %4.2f \n',chain,PM{chain}.slope(end));
end

%get the eyelink file back to this computer
StopEyelink(p.path.edf);


%save([p.path.dropbox 'Log' num2str(subject) '.mat'],'p.psi.log')
% save PF Fit Plot
%feargenET_PFfitting_Fitplot(num2str(subject),p.log)


%clear the screen
%close everything down
cleanup;
%move the folder to appropriate location
movefile(p.path.subject,p.path.finalsubject);

    

    function  [test_face, ref_face, signal] = Trial_YN(ref_stim,test_stim,last_face_of_circle,tt)
        % computes the trial FACES, using the test/ref information input
        % values (in Deg)
        
        trial = [ref_stim test_stim]/p.stim.delta;
        % correct face number within circle
        trial      = mod(round(trial),last_face_of_circle)+1;
        ref_face   = trial(1);
        test_face  = trial(2);
        trial      = Shuffle(trial);
        %compute if trial had different faces or not
        %if trial(1)=trial(2), they were the same and subject has to
        %answer with 'no' (right option, is 1), else means correct hit
        
        if trial(1)==trial(2)
            signal = 0;
        else
            signal = 1;
        end
   
        %create two pink noise textures
        pink_noise   = Image2PinkNoise(p.stim.stim(:,:,trial(1)));
        pink_noise   = repmat((pink_noise-mean(pink_noise(:))).*p.ptb.tw+mean(pink_noise(:)),[1 1 3]);
        p.ptb.stim_sprites(p.stim.tFile+1) = Screen('MakeTexture', p.ptb.w, pink_noise);
        pink_noise   = Image2PinkNoise(p.stim.stim(:,:,trial(2)));
        pink_noise   = repmat((pink_noise-mean(pink_noise(:))).*p.ptb.tw+mean(pink_noise(:)),[1 1 3]);
        p.ptb.stim_sprites(p.stim.tFile+2) = Screen('MakeTexture', p.ptb.w, pink_noise);
        %sprite_index = [pink_noise FixationCross trial(1) FixationCross pink_noise trial(2) NaN];
        
        %get fixation crosses and onsets from p parameter
        fix        = round(p.ptb.CrossPositions(tt,:));
        
        StartEyelinkRecording(tt,phase,trial(1),fix(1),fix(2));
        
        %GetSecs so that the onsets can be defined
        onsets     = p.trial.onsets + GetSecs;
        %pink_noise 1
        
        Screen('DrawTexture', p.ptb.w,p.ptb.stim_sprites(p.stim.tFile+1));
        Eyelink('Message', 'Pink Noise 1 Onset');
        Screen('Flip',p.ptb.w,onsets(1),0);
       
        %fixation cross 1
        Screen('DrawTexture', p.ptb.w,p.ptb.stim_sprites(p.stim.tFile+1));
        Screen('DrawText', p.ptb.w, double('+'),fix(1),fix(2), p.stim.white);
        Eyelink('Command', 'draw_cross %d %d',fix(1),fix(2));
        Eyelink('Message', 'FX 1 Onset at %d %d',fix(1),fix(2));
        Screen('Flip',p.ptb.w,onsets(2),0);
       
        %face trial(1)
        Screen('DrawTexture',p.ptb.w,p.ptb.stim_sprites(trial(1)));
        Eyelink('Message', 'Stim 1 Onset');
        Screen('Flip',p.ptb.w,onsets(3),0);
       
        StopEyelinkRecording;
        
        %second face of the trial
        StartEyelinkRecording(tt,phase,trial(2),fix(3),fix(4));
        %pink_noise 2
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(p.stim.tFile+2));
        Eyelink('Message', 'Pink Noise 2 Onset');
        Screen('Flip',p.ptb.w,onsets(4),0);
        
        %fixation cross 2
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(p.stim.tFile+2));
        Screen('DrawText', p.ptb.w, double('+'), fix(3),fix(4), p.stim.white);
        Eyelink('Message', 'FX Onset 2 at %d %d',fix(3),fix(4));
        Eyelink('Command', 'draw_cross %d %d 15',fix(3),fix(4));
        Screen('Flip',p.ptb.w,onsets(5),0);
       
        %face trial(2)
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(trial(2)));
        Eyelink('Message', 'Stim 2 Onset');
        Screen('Flip',p.ptb.w,onsets(6),0);
        while GetSecs<onsets(7)
        end
        StopEyelinkRecording;
    end
    

    function SetPTB
    debug =0;
        %Open a graphics window using PTB
        screens       =  Screen('Screens');
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        
        if strcmp(p.hostname,'etpc')
           screenNumber=1;
        else
           screenNumber=max(screens);
        end
        
       
        %make everything transparent for debuggin purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        %
        [p.ptb.w ]                  = Screen('OpenWindow', screenNumber, p.stim.bg);
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', screenNumber);
        %find the mid position.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.stim.width p.stim.height];
        %area of the slider
        p.ptb.rect                  = [p.ptb.midpoint(1)*0.5  p.ptb.midpoint(2)*0.8 p.ptb.midpoint(1) p.ptb.midpoint(2)*0.2];
        %compute the cross position.
        [nx ny bb] = DrawFormattedText(p.ptb.w,'+','center','center');
        Screen('FillRect',p.ptb.w,p.stim.bg);
%         p.ptb.cross_shift           = [45 50];%upper and lower cross positions
%         p.ptb.CrossPosition_y       = [ny-p.ptb.cross_shift(1)  ny+p.ptb.cross_shift(2) ];
%         p.ptb.CrossPosition_x       = [bb(1) bb(1)];
%         p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
%         p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
         p.ptb.CrossPositions   = FixationCrossPool;     

        Priority(MaxPriority(p.ptb.w));
        
        for nStim = 1:p.stim.tFile
                filename       = p.stim.files(nStim,:);
                [im , ~, ~]    = imread(filename);
                %what is this good for?
                if ndims(im) == 3
                    p.stim.stim(:,:,nStim)    = rgb2gray(im);
                else
                    p.stim.stim(:,:,nStim)    = im;
                end
                p.ptb.stim_sprites(nStim)     = Screen('MakeTexture', p.ptb.w, im );
        end
        p.stim.delta = 720/p.stim.tFile;
        
        %create tukeywindow for the pink noise fadeout
        w  =.3;
        p.ptb.tw = tukeywin(p.stim.height,w)*tukeywin(p.stim.height,w)';
        
        
        function  [cross_positions]=FixationCrossPool
            radius   = 590; %in px (around 14 degrees (37 px/deg))
            center   = [800 600];
            
            %setting up fixation cross pool vector of size
            % totaltrials x 4 (face_1_x face_1_y face_2_x face_2_y)
            cross_directions = round(rand(tchain*p.psi.numtrials,2))*180;
            dummy            = cross_directions + rand(tchain*p.psi.numtrials,2)*30-15;
            cross_positions  = [cosd(dummy(:,1))*radius+center(1) sind(dummy(:,1))*radius+center(2)...
                cosd(dummy(:,2))*radius+center(1) sind(dummy(:,2))*radius+center(2)];
        end
    end
 


    function SetParams
    
        %
        p.var.timings                 = zeros(1,10);
        p.var.event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\onat\Experiments\';
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        else
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        end
        
        p.path.experiment             = [p.path.baselocation 'feargen_master\'];
        p.path.stimfolder             = 'stim\32discrimination';
        p.path.stim                   = [p.path.experiment  p.path.stimfolder '\'];
        p.path.stim24                 = [p.path.experiment  p.path.stimfolder '\' '24bits' '\'];
        %
        p.subID                       = sprintf('sub%02d',subject);
        p.path.edf                    = char(sprintf([p.subID 'p%02d' ],phase));
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '_' timestamp '\' ];
        p.path.dropbox                = 'C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\DiscriminationTask\pilotedata\data';
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'pmf']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\' 'p.mat']);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
     
          dummy = dir([p.path.stim '*.bmp']);
            p.stim.files    = [repmat([fileparts(p.path.stim) filesep],length(dummy),1) vertcat(dummy(:).name)];
            p.stim.label = {dummy(:).name};  
        
        
        p.stim.tFile                  = size(p.stim.files,1);%number of different files
        p.stim.tFace                  = p.stim.tFile;%number of faces.
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
        p.text.fixationsize            = 60;
        %rating business
        p.rating.division              = 2;%number of divisions for the rating slider
        %
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
        else
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('up');
            p.keys.increase                = KbName('right');
            p.keys.decrease                = KbName('left');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
        end
        
       
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
%         1.5 0.5 0.5
        p.duration.stim                = 0.7;%s     
        p.duration.pink                = 0.7;%0.2
        p.duration.fix                 = 1.0;
        %p.duration.gray                = .1;
        if simulation_mode
            p.duration.stim                = .001;%s
            p.duration.pink                = .001;
            p.duration.fix                 = .001;
            %p.duration.gray                = .001;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %create the randomized design
        p.stim.cs_plus                 = csp_degree;%index of cs stimulus, this is the one paired to shock
        %p.stim.cs_neg                  = csn;
      

        event_onsets = 0.15;
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.fix];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.fix];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        %event_onsets = [event_onsets event_onsets(end)+p.duration.gray];

        p.trial.onsets = event_onsets;
%         p.out.rating                  = [];
%         p.out.log                     = zeros(p.psi.numtrials*4,4).*NaN;


        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %priors for the PSI fitting structure PM
        
        %% Define prior, these are always the same so defining once is enough.
        p.psi.prioraaRange    = linspace(0,100,50); %values of aa to include in prior
        %IS THIS RANGE OF BETA VALUES REASONABLE?
        p.psi.priorBetaRange  = linspace(-2,0,50);  %values of log_10(beta) to include in prior
        %Range of lapse rates for the marginalized estimation of lambda
        %Prins(2013) uses 0:0.01:0.1;
        p.psi.priorLambdaRange = 0:0.01:0.05;
        %Range of guess rates (Prins: 0:0.03:0.3);
        p.psi.priorGammaRange = 0:0.03:0.3;
        % Stimulus values to select from (need not be equally spaced)
        p.psi.stimRange       = 0:11.25:100;
        %Function to be fitted during procedure
        p.psi.PFfit = @PAL_CumulativeNormal;    %Shape to be assumed
        
        %Termination after n Trials
        p.psi.numtrials      = 50;
        % percentage of obligatory x=0 trials
        p.psi.p0  = .2;
        
        %set up procedure
        PM = [];
        face_shift   = [0 180 0 180];
        circle_shift = [0 0 360 360];
        circle_id    = [1 1 2 2]*p.stim.tFace/2;
        tchain = 2;

        
   

        
     





        %Save the stuff
        save(p.path.path_param,'p');
        %

  end
    function [rating]=RatingSlider(rect,tSection,position,up,down,confirm,labels,message1,message2,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [nx, ny, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
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
                    rating   = tSection - position + 1;
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
            rating               = tSection - position + 1;
            increment([up down]) = [1 -1];%delta
            tick_x               = linspace(rect(1),rect(1)+rect(3),tSection+1);%tick positions
            tick_size            = rect(3)./tSection;
            ss                   = tick_size/5*0.9;%slider size.
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize./2);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p.stim.white);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.6,rect(2), p.stim.white);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.2,rect(2), p.stim.white);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message1, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize./2);
            DrawFormattedText(p.ptb.w,message2, 'center', p.ptb.midpoint(2)*0.4,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            Screen('Flip',p.ptb.w);
        end
    end

    function shuffled = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end

    function ShowInstruction(nInstruct)
        
        [text]=GetText(nInstruct);
        ShowText(text);
        %let subject read it and ask confirmation to proceed.
        
        KbStrokeWait;
        
        Screen('FillRect',p.ptb.w,p.stim.bg);
        Screen('Flip',p.ptb.w);
        
    end
    function ShowText(text)
        
        
        Screen('FillRect',p.ptb.w,p.stim.bg);
        %DrawFormattedText(p.ptb.w, text, p.text.start_x, 'center',p.stim.white,[],[],[],2,[]);
        DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        
        %show the messages at the experimenter screen
        fprintf([repmat('=',1,50) '\n']);
        fprintf('Subject''s monitor:\n');
        fprintf(text);
        fprintf([repmat('=',1,50) '\n']);
        
    end


    function [text]=GetText(nInstruct)
        
        if nInstruct == 0%Eyetracking calibration
                
                text = ['Um Deine Augenbewegungen zu messen, \n' ...
                        'müssen wir jetzt den Eye-Tracker kalibrieren.\n' ...
                        'Dazu zeigen wir Dir einige Punkte auf dem Bildschirm, \n' ...
                        'bei denen Du Dich wie folgt verhältst:\n' ...
                        'Bitte fixiere das Fixationskreuz und \n' ...
                        'bleibe so lange darauf, wie es zu sehen ist.\n' ...
                        'Bitte drücke jetzt den mittleren Knopf, \n' ...
                        'um mit der Kalibrierung weiterzumachen.\n' ...
                    ];
        
        elseif nInstruct == 1
            text = ['Du siehst nun nacheinander zwei Gesichter.\n'...
                '\n'...
                'Danach wirst Du gefragt, ob die Gesichter unterschiedlich oder gleich waren.\n'...
                '\n'...
                'Benutze dazu die Pfeiltasten (links, rechts) und die obere Taste zum Bestätigen.\n'...
                '\n'...
                'Wenn du noch Fragen hast, kannst du jetzt den Versuchsleiter fragen.\n'...
                '\n'...
                'Drücke ansonsten die mittlere Taste,\n'...
                '   um das Experiment zu starten.\n' ...
                ];
        elseif nInstruct == 3
            text = ['You will now see two faces after each other.\n'...
                '\n'...
                'Please state, if they were different (left) or the same (right).\n'...
                '\n'...
                'Use the arrow keys to move the marker and confirm with the UP button.\n'...
                '\n'...
                'Please press UP\n'...
                '   to start the experiment!\n' ...
                ];
        elseif nInstruct == 2%end
            text = 'Experiment beendet!\n';
            
        elseif nInstruct==4%break
            text = [sprintf('Du hast bereits %g von %g Durchgängen geschafft!\n',tt-1,p.psi.numtrials*tchain)...
                'Mache eine kurze Pause, aber halte Deinen Kopf in der gleichen Position!\n'...
                'Drücke anschließend die mittlere Taste, um weiterzumachen.\n'];
        end
    end
       
    function SetupLog(nc)
        
        
        p.psi.log.globaltrial= NaN(nc,p.psi.numtrials);
        p.psi.log.signal     = NaN(nc,p.psi.numtrials);
        p.psi.log.x          = NaN(nc,p.psi.numtrials);
        p.psi.log.refface    = NaN(nc,p.psi.numtrials);
        p.psi.log.testface   = NaN(nc,p.psi.numtrials);
        
        p.psi.log.response   = NaN(nc,p.psi.numtrials);
        p.psi.log.alpha      = NaN(nc,p.psi.numtrials);
        p.psi.log.seAlpha    = NaN(nc,p.psi.numtrials);
        p.psi.log.beta       = NaN(nc,p.psi.numtrials);
        p.psi.log.seBeta     = NaN(nc,p.psi.numtrials);
        p.psi.log.gamma      = NaN(nc,p.psi.numtrials);
        p.psi.log.seGamma    = NaN(nc,p.psi.numtrials);
        p.psi.log.lambda     = NaN(nc,p.psi.numtrials);
        p.psi.log.seLambda   = NaN(nc,p.psi.numtrials);
        p.psi.log.xrounded   = NaN(p.stim.tFace/tchain+1,p.psi.numtrials,nc);
        p.psi.log.trial_counter  = zeros(p.stim.tFace/tchain+1,nc);
        
    end

    function SetLog
        
        
        p.psi.log.globaltrial(current_chain,cc(current_chain))= tt;
        p.psi.log.signal(current_chain,cc(current_chain))     = signal;
        p.psi.log.x(current_chain,cc(current_chain))          = PM{current_chain}.x(cc(current_chain))*direction;
        p.psi.log.refface(current_chain,cc(current_chain))    = ref_face;
        p.psi.log.testface(current_chain,cc(current_chain))   = test_face;
        p.psi.log.response(current_chain,cc(current_chain))   = response;
        p.psi.log.alpha(current_chain,cc(current_chain))      = PM{current_chain}.threshold(end);
        p.psi.log.seAlpha(current_chain,cc(current_chain))    = PM{current_chain}.seThreshold(end);
        p.psi.log.beta(current_chain,cc(current_chain))       = PM{current_chain}.slope(end);
        p.psi.log.seBeta(current_chain,cc(current_chain))     = PM{current_chain}.seSlope(end);
        p.psi.log.gamma(current_chain,cc(current_chain))      = PM{current_chain}.guess(end);
        p.psi.log.seGamma(current_chain,cc(current_chain))    = PM{current_chain}.seGuess(end);
        p.psi.log.lambda(current_chain,cc(current_chain))     = PM{current_chain}.lapse(end);
        p.psi.log.seLambda(current_chain,cc(current_chain))   = PM{current_chain}.seLapse(end);
        
        
    end
%     function PlotProcedure
%         plotproc=figure(1);
%         %         title(sprintf('Threshold Estimation for subject %02d',tchain),'FontSize',14)
%         for sub=1:tchain;
%             subplot(2,2,sub)
%             t = 1:length(p.log.x(sub));
%             hold on;
%             plot(t,abs(p.log.x(sub)),'bo-');
%             errorbar(t,p.log.alpha(sub),p.log.seAlpha(sub),'r--')
%             plot(t(p.log.response(sub) == 1),p.log.x(sub)(p.log.response(sub) == 1),'ko', ...
%                 'MarkerFaceColor','k');
%             plot(t(p.log.response(sub) == 0),p.log.x(sub)(p.log.response(sub) == 0),'ko', ...
%                 'MarkerFaceColor','w');
%             
%             set(gca,'FontSize',12);
%             axis([0 max(t)+1 0 max(p.log{sub}.alpha)+max(p.log{sub}.seAlpha)+20])
%             xlabel('Trial');
%             ylabel('xCurrent (Deg)');
%             
%         end
%         annotation('textbox', [0 0.9 1 0.1], 'String',...
%             (sprintf('Threshold Estimation for subject %02d',tchain)), ...
%             'EdgeColor', 'none', ...
%             'HorizontalAlignment', 'center','FontSize',14)
%         legend('xCurrent','estimated Threshold','Response = 1','Response = 0','Location','northeast');
%       
% %     end
%     function Plot_Fit
%         plotfit=figure(2);
%          for sub=1:tchain;
%             subplot(2,2,sub)
%             t = 1:length(p.log{sub}.x);
%             hold on;
%             plot(t,abs(p.log{sub}.x),'bo-');
%             errorbar(t,p.log{1}.alpha,p.log{1}.seAlpha,'r--')
%             plot(t(p.log{sub}.response == 1),p.log{sub}.x(p.log{sub}.response == 1),'ko', ...
%                 'MarkerFaceColor','k');
%             plot(t(p.log{sub}.response == 0),p.log{sub}.x(p.log{sub}.response == 0),'ko', ...
%                 'MarkerFaceColor','w');
%             
%             set(gca,'FontSize',12);
%             axis([0 max(t)+1 0 max(p.log{sub}.alpha)+max(p.log{sub}.seAlpha)+20])
%             xlabel('Trial');
%             ylabel('xCurrent (Deg)');
%             
%         end

function [t]=StartEyelinkRecording(tt,phase,trialface,fixx,fixy)
        t = [];
        
        Eyelink('Message', 'Trial: %03d, Phase: %02d, Face: %d ,FX %d,%d', tt, phase, trialface, fixx,fixy);
        % an integration message so that an image can be loaded as
        % overlay background when performing Data Viewer analysis.
        WaitSecs(0.01);
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p.stim.files(trialface,:), p.ptb.midpoint(1), p.ptb.midpoint(2));
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('Command', 'record_status_message "Stim: %d, Phase: %d"',trialface, phase);
        %
        %Put the tracker offline and draw the stimuli.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        %draw the image on the screen
        Eyelink('ImageTransfer',p.stim.files24(trialface,:),p.ptb.imrect(1),p.ptb.imrect(2),p.ptb.imrect(3),p.ptb.imrect(4),p.ptb.imrect(1),p.ptb.imrect(2));
      
        %Eyelink('Command', 'draw_cross %d %d',fix(1),fix(2))
        %
        %drift correction
        %EyelinkDoDriftCorrection(el,crosspositionx,crosspositiony,0,0);
        %start recording following mode transition and a short pause.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('StartRecording');
        Screen('Textsize', p.ptb.w,p.text.fixationsize);
        t = GetSecs;
        Log(t,8,NaN);
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
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearGen2 Experiment''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
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
        ShowInstruction(0);
        EyelinkDoTrackerSetup(el);
        %Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s',messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')
end


function Log(ptb_time, event_type, event_info)
        %Phases:
        %Pre-Experiment       :     1
        %Post-Experiment      :     2
%         %Instruction          :     1
%         %Baseline             :     2
%         %Conditioning         :     3
%         %Test                 :     4
%         %Rating               :     5
%         %Calibration          :     0
        %
        %event types are as follows:
        %
        %Scan Detection       :     0    info: NaN;
        %Cross Onset          :     1    info: position
        %Stimulus Onset/Offset:     2/-2 info: stim_id
        %Cross Movement       :     3    info: NaN;
        %Stimulus Offset      :     -2   info: NaN;
        %UCS Delivery         :     4    info: NaN;
        %Key Presses          :     7    info: NaN;
        %Tracker Onset/Offset :     8    info: NaN;
        %
        %Text on the screen   :     5    info: Which Text?
        %RatingScreen Onset   :     6    info: NaN;
        
        p.var.event_count                = p.var.event_count + 1;
        p.out.log(p.var.event_count,:)   = [ptb_time event_type event_info phase];
        % %         p_out_log(p.out.event_counter,:)
        %logstring([ 'Logged: ' mat2str(p_out_log(p.out.event_counter,:)) ' - Type: ' p.verbose.eventtype{abs(event_type)} ' - Phase: ' p.verbose.eventphase{CurrentExperimentalPhase}])
        %for i = 1:3;subplot(3,1,i);plot(p_out_log(1:p.out.event_counter ,i),'o-');drawnow;end
        %
        
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
