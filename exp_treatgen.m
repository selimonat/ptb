function [p]=exp_treatgen(subject,run,csp,tonic,middletemp,lowtemp)
%[p]=FearGen_eyelab(subject,phase,csp,PainThreshold)
%
%Used for fearamy project, based on the FearGen_eyelab code. It increments
%it by adding scanner pulse communications.
%
%
mrt   = 0;
debug = 0;%debug mode
laptop = 0;
arduino = 0;
%replace parallel port function with a dummy function
if ismac
    %   outp = @(x,y) fprintf('[%i %i]\n',x,y);
end
if nargin ~= 6
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
el        = 0;%[];
p         = [];
s         = [];
SetParams;
if arduino
    SetArduino;
end
SetPTB;
%
%init all the variables
t                         = [];
nTrial                    = 0;
%%
p.var.event_count         = 0;
%%
if el
    InitEyeLink;
end
WaitSecs(2);
KbQueueStop(p.ptb.device);
KbQueueRelease(p.ptb.device);
%save again the parameter file
fprintf('saving parameter file. \n');
% save(p.path.path_param,'p');
if run == 0
    p.var.ExpPhase  = run;%set this after the calibration;
    ShowInstruction(1,1);
    ApplyAndRate;
    ShowInstruction(2,1);
    TENSdemo;
    ShowInstruction(3,1);
    PresentStimuli;
    ShowInstruction(20,0,2);
else
    %
    if el
        CalibrateEL;
    end
    p.var.ExpPhase  = run;%set this after the calibration;
    if run ==1
        ShowInstruction(4,1);
        for ninstr = 400:406
            ShowInstruction(ninstr,1);
        end
    else
        ShowInstruction(44,1)
    end
    ApplyAndRate;
    PresentStimuli;
    Summary;
    WaitSecs(3);
    %turn scanner off
    if run == 5
        AskDetectionSelectable;
    end
    ShowInstruction(21,1);
end

