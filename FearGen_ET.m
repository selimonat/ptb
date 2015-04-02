function [p]=FearGen_ET(subject,phase,csp,PainThreshold)
%[p]=Conditioning(subject,NthSeq,CSpface,phase,PainThreshold)
%
%Used for the last recording (3rd Scan Request) sessions of the Feargen
%project. Mainly different in loading the precomputed sequences...

if nargin ~= 4
    fprintf('Wrong number of inputs\n');
    keyboard;
end
   
csp = [csp csp+8];
csn =  [mod( csp(1) + 8/2-1, 8)+1 mod( csp(2)-8 + 8/2-1, 8)+1+8 ];

ListenChar(2);%disable pressed keys to be spitted around
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
debug = 0;%debug mode
SetPTB;
%
%init all the variables
t                         = [];
nTrial                    = 0;
%%
%Time Storage
TimePulse1                = [];
TimePulse2                = [];
TimeStimOnset             = [];
TimeCrossJumpTime         = [];
TimeEndStim               = [];
TimeStartShock            = [];
TimeTrackerOff            = [];
TimeTrackerOn             = [];
TimeCrossOn               = [];   
p_var_ExpPhase            = [];
p_var_event_count         = 0;
p_out_log                 = p.out.log;
p_ptb_w                   = p.ptb.w;
p_ptb_stim_sprites        = p.ptb.stim_sprites;
p_ptb_CrossPosition_x     = p.ptb.CrossPosition_x;
p_ptb_imrect              = p.ptb.imrect;
p_ptb_CrossPositionET_x   = p.ptb.CrossPositionET_x;
p_ptb_CrossPositionET_y   = p.ptb.CrossPositionET_y;
p_ptb_slack               = p.ptb.slack;
p_stim_white              = p.stim.white;
p_ptb_midpoint            = p.ptb.midpoint;
p_com_lpt_address         = p.com.lpt.address;
p_com_lpt_StimOnset       = p.com.lpt.StimOnset;
p_com_lpt_UCS             = p.com.lpt.UCS;
p_com_lpt_FixOnset        = p.com.lpt.FixOnset;
p_com_lpt_FixMove         = p.com.lpt.FixMove;
p_com_lpt_StimOffset      =  p.com.lpt.StimOffset;

p_duration_shockpulse     = p.duration.shockpulse;
p_duration_crossmoves     = p.duration.crossmoves;
p_duration_stim           = p.duration.stim;
p_duration_onset2shock    = p.duration.onset2shock;
p_duration_keep_recording = p.duration.keep_recording;
p_duration_prestim        = p.duration.prestim;
p_stim_files              = p.stim.files;
p_duration_prestim_ori    = p.duration.prestim_ori;
p.com.serial              = p.com.serial;
%
p_presentation_cross_position = p.presentation.cross_position;
p_ptb_device                  = p.ptb.device;
p_keys_confirm                = p.keys.confirm;
%%
InitEyeLink;
WaitSecs(2);
%calibrate if we are at the scanner computer.
if strcmp(p.hostname,'triostim1') || strcmp(p.hostname,'etpc');
     CalibrateEL;
end
%save again the parameter file
save(p.path.path_param,'p');
%
if phase == 1 %training part...
    
    p.mrt.LastScans = 0;%scanner is off here, otherwise we will wait forever
    p_var_ExpPhase  = phase;
    %
    ShowInstruction(4,1);
    ConfirmIntensity;
    %
    ShowInstruction(1,1);
    ShowInstruction(2,1);
    ShowInstruction(3,1);
    PresentStimuli;
        
elseif phase == 2
    %
    p_var_ExpPhase  = phase;        
    ShowInstruction(5,1);%will wait for keypresses
    PresentStimuli;    
    AskStimRating;%make sure that scanner doesnt stop prematurely asa the stim offset
  
elseif phase == 3
    %
    p_mrt_on        = 0;
    p_var_ExpPhase  = phase;        
    %
    ShowInstruction(6,1);%will not wait for keypresses
    %
    PresentStimuli;
    %
    %makee sure that scanner doesnt stop prematurely asa the stim offset
    
