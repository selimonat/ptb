function [p]=exp_fearadapt_main(subject,PainThreshold)
%[p]=exp_FearGen_ForAll(subject,phase,csp,PainThreshold)

%
%
%   This code is based on the exp_FearAmy.m, adapted to run the initial FearGen
%   experiment (Onat & Buechel, 2015).
%
%   When the experiment starts as experimenter you will have to pass through
%   few sanity checks (press (V)alidate to continue). Once these are
%   passed, some text will be shown to the participant. You can also pass
%   these stages by pressing V (normally the subject has to read them and
%   press confirm key). These instructions for participants are shown using
%   the ShowInstruction function, where you precise instructions by their
%   id number. All instructions are stored in the GetText function by these
%   ids. So if you would like to change instructions you will need to
%   modify that function.
%
%   The experiment starts with PHASE = 1. Here I set the shock intensity
%   while the participant is in the scanner. The shock threshold is
%   measured outside the scanner. This is here just to validate the shock
%   intensity that will be used during the experiment, it is obtained by
%   the PAINTHRESHOLD (given as input) times P.OUT.SHOCKFACTOR (defined
%   below). PAINTHRESHOLD is only painful half of the time by definition,
%   and we would like to give a shock which is more painful but still
%   bearable by the participant. That is, I ask the participant to confirm
%   the shock is PAINFUL and BEARABLE. If the shock is not bearable the
%   program will propose a lower amplitude and the same question will be
%   repeated until these two conditions are fulfilled. It is always good to
%   stay in oral communication with the participant though. The phase = 1
%   continues with a short presentation of faces, where I evaluate whether
%   they 1/ follow the fixation cross as instructed and 2/ detect the
%   oddball target. If they fail in any of these, phase 1 is repeated. This
%   phase also helps people to familiarize with the faces if no other task
%   has yet been carried out befo
%
%   The phase 2 is baseline. All faces are shown, but non predicts the
%   shock. Instead shocks are delivered after a shock symbol. This phase
%   ends with ratings.
%
%   Phase 3 is conditioning. Only CS+ and CS- are shown and CS+ is shocked
%   at about 30% of the cases.
%
%   Phase 4 is similar to baseline, all faces are shown, but shock follows
%   the CS+ face to avoid extinction. Following this phase, there is the
%   detection task.
%
%
%   The current experiment can fully work with the Eyelink
%   eye-tracker. This is however now disabled. If you intent to record
%   eye-movements turn the EyelinkWanted flag to 1.
%
%   The parallel communication currently relies on the cogent's OUTP
%   function. It is used to deliver shocks and to send event pulses to the
%   physio computer. If you intend to use a Windows systems you can install
%   cogent and outp function, then you would be able to directly use this
%   code. Or take the extra mile and code the outp equivalent in PTB (that
%   would be nice).
%
%   To do before you start:
%   Set the baselocation for the experiment in SetParams around line 420:
%   p.path.baselocation variable. this location will be used to save
%   the experiment-related data for the current subject.
%
%
%   Example usage:
%   exp_FearGen_ForAll(12,3,4,1,8.43); runs the Conditioning paradigm (3) for
%   participant 12, using the stimulus sequence 4 where the CS+ face is
%   face number 1 for a participant who has a shock intensity of 8.43.
%
%
%   Selim Onat

debug   = 0;%debug mode => 1: transparent window enabling viewing the background.
trial_info = 0;
EyelinkWanted = 0;%is Eyelink wanted?
mrt           = 0;
lab           = '204';
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
if nargin ~= 2
    fprintf('Wrong number of inputs\n');
    keyboard;
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
phase = 0; %for now
p.var.ExpPhase  = 0;
trun = 4;
SetParams;%set parameters of the experiment
SetPTB;%set visualization parameters.
%
%init all the variables
t                         = [];
nTrial                    = 0;
ntTrial                   = 0;
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

if EyelinkWanted
        CalibrateEL;
        ShowInstruction(299,0,5);
end

    %% Instructions
    p.var.ExpPhase  = 1;%set this after the calibration;
    for ninst = [1 2 3]
        ShowInstruction(ninst,1);
    end
%     ShowInstruction(5,1); %has been done in discr. task
%     ConfirmIntensity;
    for ninst = [4 401:406]
        ShowInstruction(ninst,1);
    end
for phase = 1:trun
    %%
    press2shock = p.presentation(phase).press2shock(p.presentation(phase).world);
    BlockInstruction(phase,press2shock,1)
    PresentStimuli;
    fprintf('Now saving p at end of block %d.\n',phase)
    save(p.path.path_param,'p');
    
end
fprintf('Going into AskStimRating mode.\n');
% AskStimRating;%make sure that scanner doesnt stop prematurely asa the stim offset
       %     if phase == 6
    %         if EyelinkWanted
    %             CalibrateEL;
    %             AskDetection;
