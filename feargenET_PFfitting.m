function feargenET_PFfitting(subject,   csp_degree)

p = [];
SetParams;
SetPTB;
%Simulated observer's characteristics
PFsimul = @PAL_Gumbel;
trueParams = [0 2 0.5 0.01];

%Set up running fit procedure:

%% Define prior
alphas = linspace(0,90,400);
prior  = PAL_pdfNormal(alphas,0,400); %Gaussian
%%
%Termination rule
stopcriterion = 'trials';
stoprule      = 10;

%Function to be fitted during procedure
PFfit    = @PAL_Gumbel;    %Shape to be assumed
beta     = 2;               %Slope to be assumed
lambda   = 0.01;         %Lapse rate to be assumed
meanmode = 'mean';      %Use mean of posterior as placement rule

%set up procedure
RF = [];
face_shift  = [0 180 0 180];
circle_shift = [0 0 360 360];
for nc = 1:4
RF{nc} = PAL_AMRF_setupRF('priorAlphaRange', alphas, 'prior', prior,...
    'stopcriterion',stopcriterion,'stoprule',stoprule,'beta',beta,...
    'lambda',lambda,'PF',PFfit,'meanmode',meanmode);
    RF{nc}.reference_face   = face_shift(nc);
    RF{nc}.reference_circle = circle_shift(nc);
end
%need 4 PF, 1) cs+ local, 2)cs- local, 3) cs+ foreign, 4) cs-foreign
% random sequence of chains
chain_sequence = rand


%Trial loop
while RF{1}.stop ~= 1 && RF{2}.stop ~= 1 && RF{3}.stop ~= 1 && RF{4}.stop ~= 1
    
    current_chain = randsample(1:4,1);
    if RF{current_chain}.stop ~= 1
    %Present trial here at stimulus intensity UD.xCurrent and collect
    %response
    %Here we simulate a response instead (0: incorrect, 1: correct)  
    direction = randsample([-1 1],1);
    test      = RF{current_chain}.xCurrent * direction + RF{current_chain}.reference_face + csp_degree + RF{current_chain}.reference_circle;
    ref       = RF{current_chain}.reference_face + csp_degree + RF{current_chain}.reference_circle;
    %
            message = 'War der Reiz schmerzhaft oder nicht?\nBewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätige deine Einschätzung mit der mit der oberen Pfeiltaste.';

    [response]      = RatingSlider(p.ptb.rect,2,Shuffle(1:2,1),p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'erstes\nPaar' 'zweites\nPaar'},message,0);

    Trial_2IFC(ref,test);
    fprintf('Trial Finished...\n')

    response = rand(1) < PFsimul(trueParams,amplitude);    
    RF = PAL_AMRF_updateRF(RF{current_chain}, test, response); %updating RF
    end
end



    function Trial_2IFC(ref_stim,test_stim)
        trial      = Shuffle([ref_stim ref_stim ref_stim test_stim ])
        onsets     = p.trial.onsets + GetSecs;
        sprite_index = round([100 trial(1)/p.stim.delta+1 100 trial(2)/p.stim.delta+1 NaN 100 trial(3)/p.stim.delta+1 100 trial(4)/p.stim.delta+1 NaN ]);
        for i = 1:length(sprite_index) 
             fprintf('Trial: %03d...\n',sprite_index(i))
            %create the pink noise sprite
            if sprite_index(i) == 100
                pink_noise              = repmat(Image2PinkNoise(p.stim.stim(:,:,1)),[1 1 3]);%correct this
                p.ptb.stim_sprites(100) = Screen('MakeTexture', p.ptb.w, pink_noise );
            end
            % write the image to the buffer if not gray
            if i ~= 5
                Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(sprite_index(i)));
            end
            %show image.
            Screen('Flip',p.ptb.w,onsets(i),0);
        end
        %show PN
        %show 1-1 csp 
        %show PN
        %show 1-2 csp + delta
        %show BG
        %show PN
        %show 2-1 csp 
        %show PN
        %show 2-2 csp
        %show PN
        
        
        
        Screen('DrawTexture', p.ptb.w, p.ptb.stim.sprites(stim_id));
        Screen('Flip',p.ptb.w,TimeStimOnset,0);
        
        
    end

function SetPTB
    debug =1;
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
                p.stim.stim(:,:,nStim)    = rgb2gray(im);
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
        p.path.stimfolder             = 'ethno_pilote';
        p.path.stim                   = [p.path.baselocation 'Stimuli\Gradients\' p.path.stimfolder '\'];
        %
        p.subID                       = sprintf('sub%02d',subject);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '_' timestamp '\' ];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'pmf']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\param_pmf']);
        
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
        p.duration.stim                = 1.5;%s     
        p.duration.pink                = .5;
        p.duration.gray                = 2;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %create the randomized design
        p.stim.cs_plus                 = csp_degree;%index of cs stimulus, this is the one paired to shock
%         p.stim.cs_neg                  = csn;
      

        event_onsets = 0.15;
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.gray];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];
        event_onsets = [event_onsets event_onsets(end)+p.duration.pink];
        event_onsets = [event_onsets event_onsets(end)+p.duration.stim];

        p.trial.onsets = event_onsets;

        %Save the stuff
        save(p.path.path_param,'p');
        %

  end
    function [rating]=RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
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
            Screen('TextSize', p.ptb.w,p.text.fontsize./2);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
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

end
