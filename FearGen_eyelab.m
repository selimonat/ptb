function [p]=FearGen_eyelab(subject,NthSeq,phase,csp,PainThreshold)
%[p]=FearGen_eyelab(subject,NthSeq,phase,csp,PainThreshold)
%
%
%   Feargen presentation outside of the scanner, meaning that pulse
%   synchronisation feature is taken out. Eyetracker communication, pulse
%   logging to physio computer are left intact.

if nargin ~= 5
    fprintf('Wrong number of inputs\n');
    keyboard;
end
%change this if you like to use another sequence.
sequence_name = 'FeargenSequencer_130218_0343.mat';

% ListenChar(2);%disable pressed keys to be spitted around
commandwindow;
%clear everything
clear mex global functions
cgshut;
global cogent;
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);
%
el                        = [];
p                         = [];
SetParams;
debug                     = 0;%debug mode
SetPTB;
%
%init variables
t                         = [];
nTrial                    = 0;
%%
InitEyeLink;
WaitSecs(2);
%calibrate if we are at the scanner computer.
CalibrateEL;
%save again the parameter file
save(p.path.path_param,'p');
%
if phase == 1 %training part...
    
    p.var.ExpPhase  = phase;
    %
    ShowInstruction(4,1);
    ConfirmIntensity;
    %
    ShowInstruction(1,1);
    ShowInstruction(2,1);
    PresentStimuli;
    
elseif phase == 2
    %
    p.var.ExpPhase  = phase;
    ShowInstruction(5,1);%will wait for keypresses
    PresentStimuli;
    AskStimRating;
elseif phase == 3
    %
    p.var.ExpPhase  = phase;
    ShowInstruction(6,1);%will not wait for keypresses
    PresentStimuli;
    AskStimRating;
elseif phase == 4
    p.var.ExpPhase  = phase;
    %
    ShowInstruction(6,1);%will not wait for keypresses    
    PresentStimuli;

	AskStimRating
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
        KbStrokeWait;
        ShowInstruction(10,0);%shock is coming message...
        t = GetSecs + p.duration.shock;
        MarkCED( p.com.lpt.address, p.com.lpt.shock )
        while GetSecs < t;
            Buzz;
        end
        %
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und besttige deine Einschï¿½tzung mit der mit der oberen Pfeiltaste.';
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
        %
        TimeEndStim                 = GetSecs;
        for nTrial  = 1:p.presentation.tTrial;
            %
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            pos1         = p.ptb.CrossPosition_y(p.presentation.cross_position(nTrial));
            pos2         = p.ptb.CrossPosition_y(3-p.presentation.cross_position(nTrial));
            ISI          = p.presentation.isi(nTrial);
            ucs          = p.presentation.ucs(nTrial);
            oddball      = p.presentation.oddball(nTrial);
            prestimdur   = p.presentation.prestim_duration(nTrial);
            %
            fprintf('%d of %d, S: %d, ISI: %d, UCS: %d, ODD: %d.\n',nTrial,p.presentation.tTrial,stim_id,ISI,ucs,oddball);
            %
            
            OnsetTime     = TimeEndStim + ISI*2;
            
            %             jetz = GetSecs;
            %             if mod(nTrial,100) == 0
            %                ShowInstruction(15,1);
            %                OnsetTime = OnsetTime + GetSecs - jetz;
            %             end
            
            KbQueueStart(p.ptb.device);%monitor keypresses...
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim]= Trial(OnsetTime, prestimdur, stim_id , ucs  , pos1 , pos2, oddball);
            %
            [keypressed, firstPress]=KbQueueCheck(p.ptb.device);
            %if the press was after stimulus onset and before stimulus
            %offset
            if keypressed && (firstPress(p.keys.confirm) > OnsetTime) && (firstPress(p.keys.confirm) < TimeEndStim)
                p.out.response(nTrial) = 1;
                Log(firstPress(p.keys.confirm),7,NaN);%log the key press for hit detection.
                fprintf('Subject Pressed the Hit Key!!\n');
            end
            
        end
    end