%     fprintf('Going into AskStimRating mode.\n');
AskStimRating;%make sure that scanner doesnt stop prematurely asa the stim offset

    %         end

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

    function AskDetectionSelectable
        %asks subjects to select the face that was associated with a shocks
        positions          = circshift(1:8,[1 Shuffle(1:8,1)]);%position of the marker
        p.var.ExpPhase = 4;
        ShowInstruction(8,1);
        %%
        increment([p.keys.increase p.keys.decrease]) = [1 -1];%key to increment mapping
        %%
        ok                 = 1;
        while ok
            DrawCircle;
            Screen('FrameOval', p.ptb.w, [1 1 0], p.stim.circle_rect(positions(1),:), 2);%draw the marker circle somewhere random initially.
            Screen('Flip',p.ptb.w);
            [~, keyCode, ~]  = KbStrokeWait(p.ptb.device);%observe key presses
            keyCode          = find(keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                if (keyCode == p.keys.increase) || (keyCode == p.keys.decrease)
                    positions  = circshift(positions,[0 increment(keyCode)]);
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
        p.out.selectedface = p.stim.circle_order(positions(1));
    end
    function DrawCircle
        for npos = 1:p.stim.tFace
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(p.stim.circle_file_id(npos)),[],p.stim.circle_rect(npos,:));
            %Screen('DrawText', p.ptb.w, sprintf('%i_%i_%i',p.stim.circle_order(npos),p.stim.circle_file_id(npos),npos),mean(p.stim.circle_rect(npos,[1 3])) ,mean(p.stim.circle_rect(npos,[2 4])));
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
            message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätige deine Einschätzung mit der mit der Leertaste.';
            rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];
            response = RatingSlider(rect,2,1,p.keys.increase,p.keys.decrease,p.keys.confirm,{ 'nicht\nerträglich' 'erträglich'},message,0);
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
            message   = 'Bewege den "Zeiger" mit der rechten und linken Pfeiltaste\n und bestätige deine Einschätzung mit der mit der Leertaste.';
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
    end
    function PresentStimuli
        %Enter the presentation loop and wait for the first pulse to
        %arrive.
        %wait for the dummy scans
        if mrt
            [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%will log it
        else
            secs = GetSecs;
        end
        KbQueueStop(p.ptb.device);
        WaitSecs(.05);
        KbQueueCreate(p.ptb.device);
        KbQueueStart(p.ptb.device);%this means that from now on we are going to log pulses.
        %If the scanner by mistake had been started prior to this point
        %those pulses would have been not logged.
        %log the pulse timings.
 
        TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        for nTrial  = 1:p.presentation(phase).trialsperblock;
             ntTrial = ntTrial+1;
            %Get the variables that Trial function needs.
            stim_id      = p.presentation(phase).stim_id(nTrial);
            ISI          = p.presentation(phase).isi(nTrial);
            ucs          = p.presentation(phase).ucs(nTrial);
            prestimdur   = p.duration.prestim+rand(1)*.25;
            %
            OnsetTime     = TimeEndStim + ISI - p.ptb.slack;
            fprintf('Block %d: %03d of %03d (%02d of %02d total). S: %d, ISI: %d, UCS: %d, OnsetTime: %f secs.\n ',phase,nTrial,p.presentation(phase).trialsperblock,ntTrial,p.presentation(phase).tTrial,stim_id,ISI,ucs,OnsetTime);
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim] = Trial(nTrial,ntTrial,OnsetTime, prestimdur, stim_id , ucs);
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
%             if any((keycode == p.keys.confirm) & (secs > OnsetTime) & (secs <= TimeEndStim))
%                 p.out.response(nTrial) = 1;
%                 fprintf('Subject Pressed the Hit Key!!\n');
%             end
%             if mod(nTrial,p.presentation(phase).trialsperblock)==0%LK change later.
%             end
        end
        ShowInstruction(15,0,3)
        
        DeliverCostShocks(ntTrial)
        
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        if mrt
            if p.var.ExpPhase > 0
                WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%
                fprintf('OK!! Stop the Scanner\n');
            end
        end
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
        fprintf('Waiting 2 sec for a short break after block...\n')
        WaitSecs(1);
    end
    function [TimeEndStim]=Trial(nTrial,ntTrial,TimeStimOnset , jitter, stim_id , ucs)
       cond_id = p.presentation(phase).cond_id(nTrial);
      
        if nTrial > 1
            counter = p.out.counter(ntTrial-1);
            fprintf('counter = %02d\n.',counter);
        elseif nTrial == 1%mod(nTrial,p.presentation(phase).trialsperblock)==1 
            counter = 0;
            fprintf('New block, counter set to zero.\n')
        end
         p.out.counter(1:10)'
       fprintf('counter = %d\n',counter);
        %plan all the times
        TimeStimOnset      = TimeStimOnset + jitter;
        TimeBoxOnset       = TimeStimOnset  + p.duration.stim;
        TimeOutcome        = TimeStimOnset  + p.duration.stim + p.duration.outcomedelay;
        TimeEndStim        = TimeStimOnset  + p.duration.stim + p.duration.outcomedelay + p.duration.shock;
        TimeTrackerOff     = TimeStimOnset  + p.duration.stim + p.duration.outcomedelay + p.duration.shock + p.duration.keep_recording;