%get the eyelink file back to this computer
if el
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
%close everything down
% try
%     addpath('/USER/onat/Code/globalfunctions/ssh2_v2_m1_r6/ssh2_v2_m1_r6/')
%     p.path.tarname = [p.path.finalsubject(1:end-1) '.tar'];
%     tar(p.path.tarname,p.path.finalsubject);
%     [a b c] = fileparts( p.path.tarname);
%     cd(a)
%     scp_simple_put('sanportal','onat','',[b c]);
%     fprintf('Copying to neuronass succesfull...\n');
% catch
%     fprintf('Copying to neuronass failed...\n');
% end
cleanup;

    function AskDetectionSelectable
        %asks subjects to select the face that was associated with a shocks
        positions          = circshift(1:8,[1 PsychRandSample(1:8,[1 1])]);%position of the marker
        p.var.ExpPhase = 4;
        ShowInstruction(8,1);
        %%
        increment([p.keys.increase p.keys.decrease]) = [1 -1];%key to increment mapping
        %%
        ok                 = 1;
        while ok
            DrawCircle;
            Screen('FrameOval', p.ptb.w, [255 255 255], p.stim.circle_rect(positions(1),:), 2);%draw the marker circle somewhere random initially.
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
        p.out.selectedface = p.stim.circle_order(positions(1));
    end
    function DrawCircle
        Screen('FillRect', p.ptb.w ,[0 0 0], p.ptb.rect ); %black background
        for npos = 1:p.stim.tFace
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites_cut(p.stim.circle_file_id(npos)),[],p.stim.circle_rect(npos,:));
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
    function AskDetection
        %
        p.var.ExpPhase = 3;
        ShowInstruction(801,1);
        %% show a fixation cross
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y(1)];%show the fixation cross at the lip position to ease the subsequent drift correction.
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.imrect ); %always create a gray background
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
        
        Screen('DrawingFinished',p.ptb.w,0);
        Screen('Flip',p.ptb.w);
        StartEyelinkRecording(1,0,p.var.ExpPhase,0,0,0,fix,0);
        WaitSecs(1.5);
        %%
        DrawCircle;
        %Stimulus onset
        Screen('Flip',p.ptb.w);
        Eyelink('Message', 'Stim Onset');
        Eyelink('Message', 'SYNCTIME');
        %%
        WaitSecs(30);
        Screen('Flip',p.ptb.w);
        Eyelink('Message', 'Stim Offset');
        Eyelink('Message', 'BLANK_SCREEN');
        StopEyelinkRecording;
    end

    function PresentStimuli
        if arduino
            serialcom(s,'T',p.presentation.pain.tonic(1));
        end
        %Enter the presentation loop and wait for the first pulse to
        %arrive.
        %wait for the dummy scans
        %         [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%will log it
        %         KbQueueStop(p.ptb.device);
        %         WaitSecs(.05);
        %         KbQueueCreate(p.ptb.device);
        %         KbQueueStart(p.ptb.device);%this means that from now on we are going to log pulses.
        %If the scanner by mistake had been started prior to this point
        %those pulses would have been not logged.
        %log the pulse timings.
        %         TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        for nTrial  = 1:p.presentation.tTrial;
            
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            fix          = p.presentation.CrossPosition(nTrial,:); %dummy:[656   280   664   320;    640   296  680   304]
            ISI          = p.presentation.tonicpain(nTrial);
            ucs          = p.presentation.ucs(nTrial);
            dist         = p.presentation.dist(nTrial);
            if ucs
                tempC = p.presentation.pain.low(nTrial);
            else
                tempC = p.presentation.pain.middle(nTrial);
            end
            %
            %OnsetTime     = TimeEndStim + ISI-p.duration.stim - p.ptb.slack;
            fprintf('\nTrial %d of %d, Stim: %d, Temp: %5.2f, UCS: %d. ',nTrial,p.presentation.tTrial,stim_id,tempC,ucs);
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            [TimeEndStim] = Trial(nTrial, ISI, tempC, stim_id, ucs, dist, fix);
            %fprintf('OffsetTime: %05.8gs, Difference of %05.8gs\n',TimeEndStim,TimeEndStim-OnsetTime-p.duration.stim);
            %
            %dump itfa
            [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
            %log everything but "pulse keys" as pulses, not as keypresses.
            if mrt == 1
                pulses = (keycode == p.keys.pulse);
                if any(~pulses);%log keys presses if only there is one
                    Log(secs(~pulses),7,keycode(~pulses));
                end
                if any(pulses);%log pulses if only there is one
                    Log(secs(pulses),0,keycode(pulses));
                end
            end
            %check if temperatures need to be adapted
            adaptTemp(nTrial,ucs);
        end
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        if mrt ==1
            if p.var.ExpPhase > 0
                WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%
                fprintf('OK!! Stop the Scanner\n');
            end
        end
        %dump the final events
        [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
        %log everything but "pulse keys" as pulses, not as keypresses.
        
        if mrt ==1
            pulses          = (keycode == p.keys.pulse);
            if any(~pulses);%log keys presses if only there is one
                Log(secs(~pulses),7,keycode(~pulses));
            end
            if any(pulses);%log pulses if only there is one
                Log(secs(pulses),0,keycode(pulses));
            end
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        %         if mrt == 1
        %             WaitSecs(10);
        %         end
    end
    function rating = RatePain(nTrial,tonictemp);
        time2rate = p.duration.rate;
        if nTrial == 0;
            time2rate = p.duration.rate +10;
        end
        OnSetTime = GetSecs + .1;
        RateOn    = GetSecs + min(p.presentation.tonicpain);
        EndTrial  = OnSetTime + 5 + p.duration.rate;
        if nTrial < 2
            Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
            Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop        TimeCrossOn  = Screen('Flip',p.ptb.w,Fix1On,0);
            Screen('DrawingFinished',p.ptb.w,0);
            TimeCrossOn  = Screen('Flip',p.ptb.w,0);
            MarkCED( p.com.lpt.address, p.com.lpt.Fix1Onset);
            Log(TimeCrossOn,2,p.ptb.centralFixCross);%cross onset.
        end
        while GetSecs < RateOn;end
        rateinit = randi(p.rating.initrange);
        [currentRating.finalRating,currentRating.RT,currentRating.response] = vasScale(p.ptb.w,p.ptb.rect,time2rate,rateinit,...
            p.stim.bg,p.ptb.startY,p.keys,'pain');
        RateOff = Screen('Flip',p.ptb.w);
        Log(RateOff,2,p.ptb.centralFixCross);
        MarkCED(p.com.lpt.address, p.com.lpt.Fix1Onset);
        PutRatingLog(nTrial,currentRating,tonictemp,rateinit,'pain')
        while GetSecs < EndTrial;end
        rating = currentRating.finalRating;
    end
    function ApplyAndRate
       ShowInstruction(11,1);
       ok = 0;
       while ok == 0
           rampdur = abs(p.presentation.pain.tonic(1) - p.presentation.pain.base)./p.presentation.pain.ror;
           p.log.ARcount = p.log.ARcount + 1;
           Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
           Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop
           Screen('DrawingFinished',p.ptb.w,0);
           TimeCrossOn  = Screen('Flip',p.ptb.w,0);
           MarkCED( p.com.lpt.address, p.com.lpt.Fix1Onset);
           Log(TimeCrossOn,2,p.ptb.centralFixCross);%cross onset.
           k = 0;
           while k ~= KbName('v');
               pause(0.1);
               fprintf('Is the thermode set? Press v to confirm that you will now press Pre-test and START at the thermode.')
               [~, k] = KbStrokeWait(p.ptb.device);
               k = find(k);
           end
           fprintf('.. Continuing!\n')
           WaitSecs(.5);
           starttime = GetSecs;
           Log(starttime,7,k);
           ShowInstruction(9,0,rampdur+1) % Temp rising...
           Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
           Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop
           Screen('DrawingFinished',p.ptb.w,0);
           TimeCrossOn  = Screen('Flip',p.ptb.w,0);
           Log(TimeCrossOn,2,p.ptb.centralFixCross);%cross onset.
           WaitSecs(3);
           rating = RatePain(0,p.presentation.pain.tonic(1));
           Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
           Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop        TimeCrossOn  = Screen('Flip',p.ptb.w,Fix1On,0);
           Screen('DrawingFinished',p.ptb.w,0);
           TimeCrossOn  = Screen('Flip',p.ptb.w,0);
           MarkCED( p.com.lpt.address, p.com.lpt.Fix1Onset);
           Log(TimeCrossOn,2,p.ptb.centralFixCross);%cross onset.
           putAR    = [tonic rating];
           p.log.AR = [p.log.AR; putAR];
           k = 0;
           while ~ or(k == KbName('v'),k == KbName('c'));
               pause(0.1);
               fprintf('Do you want to change the temp? Press c to correct (then STOP), or v to continue...\n')
               [~, k] = KbStrokeWait(p.ptb.device);
               k = find(k);
           end
           if k == KbName('v')
               ok = 1;
               fprintf('Continuing.\n')
           elseif k == KbName('c')         
               ShowInstruction(12,1);
               x = input('.\nEnter the next tonic pain temperature we will try.\n');
               delta = x - p.presentation.pain.tonic(1);
               p.presentation.pain.tonic(1:end) = x;
               p.presentation.pain.middle       = p.presentation.pain.middle + delta;
               p.presentation.pain.low          = p.presentation.pain.low + delta;
               fprintf('Temps are now:\n');
               fprintf('Tonic:  %5.2f C\n',p.presentation.pain.tonic(1));
               fprintf('Middle: %5.2f C\n',p.presentation.pain.middle(1));
               fprintf('Low:    %5.2f C.\n',p.presentation.pain.low(1));
               if arduino
                   serialcom(s,'T',p.presentation.pain.tonic(1));
               end
           end
       end
    end
    function Summary
        fprintf('=================\n')
        fprintf('Rating results:\n')
        fprintf('single ratings for middle temp: %s\n',num2str(p.log.ratings.relief(:,3)'));
        fprintf('Mean rating for middle temp:    %5.2f\n',nanmean(p.log.ratings.relief(:,3)));
        fprintf('single ratings for UCS:         %s\n',num2str(p.log.ratings.relief(logical(p.presentation.ucs),3)'));
        fprintf('Mean rating for UCS:            %5.2f\n',nanmean(p.log.ratings.relief(logical(p.presentation.ucs),3)));
        fprintf('=================\nYour final temperatures were:\n')
        fprintf('Your final temperatures were: tonic:  %5.2f\n',p.presentation.pain.tonic(end))
        fprintf('                              middle: %5.2f\n',p.presentation.pain.middle(end))
        fprintf('                              low:    %5.2f\n',p.presentation.pain.low(end))
        
    end
    function [TimeEndStim] = Trial(nTrial, ISI, tempC, stim_id, ucs, dist, fix)
        tonic = p.presentation.pain.tonic(nTrial);
        if p.presentation.ratepain(nTrial)
            RatePain(nTrial,tonic);
        end
        rampdur = abs((tempC - p.presentation.pain.tonic(nTrial)))/p.presentation.pain.ror;
        FixCross     = [fix(1)-p.ptb.fc_width,fix(2)-p.ptb.fc_size,fix(1)+p.ptb.fc_width,fix(2)+p.ptb.fc_size;...
            fix(1)-p.ptb.fc_size,fix(2)-p.ptb.fc_width,fix(1)+p.ptb.fc_size,fix(2)+p.ptb.fc_width]; %this is the fixcross before the face, not the central one
        %get all the times
        jitterF     = rand(1).*.3; %jitter Fix
        jitterR     = rand(1).*.3;   %jitter Ramp
        OnsetTime   = GetSecs + .05; %allow to compute and draw and so on
        Fix1On      = OnsetTime;
        Fix2On      = OnsetTime + ISI;
        FaceOn      = OnsetTime + ISI + p.duration.fix + jitterF;
        FaceOff     = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face;
        Ramp1On     = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face + jitterR;
        Plateau     = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face + jitterR + rampdur;
        RateTOn     = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face + jitterR + rampdur + p.duration.treatment - 2*rampdur; %dur.treatment - 2*rampdur is total plateau duration
        RateTOff    = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face + jitterR + rampdur + p.duration.treatment - 2*rampdur + p.duration.rate;
        Ramp2On     = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face + jitterR + p.duration.treatment; % not needed actually, because this just automatically happens after rating.
        TimeEndStim = OnsetTime + ISI + p.duration.fix + jitterF + p.duration.face + jitterR + p.duration.treatment + p.duration.rate + p.duration.poststim - jitterF - jitterR;
        %% Baseline, tonic pain, inkl. white fixcross in the middle
        if nTrial ==1
            Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
            Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop        TimeCrossOn  = Screen('Flip',p.ptb.w,Fix1On,0);
            Screen('DrawingFinished',p.ptb.w,0);
            TimeCrossOn  = Screen('Flip',p.ptb.w,Fix1On,0);
            MarkCED( p.com.lpt.address, p.com.lpt.Fix1Onset);
            Log(TimeCrossOn,2,p.ptb.centralFixCross);%cross onset.
        end
        %% Show 2nd Fixcross, before Face
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
        Screen('FillRect', p.ptb.w, p.stim.white, FixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w,Fix2On,0);
        Log(TimeCrossOn,15,FixCross')
        %% Draw the stimulus to the buffer
        if stim_id ~=0
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        end
        %% Face Stimulus Onset
        TimeFaceOnset  = Screen('Flip',p.ptb.w,FaceOn,0);%asap and dont clear
        %send eyelink and ced a marker asap
        Log(TimeFaceOnset,13,stim_id)
        MarkCED(p.com.lpt.address, p.com.lpt.FaceOnset );%this actually didn't really work nicely.
        fprintf('Face No %g is on.\n',stim_id)
        %% Face Stim Off, Pain Cross on
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
        Screen('FillRect', p.ptb.w, p.stim.white,p.ptb.centralFixCross');%draw the central cross
        Screen('DrawingFinished',p.ptb.w,0);
        TimeFaceOffset  = Screen('Flip',p.ptb.w,FaceOff,0);%asap and dont clear
        Log(TimeFaceOffset,14,stim_id);%log the stimulus offset
        Log(GetSecs,3,stim_id);
        %% ramp to treatment temp
        while GetSecs < Ramp1On;end
        if arduino
            serialcom(s,'START');
        end
        Log(Ramp1On, 4, p.presentation.pain.ror); % ramp up
        MarkCED(p.com.lpt.address, p.com.lpt.Ramp1);
        fprintf('Ramping to %5.2f C in %.02f s.\n',tempC,rampdur)
        if arduino
            serialcom(s,'SET',tempC);
        end
        while GetSecs < Plateau
        end
        MarkCED(p.com.lpt.address,p.com.lpt.Plateau);
        Log(Plateau, 5, tempC); % begin of stim plateau
        MarkCED(p.com.lpt.address,p.com.lpt.Plateau);
        if ucs == 1
            fprintf('This is a UCS trial!');
            MarkCED(p.com.lpt.address, p.com.lpt.ucs);
        end
        countedDown = 1;
        while GetSecs < RateTOn
            [countedDown]=CountDown(GetSecs-Plateau,countedDown,'.');
        end
         %% Flip to Rating
        Log(RateTOn,11,NaN);%VAS Treatment onset.
        rateinit = randi(p.rating.initrange);
        [currentRating.finalRating,currentRating.RT,currentRating.response] = vasScale(p.ptb.w,p.ptb.rect,p.duration.rate,rateinit,...
            p.stim.bg,p.ptb.startY,p.keys,'relief');       
        RateOff = Screen('Flip',p.ptb.w);
        Log(RateOff,12,NaN);%VAS Treatment offset.
        fprintf('Ramping back to baseline %5.2f C in %.02f s.',tonic,rampdur)
        if arduino
            serialcom(s,'SET',p.presentation.pain.tonic(nTrial));
        end
        MarkCED(p.com.lpt.address, p.com.lpt.Ramp2)
        Log(GetSecs, 6, p.presentation.pain.ror) % ramp back to baseline
        fprintf('Took subject %5.2f seconds to respond. \n',currentRating.RT);
        PutRatingLog(nTrial,currentRating,tempC,rateinit,'relief');
        %% back to white cross (whenever ready)
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop        TimeCrossOn  = Screen('Flip',p.ptb.w,Fix1On,0);
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w);
        MarkCED( p.com.lpt.address, p.com.lpt.Fix1Onset);
        Log(TimeCrossOn,2,p.ptb.centralFixCross');%cross onset.
        while GetSecs < TimeEndStim %otherwise the trial just ends
        end
        if nTrial == p.presentation.tTrial
            RatePain(nTrial,tonic);
        end
    end
    function TENSdemo
        basetemp   = p.presentation.pain.tonic(1);
        middletemp = p.presentation.pain.middle(1);
        lowtemp    = p.presentation.pain.low(1);
        demotemps = [middletemp lowtemp middletemp lowtemp];
        rampdurs  = abs((basetemp-demotemps))./p.presentation.pain.ror;
        textstring  ={'TENS aktiv' 'TENS aktiv' 'TENS aktiv' 'TENS aktiv'};
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
        Screen('FillRect', p.ptb.w,  p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        Screen('Flip',p.ptb.w);
        for dc = 1:length(demotemps)
            text = textstring{dc};
            StartTrial = GetSecs;
            fixon     = StartTrial + .1;
            tagon     = StartTrial  + .1 + 5;
            rampon    = StartTrial  + .1 + 5 + 1 + rand(1)*.25;
            plateauon = rampon + rampdurs(dc);
            rateon    = rampon + p.duration.treatment;
            rateoff   = rampon + p.duration.treatment + p.duration.rate;
            
            %white cross
            if dc == 1
                Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
                Screen('FillRect', p.ptb.w,  p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop
                Screen('DrawingFinished',p.ptb.w,0);
                FlipTime = Screen('Flip',p.ptb.w,fixon,0);
                Log(FlipTime,2,p.ptb.centralFixCross);
            end
            Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
            Screen('FillRect', p.ptb.w,  p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop
            DrawFormattedText(p.ptb.w, text, 'center', p.ptb.midpoint(2)./1.2,p.stim.white);
            Screen('DrawingFinished',p.ptb.w,0);
            FlipTime = Screen('Flip',p.ptb.w,tagon,0);
            Log(FlipTime,3,p.ptb.centralFixCross);
            while GetSecs < rampon; end
            if arduino
                serialcom(s,'START');
                serialcom(s,'SET',demotemps(dc));
            end
            Log(GetSecs,4,p.presentation.pain.ror);
            Log(plateauon,5,demotemps(dc));
            while GetSecs < rateon; end
            Log(GetSecs,11,NaN);
            rateinit = randi(p.rating.initrange);
            [currentRating.finalRating,currentRating.RT,currentRating.response] = vasScale(p.ptb.w,p.ptb.rect,p.duration.rate,rateinit,...
                p.stim.bg,p.ptb.startY,p.keys,'relief');
            Log(GetSecs,12,NaN);
            PutRatingLog(dc,currentRating,demotemps(dc),rateinit,'TENSdemo');
            fprintf(textstring{dc})
            fprintf(' condition with Temp of %g was rated as VAS  = %g \n',demotemps(dc),currentRating.finalRating)
            Log(GetSecs,6,p.presentation.pain.ror);
            if arduino
                serialcom(s,'SET',basetemp);
            end
            Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
            Screen('FillRect', p.ptb.w,  p.stim.white, p.ptb.centralFixCross');%draw the prestimus cross atop
            Screen('DrawingFinished',p.ptb.w,0);
            FlipTime = Screen('Flip',p.ptb.w,fixon,0);
            Log(FlipTime,2,p.ptb.centralFixCross);
            while GetSecs < rateoff;end % if subject rated faster than allowed, we add this to ISI.
        end
        k = 0;
        while ~ or(k == KbName('v'),k == KbName('c'));
            pause(0.1);
            fprintf('Mean VAS: CS- (%5.2f C) = %g, CS+ (%5.2f C) = %g...\n',demotemps(1),nanmean(p.log.ratings.tensdemo([1 3],3)),demotemps(2),nanmean(p.log.ratings.tensdemo([2 4],3)))
            fprintf('Are you OK with these ratings? Press c to correct, or v to continue...\n')
            [~, k] = KbStrokeWait(p.ptb.device);
            k = find(k);
        end
        if k == KbName('c')
            x1 = input(sprintf('Please enter the corrected CS- temperature (medium, before %5.2f).\n',demotemps(1)));
            x2 = input(sprintf('Please enter the corrected CS+ temperature (lower, before %5.2f).\n',demotemps(2)));
            p.presentation.pain.middle     = repmat(x1,[p.presentation.tTrial 1]);
            p.presentation.pain.low        = repmat(x2,[p.presentation.tTrial 1]);
            fprintf('Corrected temperatures to middle = %g and low = %g. \n',p.presentation.pain.middle(1),p.presentation.pain.low(1))
        elseif k == KbName('v')
            fprintf('Temperatures were okay. Continuing. \n')
        end
    end
    function PutRatingLog(currentTrial,currentRating,tempC,initVAS,type)
        if strcmp(type,'pain')
            if currentTrial == 0
                p.log.ratings.initialPain = currentRating.finalRating;
            else
                p.log.ratingEventCount                = p.log.ratingEventCount + 1;
                p.log.ratings.pain(currentTrial,1)    = tempC;
                p.log.ratings.pain(currentTrial,2)    = currentTrial;
                p.log.ratings.pain(currentTrial,3)    = currentRating.finalRating;
                p.log.ratings.pain(currentTrial,4)    = currentRating.response;
                p.log.ratings.pain(currentTrial,5)    = currentRating.RT;
                p.log.ratings.pain(currentTrial,6)    = initVAS;
            end
        elseif strcmp(type,'relief')
            p.log.ratingEventCount                    = p.log.ratingEventCount + 1;
            p.log.ratings.relief(currentTrial,1)       = tempC;
            p.log.ratings.relief(currentTrial,2)       = currentTrial;
            p.log.ratings.relief(currentTrial,3)       = currentRating.finalRating;
            p.log.ratings.relief(currentTrial,4)       = currentRating.response;
            p.log.ratings.relief(currentTrial,5)       = currentRating.RT;
            p.log.ratings.relief(currentTrial,6)       = initVAS;
        elseif strcmp(type,'TENSdemo')
            p.log.ratingEventCount                    = p.log.ratingEventCount + 1;
            if currentTrial == 0
                p.log.ratings.tensDEMOinitialPain = currentRating.finalRating;
            else
                p.log.ratings.tensdemo(currentTrial,1)    = tempC;
                p.log.ratings.tensdemo(currentTrial,2)    = currentTrial;
                p.log.ratings.tensdemo(currentTrial,3)    = currentRating.finalRating;
                p.log.ratings.tensdemo(currentTrial,4)    = currentRating.response;
                p.log.ratings.tensdemo(currentTrial,5)    = currentRating.RT;
                p.log.ratings.tensdemo(currentTrial,6)    = initVAS;
            end
        end
    end
    function adaptTemp(nTrial,ucs)
        adaptt = 0;
        adaptb = 0;
        if p.stim.phase ~=0
            if (p.presentation.pain.baseadapt == 1)&&(nTrial >= 3)&& (nTrial ~= p.presentation.tTrial);
                basemed = median(p.log.ratings.pain(nTrial-2:nTrial,3));
                if (90 > basemed)&&(80 <= basemed)
                    p.presentation.pain.tonic(nTrial+1:end) = p.presentation.pain.tonic(nTrial) - p.presentation.pain.adaptstep;
                    fprintf('Median VAS was %g (not near 70). Decreased baseline Temp from %5.2f to %5.2f.\n',basemed,p.presentation.pain.tonic(nTrial),p.presentation.pain.tonic(nTrial+1))
                    adaptb = -1;
                elseif (basemed >= 90)
                    p.presentation.pain.tonic(nTrial+1:end) = p.presentation.pain.tonic(nTrial) - p.presentation.pain.adaptstep*2;
                    fprintf('This was really too hot, subject rated %g. Decreased baseline Temp from %5.2f to %5.2f.\n',basemed,p.presentation.pain.tonic(nTrial),p.presentation.pain.tonic(nTrial+1))
                    adaptb = -2;
                elseif basemed < 60
                    p.presentation.pain.tonic(nTrial+1:end) = p.presentation.pain.tonic(nTrial) + p.presentation.pain.adaptstep;
                    fprintf('Median VAS was %g (not near 70). Increased baseline Temp from %5.2f to %5.2f.\n',basemed,p.presentation.pain.tonic(nTrial),p.presentation.pain.tonic(nTrial+1))
                    adaptb = 1;
                end
            end
            if (p.presentation.pain.treatadapt == 1)&&ucs  % ucs only happens twice... probably better to adapt it very flexibly(?)
                treatmed = p.log.ratings.relief(nTrial,3);
                
                if (treatmed >= 40)
                    p.presentation.pain.low(nTrial+1:end) = p.presentation.pain.low(nTrial) - p.presentation.pain.adaptstep;
                    fprintf('UCS was rated as %g (not near 30). Decreased UCS treatment Temp from %5.2f to %5.2f.\n',treatmed,p.presentation.pain.low(nTrial),p.presentation.pain.low(nTrial+1))
                    adaptt = -1;
                elseif treatmed < 20
                    p.presentation.pain.low(nTrial+1:end) = p.presentation.pain.low(nTrial) + p.presentation.pain.adaptstep;
                    fprintf('UCS was rated as %g (not near 30). Increased UCS treatment Temp from %5.2f to %5.2f.\n',treatmed,p.presentation.pain.low(nTrial),p.presentation.pain.low(nTrial+1))
                    adaptt = 1;
                end
            elseif ~ucs
                if (p.presentation.pain.treatadapt == 1)&&(sum(p.presentation.ucs(1:nTrial)==0) >= 3) && (nTrial ~= p.presentation.tTrial); %nTrial > 3 because we want the last three ratings to go to median
                    
                    dummy = p.log.ratings.relief(~p.presentation.ucs(1:nTrial),3);
                    treatmed = median(dummy(end-2:end));
                    if (treatmed >= 60)
                        p.presentation.pain.middle(nTrial+1:end) = p.presentation.pain.middle(nTrial) - p.presentation.pain.adaptstep;
                        fprintf('Median VAS was %g (not near 50).  Decreased treatment Temp from %5.2f to %5.2f.\n',treatmed,p.presentation.pain.middle(nTrial),p.presentation.pain.middle(nTrial+1))
                        adaptt = -1;
                    elseif treatmed < 40
                        p.presentation.pain.middle(nTrial+1:end) = p.presentation.pain.middle(nTrial) + p.presentation.pain.adaptstep;
                        fprintf('Median VAS was %g (not near 50). Increased treatment Temp from %5.2f to %5.2f.\n',treatmed,p.presentation.pain.middle(nTrial),p.presentation.pain.middle(nTrial+1))
                        adaptt = 1;
                        if p.presentation.pain.middle(nTrial+1) == p.presentation.pain.tonic(nTrial+1)
                            p.presentation.pain.middle(nTrial+1:end) = p.presentation.pain.tonic(nTrial+1)-.5;
                            fprintf('Reached baseline temp limit. Treatment temp set back to %5.2f.\n',p.presentation.pain.middle(nTrial+1))
                        end
                    end
                end
            end
            %check if temps are still different from each others
            if nTrial ~= p.presentation.tTrial;
                if p.presentation.pain.low(nTrial+1) == p.presentation.pain.middle(nTrial+1);
                    p.presentation.pain.low(nTrial+1:end) = p.presentation.pain.middle(nTrial+1)-p.presentation.pain.adaptstep;
                    warning('Needed to put UCS temp down, because middle temp was the same.\n')
                end
                if any([adaptb adaptt])
                    fprintf('Temps are now:\nBase:    %5.2f\nMiddle:  %5.2f\nLow:     %5.2f\n',p.presentation.pain.tonic(nTrial+1),p.presentation.pain.middle(nTrial+1),p.presentation.pain.low(nTrial+1))
                end
            end
            p.presentation.pain.adapt(nTrial,:) = [adaptb adaptt];
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
        elseif strcmp(p.hostname,'isn3464a9d59588') % Lea's HP
            p.path.baselocation       = 'C:\Users\Lea\Documents\Experiments\';
        end
        
        p.path.experiment             = [p.path.baselocation 'Treatgen\'];
        p.path.stim              = [p.path.experiment 'Stimuli\'];
        p.path.stim24            = [p.path.stim '24bit' filesep];
        p.path.stim_cut          = [p.path.stim 'cut' filesep];
        %
        p.subID                       = sprintf('sub%03d',subject);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment  'data\tmp' filesep p.subID '_' timestamp filesep ];
        p.path.finalsubject           = [p.path.experiment 'data' filesep p.subID '_' 'p0' num2str(run) filesep];
        p.path.path_edf               = [p.path.subject  'eye' filesep];
        p.path.edf                    = sprintf([p.subID 'p%02d.edf' ],run);
        p.path.path_param             = [p.path.subject 'stimulation' filesep 'data.mat'];
        %create folder hierarchy
        mkdir(p.path.subject);
%         mkdir(p.path.finalsubject);
        mkdir([p.path.subject 'scr']);
        mkdir([p.path.subject 'eye']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);
%         mkdir([p.path.subject 'diary'])
%         p.path.diaryfilename  = [p.path.subject 'diary\diary.txt'];
%         diary(p.path.diaryfilename)
%         %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files     p.stim.label]   = FileMatrix([p.path.stim '*.bmp']);
        [p.stim.files_cut p.stim.label]   = FileMatrix([p.path.stim_cut '*.png']);
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
        p.text.fontname                = 'Arial';
        p.text.fontsize                = 18;%30;
        p.text.fixsize                 = 60;
        %rating business
        p.rating.division              = 101;%number of divisions for the rating slider
        p.rating.initrange             = [30 70];
        p.rating.repetition            = 1;%how many times a given face has to be repeated...
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
        if strcmp(p.hostname,'triostim1')
            p.keys.confirm                 = KbName('4$');
            p.keys.increase                = KbName('1!');
            p.keys.decrease                = KbName('3#');
            p.keys.pulse                   = KbName('5%');
            p.keys.el_calib                = KbName('v');
            p.keys.el_valid                = KbName('c');
            p.keys.esc                     = KbName('esc');
            p.keys.enter                   = KbName('return');
        elseif strcmp(p.hostname,'isn3464a9d59588') % Lea's HP
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('space');
            p.keys.increase                = KbName('right');
            p.keys.decrease                = KbName('left');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
            p.keys.null                    = KbName('0)');
            p.keys.one                     = KbName('1!');
            p.keys.v                       = KbName('v');
            p.keys.c                       = KbName('c');
        end
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address = 888;
        %codes for different events
        p.com.lpt.Fix1Onset = 2;
        p.com.lpt.FaceOnset = 4;
        p.com.lpt.RateB     = 8;
        p.com.lpt.RateT     = 16;
        p.com.lpt.Ramp1     = 32;
        p.com.lpt.Plateau   = 64;
        p.com.lpt.Ramp2     = 128;
        p.com.lpt.ucs       = 1;
        
        
        %
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.fix                 = .85; % this is minimum, gets a jittered addition
        p.duration.face                = 1.5; % face stimulus
        p.duration.poststim            = 1;
        p.duration.treatment           = 6;   % treatment plateau
        p.duration.rate                = 5;   % how long can subject rate maximally
        p.duration.keep_recording      = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence
        if run == 0
            seq.cond_id       = nan(10,1);
            seq.tTrial        = 10;
            seq.tonicpain     = Shuffle([5 6 7 6 5 6 7 6 6 5]);
            seq.ratepain      = [1 zeros(1,seq.tTrial-1)];
            seq.stim_id       = [0 Shuffle(1:8)' csp];
            seq.ucs           = [zeros(1,9) 1];
            seq.dist          = MinimumAngle((seq.stim_id-1)*45,(csp-1)*45); %actually, there is no csp yet. so it could also be nans.
            p.presentation    = seq;
            p.presentation.tTrial = 10;
        elseif run == 1
            load([p.path.stim 'stimlist/seq_cond.mat']);
            seqid             = subject+((run-1)*50);
            p.presentation    = seq(seqid,csp);
            p.presentation.seqid = seqid;
        elseif run == 10 % this could be any dummy seq, e.g. conditioning
            seq.cond_id       = Shuffle([1 1 1 1 2 2 2 2 3 3 3]);
            seq.tTrial        = length(seq.cond_id);
            seq.ucs           = seq.cond_id == 9;
            seq.tonicpain     = randi([5 7],[1 11]);
            seq.ratepain      = zeros(1,11); seq.ratepain(1) = 1;
            seq.stim_id(seq.cond_id ==1)       = csp;
            seq.stim_id(seq.cond_id ==2)       = csn;
            seq.stim_id(seq.cond_id ==3)       = csp;
            seq.ucs           = seq.cond_id ==3;
            seq.dist          = MinimumAngle((seq.stim_id-1)*45,(csp-1)*45); %actually, there is no csp yet. so it could also be nans.
            seq.dist(seq.cond_id == 3)          = 500; %ucs
            p.presentation    = seq;
        else
            load([p.path.stim 'stimlist\seq04x8pr3.mat']);
            seqid             = subject+((run-2)*50);
            p.presentation    = seq(seqid,csp);
            p.presentation.seqid = seqid;
        end
        
        p.presentation.pain.base        = 25; %thermode constant
        p.presentation.pain.tonic       = repmat(tonic,[p.presentation.tTrial 1]);
        p.presentation.pain.middle      = repmat(middletemp,[p.presentation.tTrial 1]);
        p.presentation.pain.low         = repmat(lowtemp,[p.presentation.tTrial 1]);
        p.presentation.pain.ror         = 5;
        p.presentation.pain.adaptstep   = .5;
        p.presentation.pain.baseadapt   = 0; % do you want to adapt baseline temp online?
        p.presentation.pain.treatadapt  = 0; % do you want to adapt treatment temps online?
        p.presentation.pain.adapt       = zeros(p.presentation.tTrial,2); % first column is baseline, second treatment, logs when it was adapted
        % codes will be:
        %  1  - increase
        % -1  - decrease
        % -2  - baseline was too hurtful
        %  0  - no action taken
        if ~ismember(run,1:4)
            p.presentation.CrossPosition = FixationCrossPool;
        end
        clear seq
        %% create the randomized design
        p.stim.cs_plus                 = csp; %index of cs stimulus, this is the one with enhanced treatment
        p.stim.cs_minus                = csn; %this is only needed for beginning phase, where we condition people
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = run;
        
        p.log.ARcount                 = 0;
        p.log.AR                      = [];
        p.log.ratingEventCount        = 0;
        p.log.ratings.pain            = nan(p.presentation.tTrial,6);
        p.log.ratings.relief          = nan(p.presentation.tTrial,6);
        p.log.ratings.tensdemo        = nan(4,6);
        p.out.log                     = zeros(1000000,4).*NaN;
        p.out.response                = zeros(p.presentation.tTrial,1);
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
    end
    function SetArduino
        s = serial('COM5','BaudRate',19200);
        fopen(s);
        WaitSecs(1);
        serialcom(s,'T',p.presentation.pain.tonic(1));
        serialcom(s,'ROR',p.presentation.pain.ror);
        WaitSecs(.5);
        serialcom(s,'DIAG');
        WaitSecs(1);
    end
    function SetPTB
        %KbName('UnifyKeyNames');
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
        if laptop
            p.ptb.screenNumber = 1;
        end
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %set the resolution correctly
        res = Screen('resolution',p.ptb.screenNumber);
        HideCursor(p.ptb.screenNumber);
        %spit out the resolution
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.var.current_bg);
        %Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        
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
        p.ptb.fc_size               = 20;
        p.ptb.fc_width              = 4;
        p.ptb.fc_color              = [130 50 0];
        p.ptb.startY                = p.ptb.midpoint(2);
        fix          = [p.ptb.midpoint(1) p.ptb.startY]; % yaxis is 1/4 of total yaxis
        p.ptb.centralFixCross     = [fix(1)-p.ptb.fc_width,fix(2)-p.ptb.fc_size,fix(1)+p.ptb.fc_width,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-p.ptb.fc_width,fix(1)+p.ptb.fc_size,fix(2)+p.ptb.fc_width];
        
        p.stim.white                   = [255 255 255];        %
        %%
        %priorityLevel=MaxPriority(['GetSecs'],['KbCheck'],['KbWait'],['GetClicks']);
        Priority(MaxPriority(p.ptb.w));
        %this is necessary for the Eyelink calibration
        %InitializePsychSound(0)
        %sound('Open')
        %         Beeper(1000)
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
        while ~(k == 25 | k == 86 );
            pause(0.1);
            outp(p.com.lpt.address,256);%256 means all channels.
            fprintf('Is everything set?\n\n')
            fprintf('Digitimer still off?\n\n')
            fprintf('Did the trigger test work?\n\nPress c to send it again, v to continue...\n')
            [~, k] = KbStrokeWait(p.ptb.device);
            k = find(k);
        end
        fprintf('Continuing...\n');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the pictures to the memory.
        p.ptb.stim_sprites     = CreateStimSprites(p.stim.files);%
        p.ptb.stim_sprites_cut = CreateStimSprites(p.stim.files_cut);%
        %% take care of the circle presentation
        %order of faces on the circle that will be shown at the end.
                if run ~= 0
                    circle_order = Shuffle(unique(p.presentation.dist(p.presentation.dist < 500)));%
                    circle_order(end+1)=circle_order(1);
%                     while any(abs(diff(circle_order)) < 50);%check that neighbors will not be neighbors in the next order.
%                         circle_order        = Shuffle(unique(p.presentation.dist(p.presentation.dist < 500)));
%                         circle_order(end+1) = circle_order(1);%to be successful the check has to consider the circularity.
%                     end
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
        function [out]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:p.stim.tFile
                filename       = files(nStim,:);
                [im , ~, ~]    = imread(filename);
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
            end
        end
    end
    function [finalRating,reactionTime,response] = vasScale(window,windowRect,durRating,defaultRating,backgroundColor,StartY,keys,type)
        
        %% key settings
        KbName('UnifyKeyNames');
        lessKey =  keys.decrease; % yellow button
        moreKey =  keys.increase; % red button
        confirmKey =  keys.confirm;  % green button
        escapeKey = keys.esc;
        
        if isempty(window); error('Please provide window pointer for likertScale!'); end
        if isempty(windowRect); error('Please provide window rect for likertScale!'); end
        if isempty(durRating); error('Duration length of rating has to be specified!'); end
        
        %% Default values
        inactive   = 1; %should the irrelevant part of the scale be inactivated?
        nRatingSteps = p.rating.division;
        scaleWidth = 700;
        textSize = 20;
        lineWidth = 4;
        scaleColor = [255 255 255];
        %         if strcmp(type,'pain')
        %             activeColor = [255 0 0];
        %         elseif strcmp(type,'relief')
        %             activeColor = [0 0 255];
        %         else
        %             activeColor = [255 255 255];
        %         end
        activeColor = p.ptb.fc_color;
        if isempty(defaultRating); defaultRating = round(nRatingSteps/2); end
        if isempty(backgroundColor); backgroundColor = 0; end
        
        if inactive == 1
            defaultRating = ceil(nRatingSteps/2);
        end
        
        % if length(ratingLabels) ~= nRatingSteps
        %     error('Rating steps and label numbers do not match')
        % end
        
        %% Calculate rects
        activeAddon_width = 1.5;
        activeAddon_height = 20;
        [xCenter, yCenter] = RectCenter(windowRect);
        yCenter = StartY;
        axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        leftRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter; yCenter + lineWidth/2];
        rightRect = [xCenter; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        lowLabelRect = [axesRect(1),yCenter-20,axesRect(1)+6,yCenter+20];
        highLabelRect = [axesRect(3)-6,yCenter-20,axesRect(3),yCenter+20];
        ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
        % ticRects = [ticPositions;ones(1,nRatingSteps)*yCenter;ticPositions + lineWidth;ones(1,nRatingSteps)*yCenter+tickHeight];
        activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];
        %define text rects
        if strcmp(type,'relief')
            stringArray={ 'keine','Linderung','maximale','Linderung'};
        elseif strcmp(type,'pain')
            stringArray={ 'kein','Schmerz','maximaler','Schmerz'};
        end
        for i = 1:length(stringArray)
            [~, ~, textBox] = DrawFormattedText(window,char(stringArray(i)),0,0,backgroundColor);
            textWidths(i)=textBox(3)-textBox(1);
        end
        % keyboard
        inactivecol    = [130 130 130];
        
        Screen('TextSize',window,textSize);
        Screen('TextColor',window,[255 255 255]);
        Screen('TextFont', window, 'Arial');
        currentRating = defaultRating;
        finalRating = currentRating;
        reactionTime = 0;
        response = 0;
        first_flip  = 1;
        startTime = GetSecs;
        numberOfSecondsRemaining = durRating;
        nrbuttonpresses = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
        % tic; % control if timing is as long as durRating
        while numberOfSecondsRemaining  > 0
            Screen('FillRect',window,backgroundColor);
            Screen('FillRect',window,scaleColor,axesRect); %draw white axis
            Screen('FillRect',window,scaleColor,lowLabelRect);
            Screen('FillRect',window,scaleColor,highLabelRect);
            Screen('FillRect',window,activeColor,activeTicRects(:,currentRating));
            if strcmp(type,'pain') %we still differentiate between pain and relief so that they know whether it is pain NOW or relief experienced BEFORE
                DrawFormattedText(window, 'Bitte bewerten Sie den momentanen Schmerz.', 'center',yCenter-100, scaleColor);
                Screen('DrawText',window,'kein',axesRect(1)-textWidths(1)/2,yCenter+25,scaleColor);
                Screen('DrawText',window,'Schmerz',axesRect(1)-textWidths(2)/2,yCenter+45,scaleColor);
                Screen('DrawText',window,'maximaler',axesRect(3)-textWidths(3)/2,yCenter+25,scaleColor);
                Screen('DrawText',window,'Schmerz',axesRect(3)-textWidths(4)/2,yCenter+45,scaleColor);
            elseif strcmp(type,'relief')
               DrawFormattedText(window, 'Bitte bewerten Sie die Wirksamkeit der Behandlung.', 'center',yCenter-100, scaleColor);
                Screen('DrawText',window,'keine',axesRect(1)-textWidths(1)/2,yCenter+25,scaleColor);
                Screen('DrawText',window,'Linderung',axesRect(1)-textWidths(2)/2,yCenter+45,scaleColor);
                Screen('DrawText',window,'maximale',axesRect(3)-textWidths(3)/2,yCenter+25,scaleColor);
                Screen('DrawText',window,'Linderung',axesRect(3)-textWidths(4)/2,yCenter+45,scaleColor);
            end
            
            % Remove this line if a continuous key press should result in a continuous change of the scale
            %     while KbCheck; end
            
            if response == 0
                % set time 0 (for reaction time)
                if first_flip   == 1
                    secs0       = Screen('Flip', window); % output Flip -> starttime rating
                    first_flip  = 0;
                    % after 1st flip -> just flips without setting secs0 to null
                else
                    Screen('Flip', window);
                end
                
                [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                Log(secs,7,keyCode);
                if keyIsDown % only if a key was pressed we check which key it was
                    response = 0; % predefine variable for confirmation button 'space'
                    nrbuttonpresses = nrbuttonpresses + 1;
                    if keyCode(moreKey) % if it was the key we named key1 at the top then...
                        currentRating = currentRating + 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating > nRatingSteps
                            currentRating = nRatingSteps;
                        end
                    elseif keyCode(lessKey)
                        currentRating = currentRating - 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating < 1
                            currentRating = 1;
                        end
                    elseif keyCode(confirmKey)
                        finalRating = currentRating-1;
                        disp(['VAS Rating: ' num2str(finalRating)]);
                        response = 1;
                        reactionTime = secs - secs0;
                        break;
                    end
                end
            end
            
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
        end
        if  nrbuttonpresses ~= 0 && response == 0
            finalRating = currentRating - 1;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            fprintf('***********No Confirmation!***********\n');
        end
        if  nrbuttonpresses == 0
            finalRating = NaN; %NaN is NaN, no recoding necessary
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********No Response! Please check participant!***********\n'));
        end
        % toc
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
            text = ['Willkommen zum Experiment.\n' ...
                '\n'...
                'Wir werden Ihnen nun als Erstes demonstrieren,\n'...
                'wie sich die Schmerzreize während des Experiments anfühlen werden. \n'...
                'Sie stellen gleich eine für Sie individuell angepasste konstante Temperatur ein, \n'...
                'um einen durchgängigen, aushaltbaren Schmerz zu erzeugen.\n'...
                '\n'...
                'Drücken Sie die Leertaste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 11
            text = ['Sie erhalten nun die für Sie kalibrierte Temperatur.\n' ...
                'Nach einigen Sekunden werden Sie gebeten, diese auf einer Schmerzskala zu bewerten.\n' ...
                'Sie haben dazu 5 Sekunden Zeit.\n' ...
                '\n' ...
                'Drücken Sie die Leertaste um zu starten.\n' ...
                ];
        elseif nInstruct == 12
            text = ['Wir wiederholen den Vorgang noch einmal.\n' ...
                'Bitte geben Sie auf der Skala an, wie schmerzhaft Sie die gleich applizierte Temperatur empfinden.\n' ...
                '\n' ...
                'Drücken Sie die Leertaste um zu starten.\n' ...
                ];
        elseif nInstruct == 2%second Instr. of the training phase.
            text = ['Sie erhalten nun vier TENS Behandlungsdurchgänge, um Ihnen die Wirksamkeit zu demonstrieren.\n' ...
                'Hierbei bewerten Sie nun in jedem Durchgang,\n' ...
                'wie gut der Schmerz durch diese Behandlung gelindert wird,\n' ...
                'd.h. als wie wirksam die Behandlung empfinden.\n' ...
                'Sie haben dazu wie immer 5 Sekunden Zeit, um zu antworten.\n' ...
                'Es ist sehr wichtig, dass Sie Ihr Rating innerhalb dieser Zeit abgeben und bestätigen.\n' ...
                '\n'...
                'Drücken Sie die Leertaste um die Demonstration zu starten.\n' ...
                ];
        elseif nInstruct == 3
        text = ['Als nächstes werden wir Ihnen demonstrieren,\n' ...
            'wie die verschiedenen Durchgänge im Hauptexperiment funktionieren.\n' ...
            'Ganz zu Beginn bewerten Sie einmalig auf der Schmerzskala,\n' ...
            'wie schmerzhaft die angebrachte Temperatur für Sie ist.\n' ...
            'Anschließend folgt der erste Behandlungsdurchgang.\n' ...
            'Bitte schauen Sie generell immer auf die Fixationskreuze, die Ihre Position hin und wieder ändern.\n' ...
            '\n' ...
            'In jedem Durchgang wird Ihnen ein Gesicht präsentiert, das Sie aufmerksam betrachten sollen. \n' ...
            'Direkt nach dem Gesicht folgt die TENS Behandlung,\n'...
            'für die Sie anschließend wieder die Schmerzlinderung auf der gewohnten Skala bewerten.\n' ...
            'Es ist sehr wichtig, dass Sie Ihr Rating ganz intuitiv,\n' ...
            'aber innerhalb der gewohnten 5 Sekunden abgeben und bestätigen.\n' ...
            '\n' ...
            'Drücken Sie die Leertaste um die Demonstration zu starten.\n' ...
            ];
        elseif nInstruct == 299%short instruction before localizer
            text = ['Die Kalibrierung war erfolgreich.\n'...
                'Es startet nun eine kurze Vormessung (~2 min), während der Sie nichts tun müssen.\n\n'...
                ];
        elseif nInstruct == 4 %Instr. for the very first phase.
            text = ['Willkommen zum Hauptteil des Experiments.\n' ...
                'Auch in diesem Teil des Experiments erhalten Sie einen durchgängigen Schmerzreiz, \n'...
                'der in jedem Durchgang durch eine TENS Behandlung gelindert wird.\n' ...                
                'Wie zuvor geübt bewerten Sie hin und wieder den Schmerzreiz, sowie in jedem Durchgang die Schmerzlinderung.\n' ...
                '\n' ...
                'Wir verwenden ab jetzt unterschiedliche TENS-Frequenzen, von denen eine spürbar besser ist als der Rest.\n' ...
                '\n'...
                'Genau wie im vorherigen Durchgang sehen Sie vor jedem Behandlungsdurchgang ein Gesicht.\n'...
                'Dieses sollen Sie aufmerksam betrachten.\n'...
                'Nur EINS der Gesichter wird mit der besseren TENS Behandlung gepaart.\n'...
                'Sie werden also bemerken, dass unterschiedliche Gesichter unterschiedlich gute Behandlungen ankündigen.\n'...
                '\n'...
                'Beim ersten Durchgang jeden Blocks erscheint kein Gesicht, dies ist beabsichtigt, wundern Sie sich also nicht.'...
                '\n'...
                'Drücken Sie die Leertaste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 400%
            text = ['Wir sind jetzt kurz vor Beginn des Experiments.\n'...
                'Wenn Sie noch Fragen haben, wenden Sie sich jetzt an die Versuchleiterin. \n'...
                'Ansonsten möchten wir Sie nun noch an die wichtigsten Punkte erinnern.\n\n'...
                'Drücken Sie jeweils die Leertaste um fortzufahren.\n' ...
                ];
        elseif nInstruct == 44%short Instr. for following phases
            text = ['Es folgt nun der nächste Durchgang.\n'...
                'Wenn Sie noch Fragen haben, wenden Sie sich jetzt an die Versuchleiterin. \n'...
                '\n\n'...
                'Drücken Sie die Leertaste um zu starten.\n' ...
                ];
        elseif nInstruct == 401%third Instr. of the training phase.
            text = ['1. Blicken Sie immer auf die Fixationskreuze.\n'...
                ];
        elseif nInstruct == 402%third Instr. of the training phase.
            text = ['2. Bewerten Sie die Schmerzwahrnehmung immer wenn Sie danach gefragt werden.\n'...
                ];
        elseif nInstruct == 403%third Instr. of the training phase.
            text = ['3. Bewerten Sie die Linderung in jedem Durchgang (bei Erscheinen der Skala).\n'...
                ];
        elseif nInstruct == 404%third Instr. of the training phase.
            text = ['4. Eins der Gesichter wird mit der besseren TENS Frequenz gepaart.\n'...
                ];
        elseif nInstruct == 405%third Instr. of the training phase.
            text = ['5. Es ist allein Ihre Wahrnehmung gefragt, es gibt kein richtig oder falsch.\n'...
                ];
        elseif nInstruct == 406%third Instr. of the training phase.
            text = ['Drücken Sie jetzt die Leertaste, das Experiment startet dann in wenigen Sekunden.\n' ...
                ];
        elseif nInstruct == 20
            text = ['Demo beendet. Vielen Dank! \n'];
            
        elseif nInstruct == 21
            text = ['Durchgang beendet. Vielen Dank! \n'];
            
        elseif nInstruct == 8;%AskDetectionSelectable
            text = ['Sie sehen nun noch einmal eine Übersicht der verschiedenen Gesichter.\n'...
                'Bitte geben Sie an, welches der Gesichter Ihrer Meinung nach\n mit der optimalen TENS Behandlung gepaart wurde.\n\n'...
                'Nutzen Sie die linke und rechte Taste, um die Markierung\n zum richtigen Gesicht zu navigieren,\n'...
                'und drücken Sie die Leertaste zum Bestätigen.\n\n'...
                'Bitte zum Starten die Leertaste drücken.\n'...
                ];            
        elseif nInstruct == 801;%AskDetectionSelectable
            text = ['Sie sehen nun eine Übersicht der verschiedenen Gesichter.\n'...
                'Bitte schauen Sie sich die Gesichter aufmerksam an.\n'...
                'Bitte drücken Sie zum Start die Leertaste und\n' ...
                'fixieren Sie das anschließend erscheinende Fixationskreuz.\n'...
                ];
        elseif nInstruct == 9; % Rising Temp
            text = ['Temperatur wird angepasst... \n'];
        elseif nInstruct == 14
            text = ['Danke. Den aktiven Teil des Experiment haben Sie nun geschafft.\n'...
                'Es folgt nun noch eine strukturelle Messung, die ca. 7 Minuten dauert.\n'...
                'Sie können dabei ruhig die Augen schließen und sich entspannen.\n'];
        else
            text = {''};
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
    function [shuffled idx] = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [~, idx]        = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end
    function [cross_positions]=FixationCrossPool
        radius   = 290; %in px (around 14 degrees (37 px/deg))
        center   = [960 600];
        
        %setting up fixation cross pool vector of size
        % totaltrials x 4 (face_1_x face_1_y face_2_x face_2_y)
        cross_directions = round(rand(p.presentation.tTrial,1))*180;
        dummy            = cross_directions + rand(p.presentation.tTrial,1)*30-15;
        cross_positions  = [cosd(dummy(:,1))*radius+center(1) sind(dummy(:,1))*radius+center(2)];
        %         cross_positions  = [cosd(dummy(:,1))*radius+center(1) sind(dummy(:,1))*radius+center(2)...
        %             cosd(dummy(:,2))*radius+center(1) sind(dummy(:,2))*radius+center(2)];
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
    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end
    function [countedDown]=CountDown(secs, countedDown, countString)
        if secs>countedDown
            fprintf('%s', countString);
            countedDown=ceil(secs);
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
            %            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        commandwindow;
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        if arduino
            fclose(s);
        end
        diary off
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
        %         %Pulse Detection      :     0    info: NaN;
        %         %Tracker Onset        :     1
        %         %Cross (tonic) Onset  :     2    info: position
        %         %Cross (pain) Onset   :     3    info: position
        %         %Ramp down Onset      :     4    info: ror
        %         %Treatment Plateau    :     5    info: temp
        %         %Ramp back onset      :     6    info: ror;
        %         %Key Presses          :     7    info: NaN;
        %         %Tracker Offset       :     8    info: NaN;
        %         %Rate pain Onset		:     9    info: NaN;
        %         %Rate pain Offset     :     10   info: NaN;
        %         %Rate treat Onset     :     11   info: NaN;
        %         %Rate treat Offset    :     12   info: NaN;
        %         %Face Onset           :     13   info: stim_id;
        %         %Face Offset          :     14   info: stim_id;
        %         %FaceStim Fixcross    :     15   info: position
        %         %dummy fixflip        :     22   info: NaN;
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
end