function [TimeEndStim]=Trial2(TimeStimOnset , prestimdur, stim_id , pos1 )
        %For the ratings, shorter presentation
        
        %get all the times
        TimeCrossOnset     = TimeStimOnset  - prestimdur;
        TimeEndStim        = TimeStimOnset  + .5;
        
        %% Fixation Onset
        Screen('DrawText', p.ptb.w, double('+'), p.ptb.CrossPosition_x,pos1, p.stim.white);
        TimeCrossOn  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);        
        MarkCED( p.com.lpt.address, p.com.lpt.FixOnset );
        Eyelink('Message', 'FX Onset at %03d',pos1);
        Log(TimeCrossOn,1,stim_id);%cross onset.        
        
        %% Draw the stimulus to the buffer
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        Screen('DrawText'   , p.ptb.w, double('+'), p.ptb.CrossPosition_x,pos1, p.stim.white);        
        Screen('DrawingFinished',p.ptb.w,0);
        
        %% STIMULUS ONSET        
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
        %send eyelink and ced a marker asap        
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset );        
        Log(TimeStimOnset,2,stim_id);%log the stimulus onset
        
        
        %% CROSS JUMPS        
        Log(TimeCrossJumpTime,3,NaN);%log the fixation cross move
        
        %% UCS
        Screen('DrawingFinished',p.ptb.w,0);                
        
        %% STIM OFF immediately
        TimeEndStim = Screen('Flip',p.ptb.w,TimeEndStim,0);                
        Log(TimeEndStim,-2,stim_id);%log the stimulus offset        
    end


    function [TimeEndStim]=Trial(TimeStimOnset , prestimdur, stim_id , ucs  , pos1 , pos2, oddball )
        %get all the times
        TimeCrossOnset     = TimeStimOnset  - prestimdur;
        TimeCrossJumpTime  = TimeStimOnset  + p.duration.crossmoves - p.ptb.slack;
        TimeEndStim        = TimeStimOnset  + p.duration.stim;
        TimeStartShock     = TimeStimOnset  + p.duration.onset2shock;
        TimeTrackerOff     = TimeStimOnset  + p.duration.keep_recording;
        
        %% Fixation Onset
        Screen('DrawText', p.ptb.w, double('+'), p.ptb.CrossPosition_x,pos1, p.stim.white);
        TimeCrossOn  = Screen('Flip',p.ptb.w,TimeCrossOnset,0);        
        MarkCED( p.com.lpt.address, p.com.lpt.FixOnset );
        Eyelink('Message', 'FX Onset at %03d',pos1);
        Log(TimeCrossOn,1,stim_id);%cross onset.
        %turn the eye tracker on
        StartEyelinkRecording(stim_id,p.var.ExpPhase,oddball,ucs);
        
        %% Draw the stimulus to the buffer
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        Screen('DrawText'   , p.ptb.w, double('+'), p.ptb.CrossPosition_x,pos1, p.stim.white);
        if oddball%add freckles to the face
            x = randn(1,100)*35;
            y = randn(1,100)*10;
            s = rand(1,100);%[0 1]
            Screen('DrawDots',p.ptb.w,[x;y],1+s.*1.5,[180 0 0 160],p.ptb.midpoint,1);
            %the dots size
        end
        Screen('DrawingFinished',p.ptb.w,0);
        
        %% STIMULUS ONSET
        
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
        %send eyelink and ced a marker asap
        Eyelink('Message', 'Stim Onset');
        Eyelink('Message', 'SYNCTIME');
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset );
        if oddball
            MarkCED( p.com.lpt.address, p.com.lpt.oddball );
        end            
        Log(TimeStimOnset,2,stim_id);%log the stimulus onset
        
        
        %% CROSS JUMPS
        %Update the image on the buffer with the new cross_pos
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        Screen('DrawText'   , p.ptb.w, double('+'), p.ptb.CrossPosition_x, pos2, p.stim.white);
        if oddball == 1
            Screen('DrawDots',p.ptb.w,[x;y],1+s.*1.5,[180 0 0 160],p.ptb.midpoint,2);
        end
        Screen('DrawingFinished',p.ptb.w,0);
        
        TimeCrossJumpTime = Screen('Flip', p.ptb.w, TimeCrossJumpTime , 0);
        
        %send eyelink and ced a marker
        Eyelink('Message', 'FX Moves to %03d' ,pos2);
        Log(TimeCrossJumpTime,3,NaN);%log the fixation cross move
        
        %% UCS
        Screen('DrawingFinished',p.ptb.w,0);
        
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
        Log(TimeEndStim,-2,stim_id);%log the stimulus offset
        %
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        StopEyelinkRecording;
        
        if oddball == 1
            fprintf('This was an oddball trial!\n');
        end
        if ucs == 1
            fprintf('This was a UCS trial!\n');
            Log(TimeStartShock,4,NaN);%UCS delivery...This is done here to not waste time there
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
        
        if strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        elseif ismac
            p.path.baselocation       = '/Users/onat/Documents/BehavioralExperiments/';
        else
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        end
        p.path.experiment             = [p.path.baselocation '2015_05_feargen_revision' filesep];
        p.path.stimfolder             = ['stim' filesep 'Circle11_08Face_Frontal_SkinModerated_Transparent_Normalized'];
        p.path.stim                   = fullfile(p.path.experiment,p.path.stimfolder,filesep);
        %
        p.subID                       = sprintf('sub%02d',subject);
        p.path.edf                    = char(sprintf([p.subID 'p%02d' ],phase));
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data' filesep 'tmp' filesep p.subID '_' timestamp filesep];
        p.path.finalsubject           = [p.path.experiment 'data' filesep p.subID '_' timestamp filesep ];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);
        mkdir([p.path.subject 'eye']);
        mkdir([p.path.subject 'triads']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation' filesep 'param_phase_%02d'],phase);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.bmp']);
        p.stim.tFile                  = size(p.stim.files,1);%number of different files (including the UCS symbol)
        p.stim.tFace                  = p.stim.tFile - 1;%number of faces.
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
        %bg of the rating screen.
        p.stim.bg_rating               = [0 128 0];
        %
        %font size and background gray level
        p.text.fontname                = 'Times New Roman';
        if ismac
            p.text.fontsize                = 30;
        else
            p.text.fontsize                = 18;
        end
        %rating business (each entry in the vector is for one rating type, e.g. there cd be many ratings)
        
        p.rating.division              = [4];%number of divisions for the rating slider
        p.rating.repetition            = [2];%how many times a given face has to be repeated...
        p.rating.message               = [12];
        p.rating.slider_text           = [14];
        p.rating.tRating               = length(p.rating.repetition);
        %
        p.stim.white                   = [255 255 255];
        %get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        
        
        if ismac
            p.keys.confirm                 = KbName('UpArrow');
            p.keys.increase                = KbName('RightArrow');
            p.keys.decrease                = KbName('LeftArrow');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('ESCAPE');
        else
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('up');
            p.keys.increase                = KbName('right');
            p.keys.decrease                = KbName('left');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address              = 888;
        %codes for different events        
        %2 is empty because
        p.com.lpt.InitExperiment       = 64;
        p.com.lpt.FixOnset             = 4;
        p.com.lpt.StimOnset            = 8;
        p.com.lpt.shock                = 16;
        p.com.lpt.oddball              = 32;
        p.com.lpt.keypress             = 1;
        p.com.lpt.digitimer            = 128;
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 1.5;%s
        p.duration.shock               = 0.1;%s;x
        p.duration.shockpulse          = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse     = 0.01;%ms; and the time between each pulse
        p.duration.onset2shock         = p.duration.stim - p.duration.shock;
        p.duration.crossmoves          = p.duration.stim./2;
        p.duration.keep_recording      = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence
        dummy = load([p.path.experiment 'sequence' filesep sequence_name]);
        s                              = dummy.s;
        %create the randomized design
        p.stim.cs_plus                 = s(NthSeq,csp).cs_plus;%index of cs stimulus, this is the one paired to shock
        p.stim.cs_neg                  = s(NthSeq,csp).cs_neg;
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        %this will deal all the presentation sequence related information
        p.presentation                 = s(NthSeq,csp).phase(phase).presentation;
        %make the baseline shorter
        if phase == 2
            p.presentation.cond_id = p.presentation.cond_id(1:65);
            p.presentation.stim_id = p.presentation.stim_id(1:65);
            p.presentation.isi =  p.presentation.isi(1:65);
            p.presentation.prestim_duration = p.presentation.prestim_duration(1:65);
            p.presentation.cross_position = p.presentation.cross_position(1:65);
            p.presentation.oddball = p.presentation.oddball(1:65);
            p.presentation.ucs = p.presentation.ucs(1:65);                        
        end
        p.presentation.ucs             = double(p.presentation.ucs);
        p.presentation.oddball         = double(p.presentation.oddball);
        p.presentation.tTrial          = length(p.presentation.stim_id);         
        %
        p.out.rating                  = [];
        p.out.log                     = zeros(1000000,4).*NaN;
        p.out.response                = zeros(p.presentation.tTrial,1);
        p.out.PainThreshold           = PainThreshold;
        p.out.ShockFactor             = 1.5;
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
        
        MarkCED( p.com.lpt.address, p.com.lpt.InitExperiment );
        %
        p.var.ExpPhase = 5;
        BG             = p.stim.bg;%
        p.stim.bg      = p.stim.bg_rating;
        nseq           = 0;
        rating_seq     = [];
        %
        while nseq < p.rating.repetition
            nseq            = nseq + 1;
            rating_seq      = [ rating_seq     Shuffle(1:8)'];
        end                
        %
        Screen('FillRect', p.ptb.w , p.stim.bg);
        Screen('Flip',p.ptb.w);
        WaitSecs(2);
        %
        ShowInstruction(7,1);
        rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
        tRatend     = length(rating_seq);
        %save the rating sequence just for security
        p.out.rating_seq = rating_seq;
        
        for nRatend = 1:tRatend;
            %
            %the variable that are used by Trial function
            stim_id          = rating_seq(nRatend);
            pos1             = p.ptb.CrossPosition_y(2);
            pos2             = p.ptb.CrossPosition_y(1);
            %
            %We will turn on the fixation cross and start the tracker
            %for the first trial. These have to be done before the main
            %for loop.
            Screen('DrawText', p.ptb.w, double('+'), p.ptb.CrossPosition_x, pos1, p.stim.white);
            t  = Screen('Flip',p.ptb.w);
            %            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Mark the onset            
            Eyelink('Message', 'FX Onset at %03d',pos1);
            Log(t,1,pos1);%log the mark onset...            
            %
            if nRatend ~=1 
                ShowInstruction(77,1);
            end
            fprintf('============\nSubject is rating face %d \n', stim_id);
            Trial2(GetSecs+rand(1)*4,0.5,stim_id,pos1);
            %ask the question
            YesNoQuestion(nRatend);
            %run across ratings (this feature is added but not used here)...
            for rating_id = 1:p.rating.tRating
                TopMessage               = GetText(p.rating.message(rating_id));
                SliderTexts              = GetText(p.rating.slider_text(rating_id));
                rate(nRatend,rating_id)  = RatingSlider(rect, p.rating.division(rating_id), Shuffle(1:p.rating.division,1), p.keys.increase, p.keys.decrease, p.keys.confirm, SliderTexts,TopMessage,1);                
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Verbose the rating of the subject
            fprintf('============\nRating Results %d (%d/%d):\n', stim_id, nRatend, tRatend);
            dummy = rating_seq(1:nRatend);%trials shown so far
            for iii = 1:p.stim.tFile-1
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
        for rating_id = 1:p.rating.tRating
            p.out.rating{rating_id} = reshape(rate(:,rating_id),p.rating.repetition(rating_id),length(rating_seq)./p.rating.repetition(rating_id))';
        end
        save(p.path.path_param,'p');
        Screen('FillRect',p.ptb.w,p.stim.bg);
        p.stim.bg = BG;
        %
        save(p.path.path_param,'p');
    end
    function YesNoQuestion(nRatend)
        %
        %% Draw the question and arrows
        Screen('TextSize',p.ptb.w, 120);
        unicodetext = double(['Ja | Nein']);
        [nx ny]     = DrawFormattedText(p.ptb.w, unicodetext, 'center', 'center',p.stim.white,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        %
        Screen('TextSize',p.ptb.w, p.text.fontsize);
        %Wait for key press in a tight loop        
        while 1
            [isDown, secs, keyCode, deltaSecs] = KbCheck;
            if keyCode(p.keys.increase) || keyCode(p.keys.decrease)
                MarkCED( p.com.lpt.address, p.com.lpt.keypress );
                break;
            end
        end        
        code_binary([p.keys.decrease p.keys.increase]) = [1 0];
        code_label{p.keys.decrease} = 'Ja';
        code_label{p.keys.increase} = 'Nein';                
        %store the data
        p.out.yesno_label{nRatend}  = code_label{find(keyCode)};
        p.out.yesno_binary(nRatend) = code_binary(find(keyCode));
        fprintf('Subjects says %s...\n',p.out.yesno_label{nRatend});
    end
    function [rating] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:length(labels)
            [~ , ~, bb(nlab,:)]  = DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
            bb_size_h(nlab)      = bb(nlab,3)-bb(nlab,1);%vertical size of the bb.
            bb_size_v(nlab)      = bb(nlab,4)-bb(nlab,2);%vertical size of the bb.
            Screen('FillRect',p.ptb.w,p.stim.bg);
        end
        bb_max = max(bb);        
        %
        DrawSkala;
        ok = 1;        
        while ok == 1
            [secs, keyCode, ~] = KbStrokeWait;
            keyCode            = find(keyCode);
            Log(secs,7,keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                if (keyCode == up) || (keyCode == down)
                    next = position + increment(keyCode);
                    if next < (tSection+1) && next > 0
                        position = position + increment(keyCode);
                        %rating   = tSection - position + 1;
                    end
                    DrawSkala;
                elseif keyCode == confirm
                    WaitSecs(0.1);
                    ok = 0;
                    Screen('FillRect',p.ptb.w,p.stim.bg);
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
                    Screen('TextSize', p.ptb.w,p.text.fontsize./2);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p.stim.white);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                
                if tick <= length(labels)
                    DrawFormattedText(p.ptb.w, labels{tick}, tick_x(tick) - bb_size_h(tick)/2 + tick_size/2 , rect(2)-50, p.stim.white);
                end                
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            t = Screen('Flip',p.ptb.w);
            Log(t,6,NaN);
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
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Log(t,-5,nInstruct);
        else
            if nInstruct ~= 10%this is for the Reiz kommnt
                KbStrokeWait;
            else
                WaitSecs(1+rand(1));
            end
        end
        
        
        function ShowText(text)
            
            Screen('FillRect',p.ptb.w,p.stim.bg);
            %DrawFormattedText(p.ptb.w, text, p.text.start_x, 'center',p.stim.white,[],[],[],2,[]);
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            Log(t,5,nInstruct);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');
            fprintf('=========================================================\n');
            fprintf(native2unicode(text));
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
                'bleiben Sie so lange darauf, wie er zu sehen ist.\n' ...
                'Bitte drücken Sie jetzt den mittleren Knopf, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
            
        elseif nInstruct == 1%first Instr. of the training phase.
            text = ['Wir werden nun als erstes einen Übungsdurchgang machen,\n' ...
                'damit Sie sich an Ihre Aufgabe gewöhnen können.\n' ...
                'In diesem Durchgang können Sie sich vollkommen sicher fühlen,\n' ...
                'es werden keine elektrischen Reize verabreicht.\n' ...
                'Eine wichtige grundsätzliche Regel ist, dass Sie das Fixationskreuz (das „+“)\n' ...
                'wenn es zu sehen ist mit Ihren Augen fixieren. \n' ...
                'Drücken Sie die mittlere Taste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 2%second Instr. of the training phase.
            text = ['Ein paar Bemerkungen zu den Zielreizen: \n' ...
                'Zur Erinnerung: Zielreize sind die Gesichter mit Sommersprossen.\n' ...
                'Sobald ein solcher Zielreiz erscheint, \n' ...
                'sollen Sie schnellstmöglich die mittlere Taste drücken, \n' ...
                'und zwar bevor der Reiz wieder verschwunden ist \n' ...
                '(Sie müssen also sehr schnell und aufmerksam sein).' ...
                ];
        elseif nInstruct == 3%third Instr. of the training phase.
            text = ['Es ist sehr wichtig, dass Sie Ihren Kopf während \n' ...
                'des Experiments nicht bewegen. \n' ...
                'Das ist besonders wichtig für die Qualität der Messung.\n' ...
                'Daher sollte Ihre Kopfhaltung so bequem wie möglich sein.\n' ...
                'Wenn es sich jetzt gerade nicht bequem anfühlt oder \n' ...
                'Sie das Bedürfnis haben, Ihre Position noch verändern zu wollen, \n' ...
                'ist jetzt der Moment, in dem Sie das tun können.\n' ...
                ];
        elseif nInstruct == 4%third Instr. of the training phase.
            text = ['Vor dem Übungsdurchgang legen wir nun \n' ...
                'die Schockintensität für den Rest des Experiments fest. \n' ...
                'Drücken Sie die mittlere Taste um fortzufahren.' ...
                ];
            
        elseif nInstruct == 5%Baseline Phase
            %
            %
            %=================================================================================================================%
            text = ['Jetzt geht es mit dem Experiment los.\n' ...
                'Ihre Aufgabe ist es jetzt, genauso wie im Training die Gesichter, \n' ...
                'die Ihnen gezeigt werden aufmerksam zu betrachten und \n' ...
                'den mittleren Knopf zu drücken, sobald Sie einen Zielreiz sehen.\n' ...
                '\n'...
                'Hin und wieder erscheint ein Symbol (ein Blitzpfeil, der vor Strom warnt), \n' ...
                'das einen elektrischen Reiz ankündigt. \n' ...
                'Die Reize erfolgen aber nur bei diesem Symbol, nicht bei den Gesichtern! \n' ...
                'Bei Gesichtern können Sie sich also sicher fühlen.\n' ...
                'Bitte denken Sie daran: 1. Folgen Sie immer den Fixationskreuz und 2. nicht bewegen!\n\n' ...
                'Drücken Sie die mittlere Taste, um zu starten. \n' ...
                ];
            
        elseif nInstruct == 6%Test and Conditioning Phase
            %=================================================================================================================%
            text = ['Auch im nun folgenden Teil des Experiments \n' ...
                'sollen Sie die Gesichter aufmerksam betrachten und \n' ...
                'den oberen Knopf drücken, sobald Sie einen Zielreiz sehen. \n' ...
                'Wie im ersten Teil des Experiments sollen Sie \n' ...
                'das Fixationskreuz immer fixieren. \n' ...
                'In dieser Phase des Experiments werden Sie\n' ...
                'gelegentlich elektrische Reize bekommen.\n\n' ...
                'Die elektrischen Reize folgen jetzt auf bestimmte Gesichter. \n' ...
                
                ];        
        
            
        elseif nInstruct == 7;%rating
            text = ['In dieser Phase hätten wir gerne, dass Sie die Gesichter\n'...
                'im Hinblick auf folgende Frage bewerten:\n\n'...
                '"Haben Sie bei diesem Gesicht elektrische Schocks erhalten?"\n\n'...
                'In diesem Teil werden Sie KEINE Schocks mehr bekommen! \n\n'...
                'Antworten Sie mit links für JA und mit rechts für NEIN.\n'...
                'Bitte folgen Sie auch hier dem Fixationskreuz.\n'...
                'Drücken Sie die obere Taste um zu starten.\n'...
                ];
            
        elseif nInstruct == 77;%rating
            text = ['Bitte beantworten Sie die folgende Frage:\n'...
                'Haben Sie bei diesem Gesicht Schocks erhalten?\n\n'...                
                'Beliebige Taste drücken, um das Gesicht zu sehen...\n'...
                'Bitte folgen Sie auch hier dem Fixationskreuz.\n' ...
                ];
            
            
        elseif nInstruct == 8 %CS+ detection
            text = ['Sie bekommen nun eine Reihe von Gesichtern gezeigt.\n' ...
                'Bitte wählen Sie das Gesicht aus bei dem der Schock verabreicht wurde.\n'...
                'Drücken Sie die mittlere Taste um fortzufahren.\n'...
                ];
        elseif nInstruct == 9%
            %=================================================================================================================%
            text = ['Bitte geben Sie an, ob die Reizstärke des folgenden Schocks\n für Sie erträglich ist.\n'...
                '\n'...
                'Drücken Sie bitte die mittlere Taste um den Reiz zu bekommen.\n'...
                ];
            
        elseif nInstruct == 10%just before the shock
            text = 'Reiz kommt...\n';
        elseif nInstruct == 11%this is the rating question
            text = ['Erhalten Sie bei diesem Gesicht einen elektrischen Schock?\n' ...
                'Antworten Sie mit links für JA und mit rechts für NEIN.\n' ...
                
                ];
        elseif nInstruct == 12%this is the rating question
            text = [' OK !\n'...
                'Bitte beantworten Sie als nächstes:\n\n'...
                'Wie sicher sind Sie sich? \n\n' ...
                'Bewegen Sie den "Zeiger" mit der rechten und linken Pfeiltaste\n' ...
                'und bestätigen Sie Ihre Einschaetzung mit der mit der oberen Pfeiltaste'...
                ];
        elseif nInstruct == 13 %These two below are the possible responses to the question in 11
            text = {'JA' 'NEIN' };
        elseif nInstruct == 14
            text = {'gar nicht' 'wenig' 'mittel' 'sehr'};
        elseif nInstruct == 15
            text = ['Pause.\n' ...
                'Drücken Sie die mittlere Taste um fortzufahren.\n'];
        else
            text = {''};
        end
    end
    function SetPTB
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Find the number of the screen to be opened
        screens                     =  Screen('Screens');
        p.ptb.screenNumber          =  1;%the maximum is the second monitor
        if ismac%for laptop with single monitor
            p.ptb.screenNumber      =0;
        end
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
        
        if strcmp(p.hostname,'etpc')
            p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,1600,1200);
            %hide the cursor
% %             HideCursor(p.ptb.screenNumber);
        end
        
        %Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        if sum([p.ptb.width p.ptb.height] - [1280 960]) ~= 0
            fprintf('SET THE CORRECT SCREEN RESOLUTION\n');
        end
        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.stim.width p.stim.height];
        %compute the cross position.
        [~, ny bb]                  = DrawFormattedText(p.ptb.w,'+','center','center');
        p.ptb.cross_shift           = [45 60];%incremental upper and lower cross positions
        p.ptb.CrossPosition_y       = [ny-p.ptb.cross_shift(1)  ny+p.ptb.cross_shift(2) ];
        p.ptb.CrossPosition_x       = bb(1);%always the same
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2)-p.ptb.cross_shift(2) p.ptb.midpoint(2)+p.ptb.cross_shift(2)];
        %%
        %priorityLevel=MaxPriority(['GetSecs'],['KbCheck'],['KbWait'],['GetClicks']);
        Priority(MaxPriority(p.ptb.w));
        %this is necessary for the Eyelink calibration
        InitializePsychSound(0)
        %sound('Open')
        Beeper(5000)
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.
        p.ptb.device        = -1;
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        config_io;
        outp(p.com.lpt.address,0);
        if( cogent.io.status ~= 0 )
            error('inp/outp installation failed');
        end
        %test whether CED receives the triggers correctly...
        k = 0;
        while k ~= 49;
            outp(p.com.lpt.address,p.com.lpt.InitExperiment);pause(0.1);outp(888,0);%247 means all but the UCS channel (so that we dont shock the subject during initialization).
            fprintf('=================\nDid the trigger test work?\nPress 0 to send it again, 1 to continue...\n')
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
        Log(t,-8,NaN);
    end
    function [t]=StartEyelinkRecording(nStim,phase,oddball,ucs)
        t = [];
        nStim = double(nStim);
        Eyelink('Message', 'TRIALID: %03d, PHASE: %02d, ODDBALL: %02d, UCS: %02d', nStim, phase, double(oddball), double(ucs));
        % an integration message so that an image can be loaded as
        % overlay background when performing Data Viewer analysis.
        WaitSecs(0.01);
        %return
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p.stim.files(nStim,:), p.ptb.midpoint(1), p.ptb.midpoint(2));
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('Command', 'record_status_message "Stim: %02d, Phase: %d"', nStim, phase);
        %
        %Put the tracker offline and draw the stimuli.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        %draw the image on the screen but also the two crosses
        if nStim <= 16
            Eyelink('ImageTransfer',p.stim.files(nStim,:),p.ptb.imrect(1),p.ptb.imrect(2),p.ptb.imrect(3),p.ptb.imrect(4),p.ptb.imrect(1),p.ptb.imrect(2));
        end
        Eyelink('Command', 'draw_cross %d %d 15',p.ptb.CrossPositionET_x(1),p.ptb.CrossPositionET_y(1) );
        Eyelink('Command', 'draw_cross %d %d 15',p.ptb.CrossPositionET_x(2),p.ptb.CrossPositionET_y(2) );
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
    function shuffled = Shuffle(vector,N)
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
        if EyelinkInit(debug)%use 0 to init normaly
            fprintf('=================\nEyelink initialized correctly...\n')
        else
            fprintf('=================\nThere is problem in Eyelink initialization\n')
            keyboard;
        end
        %
        WaitSecs(0.5);
        [~, vs] = Eyelink('GetTrackerVersion');
        fprintf('=================\nRunning experiment on a ''%s'' tracker.\n', vs );
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
        Eyelink('Openfile', p.path.edf);
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearGen2 Experiment''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
        Eyelink('command', 'calibration_type = HV9');
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
    function cleanup
        
        % Close window:
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'etpc')
            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        %         IOPort('ConfigureSerialPort', p.com.serial,' StopBackgroundRead');
        %         IOPort('Close',p.com.serial);
        commandwindow;
        ListenChar(0);
        try
         KbQueueRelease(p.ptb.device);
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
    function Log(ptb_time, event_type, event_info)
        %Phases:
        %Instruction          :     1
        %Baseline             :     2
        %Conditioning         :     3
        %Test                 :     4
        %Rating               :     5
        %Calibration          :     0
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
        %%
        %
        %   for x = 1:10
        %       disp(x)
        %   end
        %
        p.out.log(p.var.event_count,:)   = [ptb_time event_type event_info p.var.ExpPhase];
        % %         p.out.log(p.out.event_counter,:)
        %logstring([ 'Logged: ' mat2str(p.out.log(p.out.event_counter,:)) ' - Type: ' p.verbose.eventtype{abs(event_type)} ' - Phase: ' p.verbose.eventphase{CurrentExperimentalPhase}])
        %for i = 1:3;subplot(3,1,i);plot(p.out.log(1:p.out.event_counter ,i),'o-');drawnow;end
        %
        
    end


end