%         fprintf('\nPlanned timings: \nTimeStimOn: %f\nTimeBoxOn: %f\nTimeOutcome: %f\nTimeEndStim: %f\nTimeTrackerOff: %f\n',TimeStimOnset, TimeBoxOnset,TimeOutcome,TimeEndStim ,TimeTrackerOff)
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];
        if nTrial == 1
            %% First fixation cross Onset
%             FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
%             Screen('FillRect',  p.ptb.w, [0,0,0], FixCross');%draw the prestimus cross 
            DrawFormattedText(p.ptb.w, num2str(counter), 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_counter,p.text.color);
            DrawFormattedText(p.ptb.w, [num2str(press2shock) ' Knopfdrücke = 1 elektr. Reiz'], 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_worldinfo,p.text.color);            
            Screen('DrawingFinished',p.ptb.w,0);
            TimeCrossOn  = Screen('Flip',p.ptb.w,0,0);   
%             fprintf('\nTimeCrossOn: %f\n',TimeCrossOn)
        end
        Log(TimeCrossOn,2,NaN);%cross onset.
        %turn the eye tracker on
        if EyelinkWanted
            StartEyelinkRecording(ntTrial,stim_id,p.var.ExpPhase,stim_id,ucs,fix,mblock_id);%I would be cautious here, the first trial is never recorded in the EDF file, reason yet unknown.
        end
        %% Draw the stimulus to the buffer
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id),[],p.ptb.rect2draw);
        DrawFormattedText(p.ptb.w, num2str(counter), 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_counter,p.text.color);
        DrawFormattedText(p.ptb.w, [num2str(press2shock) ' Knopfdrücke = 1 elektr. Reiz'], 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_worldinfo,p.text.color);
        if trial_info
             DrawFormattedText(p.ptb.w, sprintf('Trial No %d, cond_id: %02d stim_id: %02d filename = %s.',stim_id,p.presentation(phase).cond_id(nTrial),p.stim.label{stim_id}), 'center',p.ptb.midpoint(2)-p.stim.rectsize-p.stim.dist_worldinfo,p.text.color);
        end
%         Screen('DrawDots', p.ptb.w, [p.ptb.midpoint(1) p.ptb.midpoint(2)], 10, [0 0 0], [], 2);
        Screen('DrawingFinished',p.ptb.w,0);
        %% STIMULUS ONSET
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
%         fprintf('Real TimeStimO: %f secs.\n',TimeStimOnset)
        %send eyelink and ced a marker asap
        if EyelinkWanted
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset );%this actually didn't really work nicely.
        %the first stim onset pulse is always missing. This could be due to
        %the fact that the state of the port was already 1 and thus CED
        %didn't realize this command.
        Log(TimeStimOnset,3,stim_id);%log the stimulus onset
        kdown = 0;
        timedout = false;
        press_is_known = false;
        while ~timedout %GetSecs < TimeBoxOnset%need sth like to so that we dont get x many key presses, once it's registered and counted
            
            [kdown,keyT, keyC]  = KbCheck(p.ptb.device);%observe key presses     %different nomenklature to avoid confusion with KbQueueDump
            if keyC ~= 0
                Log(keyT,7,keyC) %store keypress to Log
            end
            keyC          = find(keyC);
            if length(keyC) == 1%this loop avoids crashes to accidential presses of meta keys
                if  keyC == p.keys.confirm
                    if ~press_is_known %so that we don't count perseverations
                        fprintf('Subject Pressed the Escape Key!\n');
                        %update counter display right away
                        counter = counter + 1;
                        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id),[],p.ptb.rect2draw);
                        DrawFormattedText(p.ptb.w, num2str(counter), 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_counter,p.text.color);
                        DrawFormattedText(p.ptb.w, [num2str(press2shock) ' Knopfdrücke = 1 elektr. Reiz'], 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_worldinfo,p.text.color);
                        Screen('DrawingFinished',p.ptb.w,0);
                        Screen('Flip',p.ptb.w,0,0);%asap and dont clear
                        p.out.response(ntTrial) = 1;
                        p.out.RT(ntTrial)       = keyT - TimeStimOnset;
                        press_is_known = true;
                    end
                end
            end
            if GetSecs >= TimeBoxOnset
                timedout = true;
            end
        end
