function [p,Log]=feargenET_PFfitting_YN(subject,   csp_degree)

% Diskrimination Task estimating the Threshold alpha and Slope beta of an
% observer's underlying Psychometric Function (PF).
% Enter the subject Number as well as the CS+ Face in Degrees (where 00 is
% 1st face, and so)
simulation_mode = 1;
p = [];
SetParams;
SetPTB;



%Set up running fit procedure:

%% Define prior, these are always the same so defining once is enough.
prioraaRange    = linspace(0,100,50); %values of aa to include in prior
%IS THIS RANGE OF BETA VALUES REASONABLE?
priorBetaRange  = linspace(-2,0,50);  %values of log_10(beta) to include in prior
%Range of lapse rates for the marginalized estimation of lambda
%Prins(2013) uses 0:0.01:0.1;
priorLambdaRange = 0:0.01:0.05;
%Range of guess rates (Prins: 0:0.03:0.3);
priorGammaRange = 0:0.03:0.3;
% Stimulus values to select from (need not be equally spaced)
stimRange       = 0:11.25:100;


% %2-D Gaussian prior
% prior = repmat(PAL_pdfNormal(priorAlphaRange,60,60),[length(priorBetaRange) 1]).* repmat(PAL_pdfNormal(priorBetaRange',0,4),[1 length(priorAlphaRange)]);
% 
% prior = prior./sum(sum(prior)); %prior should sum to 1


%Termination after n Trials
numtrials      = 60;
% percentage of obligatory x=0 trials
p0=.2;
% numtrials  = numtrials0+numtrials0*p0;

% make a break every ....th Trial
breakpoint=70;
%Function to be fitted during procedure
PFfit = @PAL_CumulativeNormal;    %Shape to be assumed

%set up procedure
PM = [];
face_shift   = [0 180 0 180];
circle_shift = [0 0 360 360];
circle_id    = [1 1 2 2]*p.stim.tFace/2;
tchain = 1;
% counter for within chain trials (cc) and global trials (tt)
cc=zeros(1,tchain);
tt=0; 

for nc = 1:tchain
%set up procedure
PM{nc} = PAL_AMPM_setupPM('priorAlphaRange',prioraaRange,'priorBetaRange',...
    priorBetaRange, 'priorLambdaRange', priorLambdaRange,'priorGammaRange',...
    priorGammaRange,'numtrials',numtrials, 'PF' , PFfit, 'stimRange',stimRange,...
    'marginalize', [3 4]);

% 
PM{nc}.reference_face   = face_shift(nc);
PM{nc}.reference_circle = circle_shift(nc);
if p0 ~= 0
zerotrials(:,nc)=randsample([1:numtrials],ceil(numtrials*p0));
% zerotrials(:,nc)=[1 3 5 7 9 11 13 15 17];
end
% set up Log Variable
SetupLog(nc);
end

ShowInstruction(3);

OK = 1;
while OK
    
    current_chain = randsample(1:tchain,1);
    
    
    if PM{current_chain}.stop ~= 1
        tt=tt+1;
        % enter in Break Loop
            if (tt~=1 && mod(tt,breakpoint)==1 && simulation_mode==0);
                ShowInstruction(4);
            end
        cc(current_chain)=cc(current_chain)+1;
        fprintf('Chain %4.2f , Trial %02d\n',current_chain,cc)
        fprintf('Original PM.x: %4.2f \n',PM{current_chain}.x(cc))
        % manually force x=0 trial, if it fits the zerotrial condition
        if p0 ~= 0
           if any(zerotrials(:,current_chain)==cc(current_chain))
             fprintf('Forcing x=0 Trial...\n')
             PM{current_chain}.xCurrent=0;
             PM{current_chain}.x(cc)=0;
            
           end
        end
        fprintf('PM.x is now %4.2f ',PM{current_chain}.x(cc))
       
        %Present trial here at stimulus intensity PM.xCurrent and collect
        %response
        direction = randsample([-1 1],1);
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
        
%         fprintf('Chain: %03d\nxCurrent: %6.2f\nDirection:%6.2f\n %6.2f -> %6.2f vs. %6.2f\n',current_chain,PM{current_chain}.xCurrent,direction,dummy,test,ref);
%        start Trial
        fprintf('Starting Trial %03d/%03d.\n',tt,tchain*numtrials)
        
        [test_face, ref_face, signal] = Trial_YN(ref,test,circle_id(current_chain));
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
            response = ObserverResponseFunction(PFfit,true_a,1/true_s,true_g,true_l,PM{current_chain}.xCurrent);
            
                    
                       
        end
        
  
     
        % store everything in the Log
        row                                     = round(PM{current_chain}.xCurrent/p.stim.delta+1);
        Log.trial_counter(row,current_chain)   = Log.trial_counter(row,current_chain) + 1;
        Log.xrounded(row,Log.trial_counter(row,current_chain),current_chain) = response;
        
    
        %updating PM
        PM{current_chain} = PAL_AMPM_updatePM(PM{current_chain},response);
        SetLog;
        %iteration control
        dummy = cell2mat(PM);
        OK    = sum([dummy(:).stop]) ~= tchain;
    end
    

    %save Logfile here
   
    save([p.path.path_param 'Log' num2str(subject) '.mat'],'Log'); 
  

  
end
ShowInstruction(2);
%Print summary of results to screen
for chain=1:tchain
fprintf('Chain %g: Estimated Threshold (alpha): %4.2f \n',chain,PM{chain}.threshold(end));
fprintf('Chain %g: Estimated Slope (beta): %4.2f \n',chain,PM{chain}.slope(end));
end
save([p.path.dropbox 'Log' num2str(subject) '.mat'],'Log')
% save PF Fit Plot
feargenET_PFfitting_Fitplot(num2str(subject),Log)
%clear the screen
%close everything down
cleanup;
%move the folder to appropriate location
movefile(p.path.subject,p.path.finalsubject);

    

    function  [test_face, ref_face, signal] = Trial_YN(ref_stim,test_stim,last_face_of_circle)
        %         computes the trial FACES, using the test/ref information input
        %         values (in Deg)
        
        trial = [ref_stim test_stim]/p.stim.delta;
        % correct face number within circle
        
        %         trial      = round(mod(trial,last_face_of_circle)+1);
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
        %transform degrees to sprite indices:
        sprite_index = [100 trial(1) NaN 100 trial(2) NaN];
        faces_trial = trial;
        
%         fprintf('...Chain: %02d \n',current_chain)
%         fprintf('...xDelta: %4.2f Degrees.\n',PM{current_chain}.xCurrent*direction)
%         fprintf('...Faces Trial: '),fprintf('%02d %02d\n',faces_trial(1),faces_trial(2))
        onsets     = p.trial.onsets + GetSecs;
        
        for i = 1:length(sprite_index)
            %create the pink noise sprite
            if sprite_index(i) == 100
                pink_noise              = repmat(Image2PinkNoise(p.stim.stim(:,:,1)),[1 1 3]);%correct this
                p.ptb.stim_sprites(100) = Screen('MakeTexture', p.ptb.w, pink_noise );
            end
            % write the image to the buffer if not gray
            if i ~= 3 && i~=6
                Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(sprite_index(i)));
            end
            %show image.
            Screen('Flip',p.ptb.w,onsets(i),0);
            
        end
        
        
        %   what is that?
        %         Screen('DrawTexture', p.ptb.w, p.ptb.stim.sprites(stim_id));
        %         Screen('Flip',p.ptb.w,TimeStimOnset,0)
    end

    function SetPTB
    debug =0;
        %Open a graphics window using PTB
        screens       =  Screen('Screens');
        screenNumber  =  max(screens);
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
        %area of the slider
        p.ptb.rect                  = [p.ptb.midpoint(1)*0.5  p.ptb.midpoint(2)*0.8 p.ptb.midpoint(1) p.ptb.midpoint(2)*0.2];
        %compute the cross position.
        [nx ny bb] = DrawFormattedText(p.ptb.w,'+','center','center');
        Screen('FillRect',p.ptb.w,p.stim.bg);
        p.ptb.cross_shift           = [45 50];%upper and lower cross positions
        p.ptb.CrossPosition_y       = [ny-p.ptb.cross_shift(1)  ny+p.ptb.cross_shift(2) ];
        p.ptb.CrossPosition_x       = [bb(1) bb(1)];
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        %
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
    end
    function SetParams
    
        %
        p.var.timings                 = zeros(1,10);
        p_var_event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\onat\Experiments\';
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\PsychToolbox\Documents\onat\Experiments\';
        else
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        end
        
        p.path.experiment             = [p.path.baselocation 'FearGeneralization_Ethnic\'];
        p.path.stimfolder             = 'ethno_pilote\64faces';
        p.path.stim                   = [p.path.baselocation 'Stimuli\Gradients\' p.path.stimfolder '\'];
        %
        p.subID                       = sprintf('sub%02d',subject);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '_' timestamp '\' ];
        p.path.dropbox                = ['C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\DiscriminationTask\pilotedata\data'];
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
        p.duration.stim                = 0.35;%s     
        p.duration.pink                = .2;
        p.duration.gray                = .2;
        if simulation_mode
            p.duration.stim                = .001;%s
            p.duration.pink                = .001;
            p.duration.gray                = .001;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %create the randomized design
        p.stim.cs_plus                 = csp_degree;%index of cs stimulus, this is the one paired to shock
%         p.stim.cs_neg                  = csn;
      

        event_onsets = 0.15;
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.gray];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        

        p.trial.onsets = event_onsets;
%         p.out.rating                  = [];
%         p.out.log                     = zeros(numtrials*4,4).*NaN;

        %Save the stuff
        save(p.path.path_param,'p');
        %

  end
    function [rating]=RatingSlider(rect,tSection,position,up,down,confirm,labels,message1,message2,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [nx ny bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
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
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.2,rect(2), p.stim.white);
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


    function [text]=GetText(nInstruct);
        
        
        if nInstruct == 1
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
            text = ['Experiment beendet!\n'];
            
        elseif nInstruct==4%break
            text = [sprintf('Du hast bereits %g von %g Durchgängen geschafft!\n',tt-1,numtrials*tchain)...
                'Mache eine kurze Pause.\n'...
                'Drücke anschließend die mittlere Taste, um weiterzumachen.\n'];
        end
    end
       
    function SetupLog(nc)
        
        
        Log.globaltrial= NaN(nc,numtrials);
        Log.signal     = NaN(nc,numtrials);
        Log.x          = NaN(nc,numtrials);
        Log.refface    = NaN(nc,numtrials);
        Log.testface   = NaN(nc,numtrials);
        
        Log.response   = NaN(nc,numtrials);
        Log.alpha      = NaN(nc,numtrials);
        Log.seAlpha    = NaN(nc,numtrials);
        Log.beta       = NaN(nc,numtrials);
        Log.seBeta     = NaN(nc,numtrials);
        Log.gamma      = NaN(nc,numtrials);
        Log.seGamma    = NaN(nc,numtrials);
        Log.lambda     = NaN(nc,numtrials);
        Log.seLambda   = NaN(nc,numtrials);
        Log.xrounded   = NaN(p.stim.tFace/tchain+1,numtrials,nc);
        Log.trial_counter  = zeros(p.stim.tFace/tchain+1,nc);
        
    end

    function SetLog
        
        
        Log.globaltrial(current_chain,cc(current_chain))= tt;
        Log.signal(current_chain,cc(current_chain))     = signal;
        Log.x(current_chain,cc(current_chain))          = PM{current_chain}.x(cc(current_chain))*direction;
        Log.refface(current_chain,cc(current_chain))    = ref_face;
        Log.testface(current_chain,cc(current_chain))   = test_face;
        Log.response(current_chain,cc(current_chain))   = response;
        Log.alpha(current_chain,cc(current_chain))      = PM{current_chain}.threshold(end);
        Log.seAlpha(current_chain,cc(current_chain))    = PM{current_chain}.seThreshold(end);
        Log.beta(current_chain,cc(current_chain))       = PM{current_chain}.slope(end);
        Log.seBeta(current_chain,cc(current_chain))     = PM{current_chain}.seSlope(end);
        Log.gamma(current_chain,cc(current_chain))      = PM{current_chain}.guess(end);
        Log.seGamma(current_chain,cc(current_chain))    = PM{current_chain}.seGuess(end);
        Log.lambda(current_chain,cc(current_chain))     = PM{current_chain}.lapse(end);
        Log.seLambda(current_chain,cc(current_chain))   = PM{current_chain}.seLapse(end);
        
    end
%     function PlotProcedure
%         plotproc=figure(1);
%         %         title(sprintf('Threshold Estimation for subject %02d',tchain),'FontSize',14)
%         for sub=1:tchain;
%             subplot(2,2,sub)
%             t = 1:length(Log.x(sub));
%             hold on;
%             plot(t,abs(Log.x(sub)),'bo-');
%             errorbar(t,Log.alpha(sub),Log.seAlpha(sub),'r--')
%             plot(t(Log.response(sub) == 1),Log.x(sub)(Log.response(sub) == 1),'ko', ...
%                 'MarkerFaceColor','k');
%             plot(t(Log.response(sub) == 0),Log.x(sub)(Log.response(sub) == 0),'ko', ...
%                 'MarkerFaceColor','w');
%             
%             set(gca,'FontSize',12);
%             axis([0 max(t)+1 0 max(Log{sub}.alpha)+max(Log{sub}.seAlpha)+20])
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
%             t = 1:length(Log{sub}.x);
%             hold on;
%             plot(t,abs(Log{sub}.x),'bo-');
%             errorbar(t,Log{1}.alpha,Log{1}.seAlpha,'r--')
%             plot(t(Log{sub}.response == 1),Log{sub}.x(Log{sub}.response == 1),'ko', ...
%                 'MarkerFaceColor','k');
%             plot(t(Log{sub}.response == 0),Log{sub}.x(Log{sub}.response == 0),'ko', ...
%                 'MarkerFaceColor','w');
%             
%             set(gca,'FontSize',12);
%             axis([0 max(t)+1 0 max(Log{sub}.alpha)+max(Log{sub}.seAlpha)+20])
%             xlabel('Trial');
%             ylabel('xCurrent (Deg)');
%             
%         end
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
