function [p]=FearGen_eyelab(subject,phase,csp,PainThreshold)
%[p]=FearGen_eyelab(subject,phase,csp,PainThreshold)
%
%Used for fearamy project, based on the FearGen_eyelab code. It increments
%it by adding scanner pulse communications.
% 
% 

debug = 1;%debug mode
%replace parallel port function with a dummy function
if ismac
outp = @(x,y) fprintf('pp\n');
end
if nargin ~= 4
    fprintf('Wrong number of inputs\n');
    keyboard;
end

csn   = mod( csp + 8/2-1, 8)+1;
commandwindow;
%clear everything
clear mex global functions
if ~ismac
    cgshut;
    global cogent;
end
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);
%
el        = [];
p         = [];
SetParams;
SetPTB;
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

%save again the parameter file
save(p.path.path_param,'p');
if phase == 0
    %
    p.mrt.dummy_scan = 0;%for the training we don't want any pulses
    p.var.ExpPhase = phase;
    %UCS check    
    ShowInstruction(4,1);
    ConfirmIntensity;
    %test
    ShowInstruction(1,1);    
    ShowInstruction(101,1);    
    ShowInstruction(2,1);    
    PresentStimuli;
    
elseif phase == 1
    %
    p.var.ExpPhase  = phase;            
    CalibrateEL;
    ShowInstruction(3,1);
    PresentStimuli;    
    AskStimRating;%make sure that scanner doesnt stop prematurely asa the stim offset  
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
        [secs, keyCode, deltaSecs] = KbStrokeWait;
        ShowInstruction(10,0);%shock is coming message...
        t = GetSecs + p.duration.shock;
        MarkCED( p.com.lpt.address, p.com.lpt.shock );
        while GetSecs < t;
            Buzz;
        end
        %
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätige deine Einschätzung mit der mit der oberen Pfeiltaste.';
        rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
        response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nerträglich' 'erträglich'},message,0);
        if response == 2
            fprintf('All is fine :)\n');
            fprintf('Subject confirmed the shock intensity inside the scanner...\n')
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
        KbQueueStop;
        WaitSecs(.05);
        KbQueueCreate;
        KbQueueStart;
        %log the pulse timings.        
        TimeEndStim                 = secs(end);%take the first valid pulse as the end of the last stimulus.
        for nTrial  = 1:10%p.presentation.tTrial;

            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            fix_y        = p.presentation.CrossPosition(nTrial);
            ISI          = p.presentation.isi(nTrial);
            ucs          = p.presentation.ucs(nTrial);
            oddball      = p.presentation.oddball(nTrial);
            prestimdur   = p.duration.prestim+rand(1)*.25;
            dist         = p.presentation.dist(nTrial);
            %prestimdur   = p_presentation_prestim_dur(nTrial);                                    
            
            fprintf('%d of %d, S: %d, ISI: %d, UCS: %d, ODD: %d.\n',nTrial,p.presentation.tTrial,stim_id,ISI,ucs,oddball);
            %            
            OnsetTime     = TimeEndStim + ISI-p.duration.stim ;                                    
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim] = Trial(nTrial,OnsetTime, prestimdur, stim_id , ucs  , fix_y,  oddball,dist);
            %(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist )
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
        KbQueueRelease(p.ptb.device);
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        if p.var.ExpPhase > 0
            WaitPulse(p.keys.pulse,ceil(6./p.mrt.tr));%
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);        
    end
    function [TimeEndStim]=Trial(nTrial,TimeStimOnset , prestimdur, stim_id , ucs  , fix_i, oddball, dist )
        %get all the times
         TimeCrossOnset     = TimeStimOnset  - prestimdur;
         TimeCrossJump      = TimeStimOnset  + p.duration.stim/2;
         TimeEndStim        = TimeStimOnset  + p.duration.stim;
         TimeStartShock     = TimeStimOnset  + p.duration.onset2shock;
         TimeTrackerOff     = TimeStimOnset  + p.duration.keep_recording;                
         
         %% Fixation Onset       
         fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(fix_i)];
         FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
         Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
         Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
         
         Screen('DrawingFinished',p.ptb.w,0);
         TimeCrossOn  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);                  
         MarkCED( p.com.lpt.address, p.com.lpt.FixOnset );
         Eyelink('Message', 'FX Onset at %d %d',fix(1),fix(2));
         Log(TimeCrossOn,1,fix_i);%cross onset.                     
         %turn the eye tracker on
         StartEyelinkRecording(nTrial,stim_id,p.var.ExpPhase,dist,oddball,ucs,fix);                  
        %% Draw the stimulus to the buffer
        if ~stim_id==0
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        end
        %draw also the fixation cross
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');        
        Screen('DrawingFinished',p.ptb.w,0);
                
        %% STIMULUS ONSET                        
        %Here we wait only for the next pulse.
        %The proper amount is obtained with the second call of WaitPulse
        %below, before the onset of the fixation cross.
        %fprintf('Will Wait for the pulse to Stim Onset\n');
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
        %send eyelink and ced a marker asap
        Eyelink('Message', 'Stim Onset');
        Eyelink('Message', 'SYNCTIME');
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset ); 
        if oddball
            MarkCED( p.com.lpt.address, p.com.lpt.oddball );
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
            MarkCED( p.com.lpt.address, p.com.lpt.shock );
            Eyelink('Message', 'UCS Onset');
            
            while GetSecs < TimeEndStim;
                Buzz;%this is anyway sent to CED.
            end
            Eyelink('Message', 'UCS Offset');                       
        end
        
        %% STIM OFF immediately
        TimeEndStim = Screen('Flip',p.ptb.w,TimeEndStim,0);
        %send eyelink and ced a marker                
        Eyelink('Message', 'Stim Offset');            
        Eyelink('Message', 'BLANK_SCREEN');
        Screen('Textsize', p.ptb.w,p.text.fontsize);
        Log(TimeEndStim,6,stim_id);%log the stimulus offset
        %
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        TimeTrackerOff    = StopEyelinkRecording;
        

            if oddball == 1
                fprintf('This was an oddball trial!\n');
            end
            if ucs == 1
                fprintf('This was a UCS trial!\n');
                Log(TimeStartShock,5,NaN);%UCS delivery...This is done here to not waste time there
            end

    end

    function SetParams
        %mrt business
        p.mrt.dummy_scan              = 7;%this will wait until the 6th image is acquired.
        p.mrt.LastScans               = 5;%number of scans after the offset of the last stimulus
        p.mrt.tr                      = 1;%in seconds.
        %will count the number of events to be logged        
        p.var.event_count             = 0;        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\onat\Experiments\fearamy';
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        elseif ismac
            p.path.baselocation       = '/Users/onat/Desktop/fearamy';
        end
        
        p.path.experiment             = [p.path.baselocation  filesep];
        p.path.stim                   = [p.path.baselocation filesep 'stimuli' filesep];
        p.path.stim24                 = [p.path.stim '24bit' filesep];
        %
        p.subID                       = sprintf('sub%02d',subject);        
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment  'tmp' filesep p.subID '_' timestamp filesep ];
        p.path.finalsubject           = [p.path.experiment  p.subID '_' timestamp filesep ];
        p.path.path_edf               = [p.path.subject  'eye' filesep];
        p.path.edf                    = sprintf([p.subID 'p%02d.edf' ],phase);
        p.path.path_param             = [p.path.subject 'stimulation' filesep sprintf([p.subID 'p%02d.edf' ],phase)];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);
        mkdir([p.path.subject 'eye']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);                
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.bmp']);
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
        p.stim.bg_rating               = [0 128 0];
        p.stim.white                   = [255 255 255];        
        %% font size and background gray level
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;%30;
        p.text.fixsize                 = 60;
        %rating business
        p.rating.division              = 10;%number of divisions for the rating slider
        p.rating.repetition            = 2;%how many times a given face has to be repeated...
        %% get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        %% keys to be used during the experiment        
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner
        p.keys.confirm                 = KbName('4$');
        p.keys.increase                = KbName('1!');
        p.keys.decrease                = KbName('2@');                
        p.keys.pulse                   = KbName('5%');
        p.keys.el_calib                = KbName('v');
        p.keys.el_valid                = KbName('c');
        p.keys.escape                  = KbName('ESCAPE');
        p.keys.enter                   = KbName('return');
                
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address              = 888;
        %codes for different events
        p.com.lpt.InitExperiment       = 64;%which is all channels without digitimer
        p.com.lpt.FixOnset             = 4;
        p.com.lpt.StimOnset            = 8;
        p.com.lpt.shock                = 16;
        p.com.lpt.oddball              = 32;
        p.com.lpt.keypress             = 2;
        p.com.lpt.digitimer            = 128;
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
         %stimulus sequence                  
        if phase == 0        
            seq.cond_id       = Shuffle([0 1 2 3 4 5 6 7 8 9]);
            seq.tTrial        = length(seq.cond_id);
            seq.ucs           = zeros(1,seq.tTrial);
            seq.oddball       = seq.cond_id == 10;
            seq.isi           = RandSample([3 4.5],[1 seq.tTrial]);
            seq.stim_id       = seq.cond_id;            
            seq.dist          = 1:10;
            seq.CrossPosition = RandSample(1:2,[1 seq.tTrial]);
        elseif phase == 1                        
            load([fileparts(which('exp_FearAmy.m')) '/bin/fearamy_seq.mat']);
        end
        clear seqpool
        %create the randomized design
        p.stim.cs_plus                 = csp;%index of cs stimulus, this is the one paired to shock
        p.stim.cs_neg                  = csn;
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        %this will deal all the presentation sequence related information
        p.presentation                 = seq;     
            
        p.out.rating                  = [];
        p.out.log                     = zeros(1000000,4).*NaN;
        p.out.response                = zeros(p.presentation.tTrial,1);
        p.out.ShockFactor             = 2;
        %%
        p.out.PainThreshold           = PainThreshold;
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
        
        
        MarkCED( p.com.lpt.address, p.com.lpt.InitExperiment);
        p.var.ExpPhase   = 5;        
        p.var.current_bg = p.stim.bg_rating;
        %% create the order of presentation and balance the position of fixation cross
        nseq           = 0;
        rating_seq     = [];
        pos1_seq       = [];
        idx            = [];        
        face_order     = 1:p.stim.tFace
        pos_order      = Shuffle([0 0 0 0 1 1 1 1])
        while nseq < p.rating.repetition
            nseq                    = nseq + 1;        
            [dummy idx]             = Shuffle( face_order );
            rating_seq              = [rating_seq dummy];            
            %this balances both directions
            pos1_seq                = [pos1_seq double(pos_order(idx) == rem(nseq,2))+1];%+1 to make [0 1] --> [1 2]
        end         
        pos1_seq                = ones(1,16);
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
            Trial(1000+nRatend,GetSecs+1,0.5,stim_id,0,fix_y,0,dist);
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
            [secs, keyCode, ~] = KbStrokeWait;
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
                    MarkCED( p.com.lpt.address, p.com.lpt.keypress);
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
    function ShowInstruction(nInstruct,waitforkeypress)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, then subject has to press a button to
        %make the instruction text dissappear. Otherwise you have to take
        %care of it later
               
        [text]= GetText(nInstruct);
        ShowText(text);
        %let subject read it and ask confirmation to proceed. But we don't
        %need that in the case of INSTRUCT = 5;
        if waitforkeypress
            if nInstruct ~= 10%this is for the Reiz kommnt
                KbStrokeWait;
            else
                WaitSecs(2.5+rand(1));
            end
            Screen('FillRect',p.ptb.w,p.var.current_bg);
            t = Screen('Flip',p.ptb.w);            
        else
            if nInstruct ~= 10%this is for the Reiz kommnt
                KbStrokeWait;
            else
                WaitSecs(1+rand(1));
            end
        end
        
        
        function ShowText(text)
            
            Screen('FillRect',p.ptb.w,p.var.current_bg);
            %DrawFormattedText(p.ptb.w, text, p.text.start_x, 'center',p.stim.white,[],[],[],2,[]);
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            Log(t,-1,nInstruct);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');
            fprintf('=========================================================\n');
            fprintf(text);
            fprintf('=========================================================\n');
            
        end
    end
    function [text]=GetText(nInstruct)
             if nInstruct == 0%Eyetracking calibration
                
                text = ['Um Ihre Augenbewegungen zu messen, \n' ...
                        'müssen wir jetzt den Eye-Tracker kalibrieren.\n' ...
                        'Dazu zeigen wir Ihnen einige Punkte auf dem Bildschirm, \n' ...
                        'bei denen Sie sich wie folgt verhalten:\n' ...
                        'Bitte fixieren Sie den kleinen weißen Kreis und \n' ...
                        'bleiben so lange darauf, wie es zu sehen ist.\n' ...
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
                    'Drücken Sie die obere Taste um fortzufahren.\n' ...
                    ];
             elseif nInstruct == 101%first Instr. of the training phase.
                text = ['Eine wichtige grundsätzliche Regel ist auch hier,\n'...
                    'dass Sie das Fixationskreuz (das „+“)\n' ... 
                    'wenn es zu sehen ist, mit Ihren Augen fixieren. \n' ...
                    'Drücken Sie die obere Taste um fortzufahren.\n' ...
                    ];
            elseif nInstruct == 2%second Instr. of the training phase.
                text = ['Ein paar Bemerkungen zu den Zielreizen: \n' ...
                        'Zur Erinnerung: Zielreize sind die verschwommenen Gesichter.\n' ...
                        'Sobald ein solcher Zielreiz erscheint, \n' ...
                        'sollen Sie schnellstmöglich die obere Taste drücken, \n' ...
                        'und zwar bevor der Reiz wieder verschwunden ist \n' ...
                        '(Sie müssen also sehr schnell und aufmerksam sein).' ...
                    ];
            elseif nInstruct == 3%third Instr. of the training phase.
                text = ['Es ist sehr wichtig, dass Sie Ihren Kopf während \n' ...
                    'des Experiments nicht bewegen. \n' ...
                    'Das ist besonders wichtig für die Qualität der Messung.\n' ...
%                     'Also please note it is normal for the scanner to stop and restart...
%                     'This should however not interfer with your task.
%                     'Even if the scanner stops please follow the instructions as precisely as always...
                    ];
            elseif nInstruct == 4%third Instr. of the training phase.
                text = ['Vor dem Experiment legen wir nun \n' ...
                        'die Schockintensität für den Rest des Experiments fest. \n' ...
                        'Drücken Sie die obere Taste um fortzufahren.' ...
                    ];
             
            elseif nInstruct == 5%Baseline Phase
                %=================================================================================================================%
                text = ['Jetzt geht es mit dem Experiment los.\n' ...
                        'Ihre Aufgabe ist es jetzt, die Gesichter, \n' ...
                        'die Ihnen gezeigt werden aufmerksam zu betrachten und \n' ...
                        'den oberen Knopf zu drücken, sobald Sie einen Zielreiz sehen.\n' ...
                        '\n'...                        
                        'Bitte denken Sie daran: 1. Fixationskreuz fixieren und 2. nicht bewegen!\n\n' ...
                        'Sie können das Experiment nun durch Drücken der oberen Taste starten. \n' ...
                        'In dieser Phase des Experiments werden Sie\n' ...
                        'gelegentlich elektrische Reize bekommen.\n\n' ...
                        'Die elektrischen Reize folgen jetzt jedoch auf eins der Gesichter.\n' ...
                    ];
             elseif nInstruct == 6%In between runs
                %=================================================================================================================%
                text = ['Now we will have a little break...\n' ...
                        'Press a button when you want to go on...' ...
                       ];
                
            
            elseif nInstruct == 7;%rating
                text = ['In dieser Phase hätten wir gerne, dass Sie die Gesichter\n'... 
                        'im Hinblick auf folgende Frage bewerten:\n'...
                        '„Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                        'einen elektrischen Schock zu erhalten?“\n'...
                        'Bewegen Sie den Zeiger mit der rechten und linken Pfeiltaste \n'...
                        'und bestätigen Sie Ihre Einschätzung mit der oberen Pfeiltaste.\n'...                    
                    ];
                      
            elseif nInstruct == 8 %CS+ detection
                text = ['Du bekommen nun eine Reihe von Gesichtern gezeigt.\n' ...
                    'Bitte wählen Sie das Gesicht aus bei dem der Schock verabreicht wurde.\n'...
                    'Drücken Sie die obere Taste um fortzufahren.\n'...
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
                       'Bewegen Sie den "Zeiger" mit der rechten und linken Pfeiltaste\n' ... 
                       'und bestätigen Sie Ihre Einschätzung mit der mit der oberen Pfeiltaste'...
                       ];
            elseif nInstruct == 12 %These two below are the possible responses to the question in 11
                text = {'Sehr\nwahrscheinlich'};
            elseif nInstruct == 13
                text = {'Überhaupt\nnicht\nwahrscheinlich'};
             elseif nInstruct == 14
                 text = ['Bitte machen Sie eine kurze Pause.\n' ...
                         'Sie können hierbei gern die Augen einen Moment schließen.\n'...
                         'Drücken Sie anschließend die obere Taste um fortzufahren.\n'...
                         'Wir werden dann den Eyetracker noch einmal kalibrieren.\n'...
                         ];
            else
                text = {''};
            end
        end
    function SetPTB
        KbName('UnifyKeyNames');
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Find the number of the screen to be opened        
        screens                     =  Screen('Screens');
        p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor        
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %set the resolution correctly        
%         if strcmp(p.hostname,'triostim1') 
            res          = [1600 1200];