%         fprintf('Done with KBcheck loop\n')
%         fprintf('Now: %f secs.\n',GetSecs)
        %% Draw Yellow Frame with Stimulus
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id),[],p.ptb.rect2draw);
        DrawFormattedText(p.ptb.w, num2str(counter), 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_counter,p.text.color);
        DrawFormattedText(p.ptb.w, [num2str(press2shock) ' Knopfdrücke = 1 elektr. Reiz'], 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_worldinfo,p.text.color);       Screen('FrameRect',p.ptb.w, [255 255 0], p.ptb.rectbox, p.stim.rect_pix);
        if trial_info
             DrawFormattedText(p.ptb.w, sprintf('Trial No %d, cond_id: %02d stim_id: %02d filename = %s.',stim_id,cond_id,p.stim.label{stim_id}), 'center',p.ptb.midpoint(2)-p.stim.rectsize-p.stim.dist_worldinfo,p.text.color);
        end
        Screen('DrawingFinished',p.ptb.w,0);
        TimeBoxOnset = Screen('Flip',p.ptb.w,[],0);
%         fprintf('TimeBoxOn: %f\n',TimeBoxOnset)
        Log(TimeBoxOnset,4,ntTrial);
        TimeOutcome = WaitSecs('UntilTime',TimeOutcome);
        %% shock if UCS
        if ucs && ~p.out.response(ntTrial)==1
%             MarkCED(p.com.lpt.address, p.com.lpt.ucs); 
            %Deliver shock and stim off immediately
            fprintf('Buzz at %f.\n',GetSecs)
            if EyelinkWanted
                Eyelink('Message', 'UCS Onset');
            end
            Log(GetSecs,5,cond_id) %lets say cond_id is during the task, 99 is after it (punishment phase)
            while GetSecs < TimeEndStim;
                Buzz;%this is anyway sent to CED.
            end
        else
            WaitSecs('UntilTime',TimeEndStim);
        end
        %% Stimulus Offset -  switch to fixation cross
%         FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
%         Screen('FillRect',  p.ptb.w, [0 0 0], FixCross');%draw the prestimus cross atop
        DrawFormattedText(p.ptb.w, num2str(counter), 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_counter,p.text.color);
        DrawFormattedText(p.ptb.w, [num2str(press2shock) ' Knopfdrücke = 1 elektr. Reiz'], 'center',p.ptb.midpoint(2)+p.stim.rectsize*p.stim.dist_worldinfo,p.text.color);
        
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w,0,0);
%         fprintf('CrossOn: %f\n',TimeCrossOn)
        Log(TimeCrossOn,6,ntTrial)
        Log(TimeCrossOn,2,ntTrial)
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        if EyelinkWanted
            Eyelink('Message', 'Stim Offset');
            Eyelink('Message', 'BLANK_SCREEN');
        end
        TimeTrackerOff    = StopEyelinkRecording;
        p.out.counter(ntTrial)  = counter;%sum(p.out.response(1:nTrial));
    end
  function [TimeEndStim]=TrialRating(nTrial,TimeStimOnset , jitter, stim_id)
       
        %plan all the times
        TimeStimOnset      = TimeStimOnset + jitter;
        TimeEndStim        = TimeStimOnset  + p.duration.stim;
        TimeTrackerOff     = TimeStimOnset  + p.duration.stim + p.duration.keep_recording;
%         fprintf('\nPlanned timings: \nTimeStimOn: %f\nTimeEndStim: %f\nTimeTrackerOff: %f\n',TimeStimOnset, TimeEndStim ,TimeTrackerOff)
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];
        if nTrial == 1001
            %% First fixation cross Onset
%             FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
%             Screen('FillRect',  p.ptb.w, [0,0,0], FixCross');%draw the prestimus cross 
            Screen('DrawingFinished',p.ptb.w,0);
            TimeCrossOn  = Screen('Flip',p.ptb.w,0,0);
%             fprintf('\nTimeCrossOn: %f\n',TimeCrossOn)
        end
        Log(TimeCrossOn,2,NaN);%cross onset.
        %turn the eye tracker on
        if EyelinkWanted
            StartEyelinkRecording(nTrial,stim_id,p.var.ExpPhase,stim_id);%I would be cautious here, the first trial is never recorded in the EDF file, reason yet unknown.
        end
        %% Draw the stimulus to the buffer
        Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id),[],p.ptb.rect2draw);
        %% STIMULUS ONSET
        TimeStimOnset  = Screen('Flip',p.ptb.w,TimeStimOnset,0);%asap and dont clear
%         fprintf('Real Onset: %f secs.\n',TimeStimOnset)
        %send eyelink and ced a marker asap
        if EyelinkWanted
            Eyelink('Message', 'Stim Onset');
            Eyelink('Message', 'SYNCTIME');
        end
        MarkCED( p.com.lpt.address, p.com.lpt.StimOnset );%this actually didn't really work nicely.
        %the first stim onset pulse is always missing. This could be due to
        %the fact that the state of the port was already 1 and thus CED
        %didn't realize this command.
        Log(TimeStimOnset,3,stim_id+1000);%log the stimulus onset
        WaitSecs('UntilTime',TimeEndStim);
        %% Stimulus Offset -  switch to fixation cross