elseif phase == 4
    p_mrt_on        = 0;
    p_var_ExpPhase  = phase;
    %  
    ShowInstruction(6,1);%will not wait for keypresses   
    PresentStimuli;
    %makee sure that scanner doesnt stop prematurely asa the stim offset
    AskStimRating;
    %makee sure that scanner doesnt stop prematurely asa the stim offset
    fprintf('Finished with the rating\n');
    %AskWhichFace;
end

%get the eyelink file back to this computer
StopEyelink(p.path.edf);
%trim the log file and save
p_out_log = p_out_log(sum(isnan(p_out_log),2) ~= size(p_out_log,2),:);
%shift the time so that the first timestamp is equal to zero
p_out_log(:,1) = p_out_log(:,1) - p_out_log(1);
p.out.log      = p_out_log;%copy it to the output variable.
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
        while GetSecs < t;
            Buzz;
        end
        %
        message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und besttige deine Einsch�tzung mit der mit der oberen Pfeiltaste.';
        rect        = [p.ptb.width*0.2  p_ptb_midpoint(2) p.ptb.width*0.6 100];
        response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nertr�glich' 'ertr�glich'},message,0);
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
            p_presentation_stim_id   = p.presentation.stim_id;            
            p_ptb_CrossPosition_y    = p.ptb.CrossPosition_y;
            p_presentation_isi       = p.presentation.isi;
            p_presentation_ucs       = p.presentation.ucs;
            p_presentation_oddball   = p.presentation.oddball;
            %                 
        for nTrial  = 1:p.presentation.tTrial;
            %            
            %Get the variables that Trial function needs.
            stim_id      = p_presentation_stim_id(nTrial);
            pos1         = p_ptb_CrossPosition_y(p_presentation_cross_position(nTrial));
            pos2         = p_ptb_CrossPosition_y(3-p_presentation_cross_position(nTrial));
            InNPulse     = p_presentation_isi(nTrial);
            ucs          = p_presentation_ucs(nTrial);
            oddball      = p_presentation_oddball(nTrial);
            %
            fprintf('%d of %d, S: %d, ISI: %d, UCS: %d, ODD: %d.\n',nTrial,p.presentation.tTrial,stim_id,InNPulse,ucs,oddball);
            %
            if nTrial == p.presentation.tTrial%if last trial, then no next trial
                next_pos1    = [];
                next_stim_id = [];
            else%get info about the next trial
                next_pos1    = p_ptb_CrossPosition_y(p_presentation_cross_position(nTrial+1));
                next_stim_id = p_presentation_stim_id(nTrial+1);
                if nTrial == 1%first trial.
                    %We will start the tracker and turn on the fixation cross
                    %for the first trial. These have to be done before the main
                    %for loop.                   
                    Screen('DrawText', p_ptb_w, double('+'), p_ptb_CrossPosition_x, pos1, p_stim_white);                    
                    TimeCrossOn   = Screen('Flip',p_ptb_w);
                    %
                    TimeTrackerOn = StartEyelinkRecording(p_presentation_stim_id(nTrial),p_var_ExpPhase,oddball,ucs);%logs inside                   
                    %
                    %Mark the onset
                    MarkCED(p_com_lpt_address,p_com_lpt_FixOnset);
                    Eyelink('Message', 'FX Onset at %03d',pos1);
                    Log(TimeCrossOn, 1, pos1);%log the mark onset...
                end
            end
            KbQueueStart(p_ptb_device);%monitor keypresses...
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal            
            Trial(stim_id,InNPulse,ucs,next_stim_id,pos1,pos2,next_pos1,oddball);
            %
            [keypressed, firstPress]=KbQueueCheck(p_ptb_device);
            %if the press was after stimulus onset and before stimulus
            %offset
            if keypressed && (firstPress(p_keys_confirm) > TimeStimOnset) && (firstPress(p_keys_confirm) < TimeEndStim)
                p.out.response(nTrial) = 1;
                Log(firstPress(p_keys_confirm),7,NaN);%log the key press for hit detection.
                fprintf('Subject Pressed the Hit Key!!\n');
            end
        end
    end
    function Trial(stim_id,InNPulse,ucs,next_stim_id,pos1,pos2,next_pos1,oddball)
        
        %% Draw the stimulus to the buffer        
        Screen('DrawTexture', p_ptb_w, p_ptb_stim_sprites(stim_id));
        Screen('DrawText'   , p_ptb_w, double('+'), p_ptb_CrossPosition_x,pos1, p_stim_white);
        if oddball%add freckles to the face
            x = randn(1,100)*35;
            y = randn(1,100)*10;
            s = rand(1,100);%[0 1]
            Screen('DrawDots',p_ptb_w,[x;y],1+s.*1.5,[180 0 0 160],p_ptb_midpoint,1);
            %the dots size
        end
        Screen('DrawingFinished',p_ptb_w,1);
                
        %% STIMULUS ONSET                        
        %Here we wait only for the next pulse.
        %The proper amount is obtained with the second call of WaitPulse
        %below, before the onset of the fixation cross.
        %fprintf('Will Wait for the pulse to Stim Onset\n');
        TimePulse1     = WaitSecs(1);        
        TimeStimOnset  = Screen('Flip',p_ptb_w,0,1);%asap and dont clear
        %send eyelink and ced a marker asap
        Eyelink('Message', 'Stim Onset');
        Eyelink('Message', 'SYNCTIME');
        MarkCED( p_com_lpt_address, p_com_lpt_StimOnset );                
        Log(TimeStimOnset,2,stim_id);%log the stimulus onset
        
        %% Now we have 750 ms to make all the variables ready for us later use...
        
        TimeCrossJumpTime = TimePulse1  + p_duration_crossmoves - p_ptb_slack;
        TimeEndStim       = TimePulse1  + p_duration_stim;                
        TimeStartShock    = TimePulse1  + p_duration_onset2shock;
        TimeTrackerOff    = TimeEndStim + p_duration_keep_recording;
        
        %% CROSS JUMPS                        
        %Update the image on the buffer with the new cross_pos
        Screen('DrawTexture', p_ptb_w, p_ptb_stim_sprites(stim_id));
        Screen('DrawText'   , p_ptb_w, double('+'), p_ptb_CrossPosition_x, pos2, p_stim_white);
        if oddball == 1
            Screen('DrawDots',p_ptb_w,[x;y],1+s.*1.5,[180 0 0 160],p_ptb_midpoint,2);
        end
        Screen('DrawingFinished',p_ptb_w,0);
        
        %present it after 750 ms following Pulse Detection.
        %why pulse detection and not stimulus onset. Because we don't want
        %additional variability, everything should be defined with respect
        %to the arrival...
        TimeCrossJumpTime = Screen('Flip', p_ptb_w, TimeCrossJumpTime , 0);
        
        %send eyelink and ced a marker
        MarkCED(p_com_lpt_address,p_com_lpt_FixMove);
        Eyelink('Message', 'FX Moves to %03d' ,pos2);
        Log(TimeCrossJumpTime,3,NaN);%log the fixation cross move
                        
        %% UCS 
        Screen('DrawingFinished',p_ptb_w,0);
        
        if ucs == 1
            %%%%%%%%%%%%%%%%%%%%%%%
            %Deliver shock and stim off immediately            
            TimeStartShock = WaitSecs('UntilTime',TimeStartShock);
            Eyelink('Message', 'UCS Onset');
            while GetSecs < TimeEndStim;
                Buzz;%this is anyway sent to CED.
            end
            Eyelink('Message', 'UCS Offset');                       
        end
        
        %% STIM OFF immediately
        TimeEndStim = Screen('Flip',p_ptb_w,TimeEndStim);
        %send eyelink and ced a marker        
        MarkCED(p_com_lpt_address,p_com_lpt_StimOffset);
        Eyelink('Message', 'Stim Offset');            
        Eyelink('Message', 'BLANK_SCREEN');
        Log(TimeEndStim,-2,stim_id);%log the stimulus offset
        %
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        TimeTrackerOff    = StopEyelinkRecording;
        
        %% PRESTIMULUS        
        %turn on the fixation cross and start recording eye data for
        %the next stimulus if there is any
        if ~isempty(next_stim_id)
            %
            %% Fixation Onset
            Screen('DrawText', p_ptb_w, double('+'), p_ptb_CrossPosition_x,next_pos1, p_stim_white);            
            %wait for the necessarily ISI amount
            %fprintf('Will Wait for the necessary ISI amount\n');
            TimePulse2   = WaitSecs(InNPulse);                                    
            TimeCrossOn  = Screen('Flip',p_ptb_w,TimePulse2+p_duration_prestim);
            
            MarkCED(p_com_lpt_address,p_com_lpt_FixOnset);
            Eyelink('Message', 'FX Onset at %03d',pos1);
            Log(TimeCrossOn,1,stim_id);%cross onset.
            
            %% TURN the Eye tracker on again
            StartEyelinkRecording(next_stim_id,p_var_ExpPhase,oddball,ucs);            
            
            %Verbose some information            
            %fprintf('StimulusID: %3d, Phase: %3d\n%0.10g Pulse Detected\n%0.10g (%0.10g) Stim Onset\n%0.10g (%0.10g) Cross Jumped\n%0.10g (%0.10g) StimOff\n%0.10g (%0.10g) Eyelink stops\n%0.10g (%0.10g) Cross Onset\n%0.10g (%0.10g) Start Eyelink\n',...
            %stim_id,p_var_ExpPhase,TimePulse1,TimeStimOnset,TimeStimOnset-TimePulse1,TimeCrossJumpTime,TimeCrossJumpTime-TimePulse1,TimeEndStim, TimeEndStim-TimePulse1,TimeTrackerOff,TimeTrackerOff-TimePulse1,TimeCrossOn,TimeCrossOn-TimeEndStim,TimeTrackerOn,TimeTrackerOn-TimeEndStim);
            %fprintf('Waited already %d TRs\n',InNPulse);            
            %
            if oddball == 1
                fprintf('This was an oddball trial!\n');
            end
            if ucs == 1
                fprintf('This was a UCS trial!\n');
                Log(TimeStartShock,4,NaN);%UCS delivery...This is done here to not waste time there
            end
        end
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
        p.path.edf                    = sprintf([p.subID 'p%02d' ],phase);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\' p.subID '_' timestamp '\' ];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);
        mkdir([p.path.subject 'eye']);
        mkdir([p.path.subject 'triads']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\param_phase_%02d'],phase);
        
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
        p.text.fontsize                = 18;%30;
        %rating business
        p.rating.division              = 10;%number of divisions for the rating slider
        p.rating.repetition            = 2;%how many times a given face has to be repeated...
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address              = 888;
        %codes for different events
        p.com.lpt.FixOnset             = 4;
        %2 is empty because
        p.com.lpt.StimOnset            = 1;
        p.com.lpt.FixMove              = 16;
        p.com.lpt.UCS                  = 128;
        p.com.lpt.StimOffset           = 32;
        p.com.lpt.CS_plus              = 64;
        p.com.lpt.CS_neg               = 128;
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 1.2;%s
        p.duration.shock               = 0.1;%s;x        
        p.duration.shockpulse          = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse     = 0.01;%ms; and the time between each pulse
        p.duration.onset2shock         = p.duration.stim - p.duration.shock;
        p.duration.crossmoves          = p.duration.stim./2;        
        p.duration.keep_recording      = 0.1;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.prestim_ori         = .95;
        p.duration.prestim             = 2-p.duration.prestim_ori;%that is 0.95 seconds
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence
        if phase == 1
            seq = FeargenSequence_ET( 1:16, [], 1,1);
        elseif phase == 3%conditioning
            seq = FeargenSequence_ET( [csp csn], csp, 40,2);
        elseif phase == 4
            seq = FeargenSequence_ET( 1:16, csp, 18,1);
        end
        %create the randomized design
        p.stim.cs_plus                 = csp;%index of cs stimulus, this is the one paired to shock
        p.stim.cs_neg                  = csn;
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        %this will deal all the presentation sequence related information
        p.presentation                 = seq;        
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
        %       
        p_var_ExpPhase = 5;
        BG             = p.stim.bg;%
        p.stim.bg      = p.stim.bg_rating;
        nseq           = 0;
        rating_seq     = [];
        pos1_seq       = [];
        %
        while nseq < p.rating.repetition
            nseq            = nseq + 1;
            rating_seq      = [ rating_seq     Shuffle(1:p.stim.tFile)'];
        end
        message     = GetText(11);
        SliderTextL = GetText(13);
        SliderTextR = GetText(12);
        %
        Screen('FillRect', p_ptb_w , p.stim.bg);
        Screen('Flip',p_ptb_w);
        WaitSecs(2);
        %
        ShowInstruction(7,1);
        rect        = [p.ptb.width*0.2  p_ptb_midpoint(2) p.ptb.width*0.6 100];
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
            next_stim_id = [];%this is a trick, otherwise a fixation cross appears right before the rating :(
            next_pos1    = [];
                        
            %We will start the tracker and turn on the fixation cross
            %for the first trial. These have to be done before the main
            %for loop.
            StartEyelinkRecording(stim_id,p_var_ExpPhase,0,0);
            Screen('DrawText', p_ptb_w, double('+'), p.ptb.CrossPosition_x, pos1, p_stim_white);
            t  = Screen('Flip',p_ptb_w);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Mark the onset
            MarkCED(p_com_lpt_address,p_com_lpt_FixOnset);
            Eyelink('Message', 'FX Onset at %03d',pos1);
            Log(t,1,pos1);%log the mark onset...
            
            %
            Trial(stim_id,1,0,next_stim_id,pos1,pos2,next_pos1,0);
            rate(nRatend,1)  = RatingSlider(rect, p.rating.division, Shuffle(1:p.rating.division,1), p.keys.increase, p.keys.decrease, p.keys.confirm, {SliderTextL{1} SliderTextR{1}},message,1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Verbose the rating of the subject
            fprintf('============\nRating Results %d (%d/%d):\n', stim_id, nRatend, tRatend);
            dummy = rating_seq(1:nRatend);%trials shown so far
            for iii = 1:p.stim.tFile
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
        rate         = reshape(rate(i),p.rating.repetition,p.stim.tFile)';
        p.out.rating = rate;
        save(p.path.path_param,'p');
        Screen('FillRect',p_ptb_w,p.stim.bg);
        p.stim.bg = BG;
        %
        save(p.path.path_param,'p');
    end
    function [rating] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [~ , ~, bb(nlab,:)]=DrawFormattedText(p_ptb_w,labels{nlab}, 'center', 'center',  p_stim_white,[],[],[],2);
            Screen('FillRect',p_ptb_w,p.stim.bg);
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
                        %rating   = tSection - position + 1;
                    end
                    DrawSkala;
                elseif keyCode == confirm
                    WaitSecs(0.1);
                    ok = 0;
                    Screen('FillRect',p_ptb_w,p.stim.bg);
                    t=Screen('Flip',p_ptb_w);
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
                Screen('DrawLine', p_ptb_w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p_ptb_w,p.text.fontsize./2);
                    DrawFormattedText(p_ptb_w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p_stim_white);
                    Screen('TextSize', p_ptb_w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p_ptb_w, labels{1},tick_x(tick)-bb_size*1.4,rect(2), p_stim_white);
                elseif tick == tSection+1
                    DrawFormattedText(p_ptb_w, labels{2},tick_x(tick)+bb_size*0.4,rect(2), p_stim_white);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p_ptb_w, p_stim_white, round(slider));
            Screen('TextSize', p_ptb_w,p.text.fontsize./2);
            DrawFormattedText(p_ptb_w,message, 'center', p_ptb_midpoint(2)*0.2,  p_stim_white,[],[],[],2);
            Screen('TextSize', p_ptb_w,p.text.fontsize);
            t = Screen('Flip',p_ptb_w);
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
            Screen('FillRect',p_ptb_w,p.stim.bg);
            t = Screen('Flip',p_ptb_w);
            Log(t,-5,nInstruct);
        else
            if nInstruct ~= 10%this is for the Reiz kommnt
                KbStrokeWait;
            else
                WaitSecs(1+rand(1));
            end
        end
        
        
        function ShowText(text)
            
            Screen('FillRect',p_ptb_w,p.stim.bg);
            %DrawFormattedText(p_ptb_w, text, p.text.start_x, 'center',p_stim_white,[],[],[],2,[]);
            DrawFormattedText(p_ptb_w, text, 'center', 'center',p_stim_white,[],[],[],2,[]);
            t=Screen('Flip',p_ptb_w);
            Log(t,5,nInstruct);
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
                
                text = ['Um Deine Augenbewegungen zu messen, \n' ...
                        'm�ssen wir jetzt den Eye-Tracker kalibrieren.\n' ...
                        'Dazu zeigen wir Dir einige Punkte auf dem Bildschirm, \n' ...
                        'bei denen Du Dich entsprechend der eben genannten Regel verh�lst:\n' ...
                        'Bitte fixiere das Fixationskreuz und \n' ...
                        'bleibe so lange darauf, wie es zu sehen ist.\n' ...
                        'Bitte dr�cke jetzt den mittleren Knopf, \n' ...
                        'um mit der Kalibrierung weiterzumachen.\n' ...
                    ];
                
            elseif nInstruct == 1%first Instr. of the training phase.
                text = ['Wir werden nun als erstes einen �bungsdurchgang machen,\n' ...
                    'damit Du Dich im Scanner an Deine Aufgabe gew�hnen kannst.\n' ...
                    'In diesem Durchgang kannst Du Dich vollkommen sicher f�hlen,\n' ... 
                    'es werden keine elektrischen Reize verabreicht.\n' ...
                    'Eine wichtige grunds�tzliche Regel ist, dass Du das Fixationskreuz (das �+�)\n' ... 
                    'sobald es zu sehen ist mit Deinen Augen fixierst UND \n' ...
                    'den Blick die ganze Zeit darauf richtest, solange es zu sehen ist.\n' ...
                    'Das Fixationskreuz ver�ndert seine Position � immer nach oben � und \n' ... 
                    'es ist wichtig, dass Du dieser Bewegung so genau wie m�glich \n' ...
                    'mit Deinem Blick folgst.\n' ...
                    'Dr�cke die mittlere Taste um mit dem n�chsten Abschnitt fortzufahren.\n' ...
                    ];
            elseif nInstruct == 2%second Instr. of the training phase.
                text = ['Ein paar Bemerkungen zu den Zielreizen: \n' ...
                        'Zur Erinnerung: Zielreize sind die Gesichter mit Sommersprossen.\n' ...
                        'Sobald ein solcher Zielreiz erscheint, \n' ...
                        'sollst Du schnellstm�glich die mittlere Taste dr�cken, \n' ...
                        'und zwar bevor der Reiz wieder verschwunden ist \n' ...
                        '(Du musst also sehr schnell und aufmerksam sein).' ...
                    ];
            elseif nInstruct == 3%third Instr. of the training phase.
                text = ['Es ist sehr wichtig, dass Du Deinen Kopf w�hrend \n' ...
                    'des Experiments nicht bewegst. \n' ...
                    'Das ist besonders wichtig f�r die Qualit�t der Messung.\n' ...
                    'Daher sollte Deine Kopfhaltung so bequem wie m�glich sein.\n' ... 
                    'Wenn es sich jetzt gerade nicht bequem anf�hlt oder \n' ...
                    'Du das Gef�hl hast, \n' ...
                    'Du m�chtest die Position noch ver�ndern, \n' ...
                    'ist jetzt der Moment, in dem Du das tun kannst.\n' ...
                    ];
            elseif nInstruct == 4%third Instr. of the training phase.
                text = ['Vor dem �bungsdurchgang legen wir nun \n' ...
                        'die Schockintensit�t f�r den Rest des Experiments fest. \n' ...
                        'Dr�cke die mittlere Taste um fortzufahren.' ...
                    ];
             
            elseif nInstruct == 5%Baseline Phase
                %
                %
                %=================================================================================================================%
                text = ['Jetzt geht es mit dem Experiment los.\n' ...
                        'Deine Aufgabe ist es jetzt, genauso wie im Training die Gesichter, \n' ...
                        'die Dir gezeigt werden aufmerksam zu betrachten und \n' ...
                        'den mittleren Knopf zu dr�cken, sobald du einen Zielreiz siehst.\n' ...
                        '\n'...
                        'Hin und wieder erscheint ein Symbol (ein Blitzpfeil, der vor Strom warnt), \n' ...
                        'das einen elektrischen Reiz ank�ndigt. \n' ...
                        'Die Reize erfolgen aber nur bei diesem Symbol, nicht bei den Gesichtern! \n' ...
                        'Bei Gesichtern kannst Du Dich also sicher f�hlen.\n' ...
                        'Bitte denke daran: 1. Folge immer den Fixationskreuz und 2. nicht bewegen!\n\n' ...
                        'Wenn Du noch Fragen hast, kannst du sie jetzt gerne �ber die Sprechanlage stellen. \n' ...
                        'Ansonsten kannst Du das Experiment �ber die mittlere Taste starten. \n' ...
                    ];
                
            elseif nInstruct == 6%Test and Conditioning Phase
                %=================================================================================================================%
                text = ['Auch im nun folgenden Teil des Experiments \n' ...
                        'sollst Du die Gesichter aufmerksam betrachten und \n' ...                                    
                        'den mittleren Knopf dr�cken, sobald du einen Zielreiz siehst. \n' ...
                        'Wie im ersten Teil des Experiments sollst Du \n' ...
                        'das Fixationskreuz immer fixieren, \n' ...
                        'ihm immer folgen und Deinen Blick nie von ihm abwenden. \n\n' ...
                        'In dieser Phase des Experiments wirst du wieder \n' ...
                        'gelegentlich elektrische Reize bekommen.\n\n' ...
                        'Die elektrischen Reize folgen jetzt jedoch auf eins der Gesichter, \n' ...
                        'das elektrische Symbol wirst Du nicht mehr sehen. \n' ...
                    ];
                
                
            elseif nInstruct == 7;%rating
                text = ['In dieser Phase h�tten wir gerne, dass Du die Gesichter\n'... 
                        'im Hinblick auf folgende Frage bewertest:\n'...
                        '�Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                        'einen elektrischen Schock zu erhalten?�\n'...
                        'Bewege den Zeiger mit der rechten und linken Pfeiltaste \n'...
                        'und best�tige Deine Einsch�tzung mit der oberen Pfeiltaste.\n'...                    
                    ];
                      
            elseif nInstruct == 8 %CS+ detection
                text = ['Du bekommst nun eine Reihe von Gesichtern gezeigt.\n' ...
                    'Bitte w�hle das Gesicht aus bei dem der Schock verabreicht wurde.\n'...
                    'Dr�cke die mittlere Taste um fortzufahren.\n'...
                    ];
            elseif nInstruct == 9%
                %=================================================================================================================%
                text = ['Gib bitte an, ob die Reizst�rke des folgenden Schocks\n f�r Dich ertr�glich ist.\n'...
                    '\n'...
                    'Dr�cke bitte die mittlere Taste um den Reiz zu bekommen.\n'...
                    ];
                
            elseif nInstruct == 10%just before the shock
                text = ['Reiz kommt...\n'];
            elseif nInstruct == 11%this is the rating question
                text = ['Wie wahrscheinlich ist es, bei dem gerade gesehenen Gesicht \n'...
                        'einen elektrischen Schock zu erhalten?�\n' ...
                       'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n' ... 
                       'und bestaetige deine Einschaetzung mit der mit der oberen Pfeiltaste'...
                       ];
            elseif nInstruct == 12 %These two below are the possible responses to the question in 11
                text = {'Sehr\nwahrscheinlich'};
            elseif nInstruct == 13
                text = {'�berhaupt\nnicht\nwahrscheinlich'};
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
        if strcmp(p.hostname,'triostim1') 
            p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,1280,960);
            %hide the cursor
            HideCursor(p.ptb.screenNumber);
        elseif strcmp(p.hostname,'etpc')
            p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,1600,1200);
            %hide the cursor
            HideCursor(p.ptb.screenNumber);
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %set serial communication channels
        IOPort('CloseAll');
        p.com.serial = IOPort('OpenSerialPort', 'COM1', 'InputBufferSize=51840000 HardwareBufferSizes=32768,32768 Terminator=0 ReceiveLatency=0.0001 BaudRate=9600 ReceiveTimeout=7');
        IOPort('ConfigureSerialPort', p.com.serial, 'BlockingBackgroundRead=1');
        %because of the BlockingBackgroundRead=1, the flush and close all
        %command will wait for the next byte to arrive...
        IOPort('ConfigureSerialPort', p.com.serial, 'StartBackgroundRead=2');
        IOPort('Flush', p.com.serial);
        %2 is the granularity of the data, cogent box sends 2 bytes.
        %IOPort('ConfigureSerialPort', p.com.serial, 'ReadTimeout=5');
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.
        p.ptb.device        = -1;
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %prepare parallel port communication. This relies on cogent i
        %think. We could do it with PTB as well.
        config_io;
        outp(p.com.lpt.address,0);
        if( cogent.io.status ~= 0 )
            error('inp/outp installation failed');
        end
        %test whether CED receives the triggers correctly...
        k = 0;
        while k ~= 49;
            outp(888,247);pause(0.1);outp(888,0);%247 means all but the UCS channel (so that we dont shock the subject during initialization).
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
        Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p_stim_files(nStim,:), p_ptb_midpoint(1), p_ptb_midpoint(2));
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
            Eyelink('ImageTransfer',p_stim_files(nStim,:),p_ptb_imrect(1),p_ptb_imrect(2),p_ptb_imrect(3),p_ptb_imrect(4),p_ptb_imrect(1),p_ptb_imrect(2));
        end
        Eyelink('Command', 'draw_cross %d %d 15',p_ptb_CrossPositionET_x(1),p_ptb_CrossPositionET_y(1) );
        Eyelink('Command', 'draw_cross %d %d 15',p_ptb_CrossPositionET_x(2),p_ptb_CrossPositionET_y(2) );
        %
        %drift correction
        %EyelinkDoDriftCorrection(el,0,0,0,0);
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
        outp(p_com_lpt_address, p_com_lpt_UCS );
        WaitSecs(p_duration_shockpulse);
        outp(p_com_lpt_address, 0);
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
        %
        el                          = EyelinkInitDefaults(p_ptb_w);
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
        Eyelink('command', 'calibration_type = HV5');
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
        if strcmp(p.hostname,'triostim1')
            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        IOPort('ConfigureSerialPort', p.com.serial,' StopBackgroundRead');
        IOPort('Close',p.com.serial);
        commandwindow;
        ListenChar(0);
        KbQueueRelease(p_ptb_device);
    end
    function CalibrateEL
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p_var_ExpPhase  = 0;
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
        
        p_var_event_count                = p_var_event_count + 1;
        p_out_log(p_var_event_count,:)   = [ptb_time event_type event_info p_var_ExpPhase];
        % %         p_out_log(p.out.event_counter,:)
        %logstring([ 'Logged: ' mat2str(p_out_log(p.out.event_counter,:)) ' - Type: ' p.verbose.eventtype{abs(event_type)} ' - Phase: ' p.verbose.eventphase{CurrentExperimentalPhase}])
        %for i = 1:3;subplot(3,1,i);plot(p_out_log(1:p.out.event_counter ,i),'o-');drawnow;end
        %
        
    end


end