%             p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,res(1),res(2));
            %hide the cursor
            HideCursor(p.ptb.screenNumber);
%         elseif strcmp(p.hostname,'etpc')
%             res          = [1600 1200];
%             p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,res(1),res(2));
%             %hide the cursor
%             HideCursor(p.ptb.screenNumber);
%         end
        %spit out the resolution 
        if ~ismac
            fprintf('Resolution of the screen is set to %dx%d...\n',res(1),res(2));
        end
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
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.ptb.midpoint(1)-p.stim.width/2+p.stim.width p.ptb.midpoint(2)-p.stim.height/2+p.stim.height];       
        p.ptb.cross_shift           = [180 -120];%incremental upper and lower cross positions
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
               
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.
        p.ptb.device        = -1;
        %get all the required keys in a vector 
        p.ptb.keysOfInterest = [];for i = fields(p.keys)';p.ptb.keysOfInterest = [p.ptb.keysOfInterest p.keys.(i{1})];end         
        fprintf('Key listening will be restricted to %d\n',p.ptb.keysOfInterest)
%         RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        %create a queue sensitive to only relevant keys.
       % KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %prepare parallel port communication. This relies on cogent i
        %think. We could do it with PTB as well.
        if ~ismac            
            config_io;
            outp(p.com.lpt.address,0);
            if( cogent.io.status ~= 0 )
                error('inp/outp installation failed');
            end                    
        end

        %CORRECT
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %test whether CED receives the triggers correctly...
        k = 0;
        while ~(k == 25 || k == 86);
            outp(p.com.lpt.address,p.com.lpt.InitExperiment);
            pause(0.1);
            outp(p.com.lpt.address,0);%247 means all but the UCS channel (so that we dont shock the subject during initialization).
            fprintf('=================\nDid the trigger test work?\nPress c to send it again, v to continue...\n')
            [~, k] = KbStrokeWait;
            k = find(k);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the pictures to the memory.
        p.ptb.stim_sprites = CreateStimSprites(p.stim.files);%
        
        function [out]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:p.stim.tFile
                filename       = files(nStim,:);
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
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

    function [t]=StartEyelinkRecording(nTrial,nStim,phase,dist,oddball,ucs,fix)
        t = [];
        if isnan(dist)
            dist=3000;
        end
        nStim = double(nStim);
        Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, FILE: %04d, DELTACSP: %04d, ODDBALL: %04d, UCS: %04d, FIXX: %04d, FIXY %04d', nTrial, phase, nStim, dist, double(oddball), double(ucs),fix(1),fix(2));
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
           Eyelink('ImageTransfer',p.stim.files24(nStim,:),p.ptb.imrect(1),p.ptb.imrect(2),p.stim.width,p.stim.height,p.ptb.imrect(1),p.ptb.imrect(2));            
        end
        Eyelink('Command', 'draw_cross %d %d 15',fix(1),fix(2));
        
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
        %PsychEyelinkDispatchCallback(el)
                            
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
            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %       
        commandwindow;        
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
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
        %Stimulus Onset       :     3    info: stim_id
        %Cross Movement       :     4    info: NaN;
        %UCS Delivery         :     5    info: NaN;
        %Stimulus Offset      :     6    info: NaN;        
        %Key Presses          :     7    info: NaN;
        %Tracker Offset       :     8    info: NaN;
        %
        %Text on the screen   :     -1    info: Which Text?
        %RatingScreen Onset   :     -2    info: NaN;
        for iii = 1:length(ptb_time)
            p.var.event_count                = p.var.event_count + 1;
            p.out.log(p.var.event_count,:)   = [ptb_time(iii) event_type event_info(iii) p.var.ExpPhase];        
        end
        plot(p.out.log(1:p.var.event_count,1) - p.out.log(1,1),p.out.log(1:p.var.event_count,2),'o','markersize',10);        
        ylim([-2 8]);
        set(gca,'ytick',[-2:8],'yticklabel',{'Rating On','Text','Pulse','Tracker+','Cross+','Stim+','CrossMov','UCS','Stim-','Key+','Tracker-'});
        grid on
        drawnow;
        
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
        fprintf('Will wait for %i dummy pulses...\n',n);
        if n ~= 0
            secs  = nan(1,n);
            pulse = 0;
            dummy = [];
            while pulse < n
                dummy         = KbTriggerWait(keycode);
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
        fprintf('there are %03d events\n',KbEventAvail(p.ptb.device));
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet(p.ptb.device);
            n          = n + 1;
            keycode(n) = evt.Keycode;
            pressed(n) = evt.Pressed;
            secs(n)    = evt.Time;
            fprintf('Event is: %d\n',keycode(n));
        end
        i           = pressed == 1;
        keycode(~i) = [];
        secs(~i)    = [];
        fprintf('there are %03d events found...\n',length(keycode));
    end
end