%         FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
%         Screen('FillRect',  p.ptb.w, [0 0 0], FixCross');%draw the prestimus cross atop
        TimeCrossOn  = Screen('Flip',p.ptb.w,0,0);
%         fprintf('CrossOn: %f\n',TimeCrossOn)
        Log(TimeCrossOn,6,nTrial)
        Log(TimeCrossOn,2,nTrial)
        %% record some more eye data after stimulus offset.
        WaitSecs('UntilTime',TimeTrackerOff);
        if EyelinkWanted
            Eyelink('Message', 'Stim Offset');
            Eyelink('Message', 'BLANK_SCREEN');
        end
        TimeTrackerOff    = StopEyelinkRecording;
        
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
        if strcmp(p.hostname,'blab0')
            p.path.baselocation       = 'U:\kampermann\FearAdapt_Pilote';
        else
            p.path.baselocation           = 'C:\Users\Lea\Documents\Experiments\FearAdapt_Pilote';
        end
        
        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0
            mkdir(p.path.baselocation);
        end
        
        p.subID                       = sprintf('sub%02d',subject);%subject id
        p.path.experiment             = [p.path.baselocation  filesep 'data\'];
        p.path.stim                   = [p.path.experiment p.subID filesep 'exp' filesep 'stim\'];
        p.path.stim24                 = [p.path.stim '24bit' filesep];%location of 24bit stimuli, useful only to send it to the eyelink system
        %         p.path.stim_cut               = [p.path.stim 'cut' filesep];%stimuli without borders, necessary for the facecircle
        %
        
        timestamp                     = datestr(now,30);%the time_stamp of the current experiment.
        p.path.subject                = [p.path.experiment  'tmp' filesep p.subID '_exp_' timestamp filesep ];%subject folder, first we save it to the temp folder.
        p.path.finalsubject           = [p.path.experiment p.subID '\exp\'];%final location of the subject folder
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
        [p.stim.files, p.stim.label]   = FileMatrix([p.path.stim '*.png']);%read in the stimlus
        p.stim.tFile                  = numel(p.stim.files);%number of different files
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
        %set the background gray according to the background of the stimuli
        for ii = 1:p.stim.tFile;
            im                        = imread(p.stim.files{ii});
            bg(ii)                     = im(1,1,1);
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
        p.text.fontsize                = 18;%30;
        p.text.fixsize                 = 60;
        p.text.color                   = [0 0 0];
        %rating business, how many ticks
        p.rating.division              = 10;%number of divisions for the rating slider
        p.rating.repetition            = 2;%how many times a given face has to be repeated...
        %% get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files{1});
        p.stim.width                   = info.Width;
        p.stim.height                  = info.Height;
        %% define rect around stimulus for outcome
        p.stim.rectsize                = 300; %one half only, will be drawn around midpoint, that we get from resolution in SetPTB, which is not yet run.
        p.stim.rect_pix                = 8; %one half only, will be dr
        p.stim.dist_counter            = 1.2;
        p.stim.dist_worldinfo          = 1.5;
        %% keys to be used during the experiment:
        %This part is highly specific for your system and recording setup,
        %please enter the correct key identifiers. You can get this information calling the
        %KbName function and replacing the code below for the key below.
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner
        %         KbName('UnifyKeyNames');
        p.keys.confirm                 = KbName('space');%
        p.keys.increase                = KbName('right');
        p.keys.decrease                = KbName('left');
        p.keys.pulse                   = KbName('5%');
        p.keys.el_calib                = KbName('v');
        p.keys.el_valid                = KbName('c');
        p.keys.escape                  = KbName('esc');
        
        
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
%         %%%%%%%%%%%%%%%%%%%%%%%%%%% Parallel port settings
%         p.com.lpt.BVRaddress           = 59392; %49232; %49020
%         p.com.lpt.CEDaddress           = 888 %55296; %888;
%         if p_slave_on
%             p.com.lpt.CEDaddress       = 59392;
%         end
%         
%         p.com.lpt.duration             = 0.005;
%         
% %         p.com.lpt.CEDduration          = 0.005;
% %         if p.mri.on == 1
% %             p.com.lpt.BVRduration      = 0.005;
% %         else
% %             p.com.lpt.BVRduration      = 0;
% %         end
%         % Codes for different events
%         p.com.lpt.scannerPulseOnset    = 255;
%         p.com.lpt.FixOnset             = 1;
%         p.com.lpt.StimOnset            = 2;
%         p.com.lpt.StartleOnset         = 4;
        %
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 3;%2;%s
        p.duration.shock               = 0.1;%s;x
        p.duration.shockpulse          = 0.005;%ms; duration of each individual pulses
        p.duration.intershockpulse     = 0.01;%ms; and the time between each pulse
        p.duration.keep_recording      = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.prestim             = .85;
        p.duration.outcomedelay        = 3;
        speedup = 1; %factor to speed up things, e.g. for debugging or testing 
        p.duration.outcomedelay        = p.duration.outcomedelay   /speedup;
        p.duration.stim                = p.duration.stim           /speedup;
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence: Explanation of the fields:
%         s = load([p.path.baselocation '\seq\exp\seq.mat']);
        s = load([p.path.baselocation '\seq\exp\seq_6runs_38trials.mat']);
        s = s.seq(subject,:);

        %this will deal all the presentation sequence related information
        p.presentation                 = s;       
        clear s;
        %% create the randomized design
        
        %Record which Phase are we going to run in this run.
%         p.stim.phase                   = phase;
        p.out.rating                  = [];%will contain explicite ratings of UCS likelihood
        p.out.log                     = zeros(1000000,4).*NaN;%Experimental LOG.
        p.out.response                = zeros(p.presentation(1).tTrial,1);%
        p.out.RT                      = nan(p.presentation(1).tTrial,1);%
        p.out.counter                 = zeros(p.presentation(1).tTrial,1);%
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
            nstim = numel(dummy);
            for nst = 1:nstim
                FM{nst}    = [fileparts(path) filesep dummy(nst).name];
            end
            labels = {dummy(:).name};
        end
    end
    function AskStimRating
        
        
        p.var.ExpPhase   = 5;
        p.var.current_bg = p.stim.bg_rating;
        %% create the order of presentation and balance the position of fixation cross
        nseq           = 0;
        rating_seq     = [];
        pos1_seq       = [];
        idx            = [];
        stim_order     = 1:p.stim.tFile;
        while nseq < p.rating.repetition
            nseq                    = nseq + 1;
            [dummy idx]             = Shuffle( stim_order );
            rating_seq              = [rating_seq dummy];
            %this balances both directions
            pos1_seq                = [pos1_seq ones(1,p.stim.tFile)];%+1 to make [0 1] --> [1 2]
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
%             %to send know the distance here, little dummy setup:
%             dummy        = -135:45:180;
%             dist         = dummy(stim_id);
            % show the picture
%          [TimeEndStim]=TrialRating(nTrial,TimeStimOnset , jitter, stim_id)
            TrialRating(1000+nRatend,GetSecs+1,0,stim_id);
            % show the slider
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
                if ismember(iii,[2 3]) %stimulus 2 and 3 are stimuli for condition 2 and 4
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
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        %
        save(p.path.path_param,'p');
    end
    function [rating] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [~ , ~, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center', p.text.color,[],[],[],2);
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
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4), [0 0 0 ]);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.4,rect(2), [0 0 0 ]);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.4,rect(2), [0 0 0 ]);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, [0 0 0], round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.text.color,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            t = Screen('Flip',p.ptb.w);
            Log(t,-2,NaN);
        end
    end
    function BlockInstruction(nBlock,press2shock,waitforkeypress,varargin)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, ==> subject presses a button to proceed
        %if waitforkeypress is 0, ==> text is shown for VARARGIN seconds.
        
        
        [text]= sprintf('Block %d.\n In diesem Block gilt folgende Regel: \n\n %d Tastendrücke = 1 elektr. Reiz am Ende des Blocks.\n\nDrücken Sie die Leertaste, um zu starten.',nBlock,press2shock);
    
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
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.text.color,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            Log(t,-1,100+nBlock);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');
            fprintf(text);
            fprintf('=========================================================\n');
            
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
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.text.color,[],[],[],2,[]);
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
                'Bitte fixieren Sie die nun folgenden weißen Kreise und \n' ...
                'bleiben so lange darauf, wie sie zu sehen sind.\n\n' ...
                'Nach der Kalibrierung dürfen Sie Ihren Kopf nicht mehr bewegen.\n'...
                'Sollten Sie Ihre Position noch verändern müssen, tun Sie dies jetzt.\n'...
                'Die beste Position ist meist die bequemste.\n\n'...
                'Bitte drücken Sie jetzt den oberen Knopf, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
         elseif nInstruct == 1
             text = ['Herzlich Willkommen zu diesem Teil des Experiments.' ...
                 '\n' ...
                 'Drücken Sie die Leertaste, um die Instruktionen zu lesen.\n'];
    
        elseif nInstruct == 2
             text = ['Auch in diesem Teil des Experiments sehen Sie verschiedene Formen.\n' ...
                 'Auf einige dieser Formen folgt in den meisten Fällen ein elektrischer Reiz.\n' ...
                 'Sie können dem elektrischen Reiz ausweichen, indem Sie die Leertaste schnell genug drücken,\n' ...
                 'd.h. bevor ein gelber Rahmen um die Form erscheint.\n' ...
                 '\n' ...
                 'Bedenken Sie jedoch: jeder Tastendruck zum Ausweichen des Reizes kostet!\n' ...
                 'Sie erhalten je nach Anzahl der Ausweich-Entscheidungen zusätzliche eletrische Reize am Ende eines Blocks.\n' ...
                 'Drücken Sie also nur, wenn die Form einen elektrischen Reiz ankündigt!\n' ...
                 '\n' ...
                 'Drücken Sie nun die Leertaste zum Fortfahren.\n'];
          elseif nInstruct == 3
             text = ['Je nachdem, in welchem Teil des Experiments Sie sich befinden, \n' ...
                 'kosten die Tastendrücke zum Ausweichen mehr oder weniger. \n' ...
                 '\n' ...
                 'Der Umrechnungsfaktor (z.B. 5 Tastendrücke = 1 elektr. Reiz) wird Ihnen \n' ...
                 'vor jedem Block angezeigt.\n' ...
                 'Er ist zudem stets untem am Bildschirm zu sehen.\n' ...
                 '\n' ...
                 'Drücken Sie nun die Leertaste zum Fortfahren.\n'];     
        elseif nInstruct == 4%third Instr. of the training phase.
            text = ['Wir sind jetzt kurz vor Beginn des Experiments.\n'...
                'Sie erhalten nun noch einmal eine Zusammenfassung der wichtigsten Punkte.\n\n'...
                'Drücken Sie jeweils die Leertaste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 401%third Instr. of the training phase.
            text = ['1/ Schauen Sie sich stets die erscheinenden Formen an.\n'...
                ];
        elseif nInstruct == 402%third Instr. of the training phase.
            text = ['2/ Auf einige der gezeigten Formen folgt ein elektrischer Reiz.\n'...
                ];
        elseif nInstruct == 403%third Instr. of the training phase.
            text = ['3/ Drücken Sie die Leertaste, wenn Sie einem Reiz ausweichen möchten.\nDrücken Sie schnell genug, d.h. bevor der gelbe Rahmen erscheint.'...
                ];
        elseif nInstruct == 404%third Instr. of the training phase.
            text = ['4/ Jedes Ausweichen kostet, d.h. Sie erhalten zusätzliche Reize am Ende des Blocks. \n '...
                ];
        elseif nInstruct == 405%third Instr. of the training phase.
            text = ['5/ Die Kosten (X Tastendrücke = 1 elektr. Reiz) sowie Anzahl bisher getätigter Tastendrücke wird Ihnen stets angezeigt.\n'...
                ];
        elseif nInstruct == 406%third Instr. of the training phase.
            text = ['Drücken Sie jetzt die Bestätigungstaste, das Experiment startet dann in wenigen Sekunden.\n' ...
                ];
        elseif nInstruct == 5%third Instr. of the training phase.
            text = ['Vor dem Experiment legen wir nun \n' ...
                'die Schockintensität für den Rest des Experiments fest. \n\n' ...
                'Drücken Sie die Leertaste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 501%third Instr. of the training phase.
            text = ['Experimenter: Please confirm that you set the stimulating intensity. \n'];
        elseif nInstruct == 502%third Instr. of the training phase.
            text = ['Experimenter: Stimulation OK. \n'];
        elseif nInstruct == 503%third Instr. of the training phase.
            text = ['Experimenter: Adapt stimulation intensity. \n'];
        elseif nInstruct == 7%third Instr. of the training phase.
            text = ['Bitte bewerten Sie die nun folgenden Formen noch einmal im Bezug folgende Frage:\n'...
                'Wir wahrscheinlich war es bei der entsprechenden Form, einen elektr. Reiz zu erhalten, wenn Sie keine Ausweich-Taste gedrückt haben?\n' ...
                'Nutzen Sie die Pfeiltasten, um den Cursor auf der Skala zu bewegen, und die Leertaste zum Bestätigen.\n\n'...
                'Drücken Sie die Leertaste um fortzufahren.\n' ...
                ];   
        elseif nInstruct == 8;%AskDetectionSelectable
            text = ['Sie sehen nun noch einmal eine Übersicht der verschiedenen Formen.\n'...
                'Bitte geben Sie an, welche der Formen Ihrer Meinung nach\n mit dem Schock gepaart wurde.\n\n'...
                'Nutzen Sie die linke und rechte Taste, um die Markierung\n zum richtigen Gesicht zu navigieren,\n'...
                'und drücken Sie dann die Bestätigungstaste.\n\n'...
                'Bitte zum Starten bestätigen.\n'...
                ];
%         elseif nInstruct == 801;%AskDetectionSelectable
%             text = ['Sie sehen nun eine ï¿½bersicht der verschiedenen Gesichter.\n'...
%                 'Bitte schauen Sie sich die Gesichter aufmerksam an.\n'...
%                 'Bitte drï¿½cken Sie zum Start die Leertaste und\n' ...
%                 'fixieren Sie das anschlieï¿½end erscheinende Fixationskreuz.\n'...
%                 ];
%             
        elseif nInstruct == 9%
            %=================================================================================================================%
            text = ['Bitte geben Sie an, ob die Reizstärke des folgenden Schocks\n für Sie erträglich ist.\n'...
                '\n'...
                'Drücken Sie bitte die Leertaste um den Reiz zu bekommen.\n'...
                ];
            
        elseif nInstruct == 10%just before the shock
            text = ['Reiz kommt...\n'];
        elseif nInstruct == 11%this is the rating question
            text = ['Wie wahrscheinlich ist es, bei der gerade gesehenen Form \n'...
                'einen elektrischen Schock zu erhalten?\n' ...
                'Bewegen Sie den "Zeiger" mit der rechten und linken Taste\n' ...
                'und bestätigen Sie Ihre Einschätzung anschließend.'...
                ];
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
            text = {'Sehr\nwahrscheinlich'};
        elseif nInstruct == 13
            text = {'Überhaupt\nnicht\nwahrscheinlich'};
        elseif nInstruct == 14
            text = ['Experiment beendet. Vielen Dank!\n'];
        elseif nInstruct == 15
            text = ['Ende des Blocks. Es geht gleich weiter.\n'];
        else
            text = {''};
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
        k = 0;
        while ~(k == p.keys.el_calib);%press V to continue
            pause(0.1);
            MarkCED(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
            fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            fprintf('/ Did the trigger test work?\n\n\n Turn on the Digitimer, then press V to continue experiment or C to continue sending test pulses...\n')
            [~, k] = KbStrokeWait([]);
            k = find(k);
            Log(GetSecs,7,k);
        end
        fprintf('Continuing...\n');
        
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
        p.ptb.res                   = res;
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.imrect                = [ p.ptb.midpoint(1)-p.stim.width/2 p.ptb.midpoint(2)-p.stim.height/2 p.ptb.midpoint(1)-p.stim.width/2+p.stim.width p.ptb.midpoint(2)-p.stim.height/2+p.stim.height];
        p.ptb.cross_shift           = [180 -120]./2.5;%incremental upper and lower cross positions
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%bb(1);%always the same
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2);%bb(1);%always the same
        %cross position for the eyetracker screen.
        p.ptb.CrossPositionET_x     = [p.ptb.midpoint(1) p.ptb.midpoint(1)];
        p.ptb.CrossPositionET_y     = [p.ptb.midpoint(2) p.ptb.midpoint(2)];
        p.ptb.fc_size               = 10;
        %
        p.ptb.rectbox               =  [p.ptb.midpoint(1)-p.stim.rectsize p.ptb.midpoint(2)-p.stim.rectsize p.ptb.midpoint(1)+p.stim.rectsize p.ptb.midpoint(2)+p.stim.rectsize]; %this is for the yellow frame during outcome
          p.ptb.imagesize           = [900 675]; %how big we want it.
        p.ptb.rect2draw            =CenterRectOnPointd([0 0 p.ptb.imagesize], p.ptb.res.width / 2,p.ptb.res.height / 2); %taken from some demo.
    
        
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the pictures to the video memory.
        p.ptb.stim_sprites     = CreateStimSprites(p.stim.files);%
   
        %%
        function [out]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:numel(files)
                filename       = files{nStim};
                [im , ~, ~]    = imread(filename);
                im = CenterStarfish(im);
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
    function [t]=StartEyelinkRecording(nTrial,nStim,phase,dist,oddball,ucs,fix,block_id)
        if EyelinkWanted
            t = [];
            if isnan(dist)
                dist=3000;
            end
            nStim = double(nStim);
            Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, FILE: %04d, ODDBALL: %04d, UCS: %04d, FIXX: %04d, FIXY %04d, MBLOCK %04d', nTrial, phase, nStim, double(oddball), double(ucs),fix(1),fix(2),block_id);
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
            Log(t,2,NaN);%LK
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
    function DeliverCostShocks(nt)
        press_count = p.out.counter(nt);
        text = ['Sie haben die Taste ' num2str(press_count) ' mal gedrückt.\n'...
            'Es folgt nun die entsprechende Anzahl an elektrischen Reizen.\n'...
            'Sie müssen nichts tun.\n'];
        pressesForShock = p.presentation(phase).press2shock(p.presentation(phase).world);
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center',p.text.color,[],[],[],2,[]);
        t=Screen('Flip',p.ptb.w);
        Log(t,-1,99);
        %show the messages at the experimenter screen
        fprintf('=========================================================\n');
        fprintf('Text shown to the subject:\n');
        fprintf(text);
        fprintf('=========================================================\n');
        WaitSecs(4)
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        t = Screen('Flip',p.ptb.w);
        nShocks=round(press_count/pressesForShock);
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
        fprintf('Waiting for 2 secs.\n')
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
        %Box Onset            :     4    info: NaN;
        %UCS Delivery         :     5    info: NaN;
        %Stimulus Offset      :     6    info: NaN;
        %Key Presses          :     7    info: NaN;
        %Tracker Offset       :     8    info: NaN;
        %new Block            :     9    info: number of block
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
    function centerput = CenterStarfish(imput)
        Nrows = size(imput,1); %this is x
        Ncols = size(imput,2); %this is y
        offset_x = 15; %this was determined via entering the clicking world.
        offset_y = 10;
        centerput = imput([(Nrows-offset_y):Nrows 1:(Nrows-offset_y-1)],[(offset_x+1):Ncols 1:offset_x],:);
    end
end
