function [p]=exp_Immuno(subject, phase)

debug   = 0; %debug mode => 1: transparent window enabling viewing the background.
small_window = 0; % Open a small window only
NoEyelink = 0; %is Eyelink wanted?
test_sequences = 0; % Load shorter test sequences


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

    outp = @(x,y) 1;
end

if nargin ~= 2
    fprintf('Wrong number of inputs\n');
    return
end

commandwindow; %focus on the command window, so that output is not written on the editor



%clear everything
clear mex global functions;%clear all before we start.

if IsWindows%clear cogent if we are in Windows and rely on Cogent for outp.
    cgshut;
    global cogent;
end

%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);


el        = [];%eye-tracker variable
p         = [];%parameter structure that contains all info about the experiment.


SetParams;%set parameters of the experiment
SetPTB;%set visualization parameters.


%Time Storage
p.var.event_count         = 0;

%% Load stimulus sequence
if ~test_sequences
    sequences = load('stimulus_sequences.mat');
else
    sequences = load('short_stimulus_sequences_IBI10.mat');
end
sequences = sequences.sequences;
sequence = sequences{subject}{phase};

% Load reward file
reward_file = fullfile('reward/', sprintf('SUB_%i.mat'));
mkdir('reward');
if exist(reward_file)
    all_rewards = load(reward_file);
    all_rewards = all_rewards.all_rewards;
else
    all_rewards.money = 0;
    all_rewards.total_rewards = 0;
    all_rewards.eur_per_reward = 0.0145;
    save(reward_file, 'all_rewards');
end

%%

% The experiment has six phases:
% 1 - training day one
% 2 - fMRI day one
% 3 - training day two
% 4 - fMRI day two
% 5 - training day three
% 6 - fMRI day three

p.subject = subject;




%% Training
if mod(phase,2) == 1
    p.mrt.dummy_scan = 0 ; %for the training we don't want any pulses
    p.phase = phase;
    for block = 1:length(sequence)
        p.sequence = sequence{block};
        p.block = block;
        ExperimentBlock(p);
    end
%% fMRI
elseif mod(phase, 2) == 0
    % Vormessung
    p.phase = phase;
    k = 0;
    while ~(k == KbName(p.keys.el_calib));
        pause(0.1);
        fprintf('Experimenter!! press V key when the vormessung is finished.\n');
        [~, k] = KbStrokeWait(p.ptb.device);
        k = find(k);
    end
    fprintf('Continuing...\n');
    %%
    for b = 1:length(sequence)
        p.block = b;
        p.sequence = sequence{b};
        p = ExperimentBlock(p);
    end
    WaitSecs(2.5);

end

cleanup;


    function p = ExperimentBlock(p)

        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);

        %Enter the presentation loop and wait for the first pulse to
        %arrive.
        %wait for the dummy scans
        p = InitEyeLink(p);
        CalibrateEL;

        ismrt = mod(p.phase, 2)==0;
        if strcmp(p.sequence.type, 'EXP')
            ShowInstruction(2, 1, ~ismrt)
        elseif strcmp(p.sequence.type, 'QA')
            ShowInstruction(3, 1, ~ismrt)
        else
            ShowInstruction(4, 1, ~ismrt)
        end
        KbQueueCreate(p.ptb.device);%, p.ptb.keysOfInterest);%default device.
        KbQueueStart(p.ptb.device)
        KbQueueFlush(p.ptb.device)

        [secs, p] = WaitPulse(p, p.keys.pulse,p.mrt.dummy_scan);%will log it
        WaitSecs(.05);


        Eyelink('StartRecording');
        WaitSecs(0.01);

        Eyelink('Message', sprintf('SUBJECT %d', p.subject));
        Eyelink('Message', sprintf('PHASE %d', p.phase));
        Eyelink('Message', sprintf('BLOCK %d', p.block));

        TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.

        % Reward stuff
        earned_rewards = 0;
        rule = nan;
        for trial  = 1:size(p.sequence.stim, 2);
            %Get the variables that Trial function needs.
            stim_id      = p.sequence.stim(trial);
            RP           = p.sequence.reward_probability(trial);
            pRP          = p.sequence.pRP(trial);
            gv_a         = p.sequence.give_reward_rule_a(trial);
            gv_b         = p.sequence.give_reward_rule_b(trial);
            ISI          = p.sequence.isi(trial);
            jitter       = p.sequence.jitter(trial);
            OnsetTime     = TimeEndStim + ISI;
            keys = [p.keys.answer_a_train p.keys.answer_b_train];
            if pRP >  0.5
                correct_answer = keys(stim_id+1);
            elseif pRP == 0.5
                correct_answer = 'any';
            else
                correct_answer = keys((~stim_id)+1);
            end
            fprintf('%d of %d, STIM: %i,  RULE: %i, CRCTANSW: %s,  ISI: %2.2f, Block: %i ',...
                trial, size(p.sequence.stim, 2), stim_id, RP, correct_answer, ISI,  p.block);

            %Start with the trial, here is time-wise sensitive must be optimal
            [TimeEndStim, p, abort, reward, rule] = Trial(p, trial, OnsetTime, jitter, stim_id, RP, pRP, gv_a, gv_b, p.block, p.phase, rule, earned_rewards);
            earned_rewards = earned_rewards + reward;
            %fprintf('OffsetTime: %2.2f secs, Difference of %2.2f secs\n', TimeEndStim, TimeEndStim-OnsetTime);

            [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
            if numel(keycode)
                %log everything but "pulse keys" as pulses, not as keypresses.
                pulses = (keycode == KbName(p.keys.pulse));

                if any(~pulses);%log keys presses if only there is one
                    p = Log(p,secs(~pulses), 1000,keycode(~pulses), p.phase, p.block);
                end
                if any(pulses);%log pulses if only there is one
                    p = Log(p,secs(pulses), 0, keycode(pulses), p.phase, p.block);
                end
            end

            if abort
                %% Save Data
                p = save_data(p);
                %stop the queue
                KbQueueStop(p.ptb.device);
                KbQueueRelease(p.ptb.device);
                sca
                throw(MException('EXP:QUIT', ...
                        'User wants to quit'));
            end
        end
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        if mod(p.phase, 2) == 0
            WaitPulse(p, p.keys.pulse, p.mrt.dummy_scan);%
            fprintf('OK!! Stop the Scanner\n');
        else
            start = GetSecs();
            while GetSecs() < start+4
            end
        end
        %dump the final events
        [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
        %log everything but "pulse keys" as pulses, not as keypresses.
        pulses          = (keycode == KbName(p.keys.pulse));
        if any(~pulses);%log keys presses if only there is one
            p = Log(p,secs(~pulses), 1000,keycode(~pulses), p.phase, p.block);
        end
        if any(pulses);%log pulses if only there is one
            p = Log(p,secs(pulses), 0,keycode(pulses), p.phase, p.block);
        end

        money_earned = earned_rewards*all_rewards.eur_per_reward;
        all_rewards.money = all_rewards.money+money_earned;
        all_rewards.total_rewards = all_rewards.total_rewards + earned_rewards;

        text = RewardText(earned_rewards, earned_rewards/trial, money_earned, all_rewards.money);
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        start = GetSecs();
        p = save_data(p);
        while GetSecs() < start+10
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);

    end

    function [TimeFeedbackOffset, p, abort, give_reward, rule]=Trial(p, nTrial, TimeStimOnset, jitter, stim_id, RP, pRP, gv_a, gv_b, block, phase, prev_rule, earned_rewards)
        %% Run one trial
        rule = nan;
        abort = false;
        give_reward = nan;
        TimeFeedbackOffset = nan;
        StartEyelinkRecording(nTrial,p.phase, RP, stim_id, block, earned_rewards); %I would be cautious here, the first trial is never recorded in the EDF file, reason yet unknown.
        % Save trial info

        TrialStart = GetSecs;
        Eyelink('message', sprintf('ACTIVE_RULE %i', RP));
        Eyelink('message', sprintf('STIM_ID %i', stim_id));
        p = Log(p,TrialStart, 1, stim_id, phase, block);

        p = Log(p,TrialStart, 2, RP, phase, block);
        MarkCED( p.com.lpt.address, 100+RP);
        MarkCED( p.com.lpt.address, 110+stim_id);


        %% Fixation Onset
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];
        FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        FixCross_s   = [fix(1)-1,fix(2)-p.ptb.fc_size/2,fix(1)+1,fix(2)+p.ptb.fc_size/2;fix(1)-p.ptb.fc_size/2,fix(2)-1,fix(1)+p.ptb.fc_size/2,fix(2)+1];

        Screen('FillRect', p.ptb.w , p.stim.bg, [] ); %always create a gray background
        if (TimeStimOnset-TrialStart) > 4 % Give time for blinks.
            Screen('FillRect',  p.ptb.w, [0, 55, 200], FixCross');%draw the prestimus cross atop
            TimeBlinkOn  = Screen('Flip',p.ptb.w, TrialStart+2);      %<----- FLIP
            Screen('FillRect',  p.ptb.w, [255, 255, 255], FixCross');%draw the prestimus cross atop
            TimeCrossOn  = Screen('Flip',p.ptb.w, TimeBlinkOn+1);      %<----- FLIP
        else
            Screen('FillRect',  p.ptb.w, [255, 255, 255], FixCross');%draw the prestimus cross atop
            TimeCrossOn  = Screen('Flip',p.ptb.w);      %<----- FLIP
        end
        p = Log(p,TimeCrossOn, 3, nan, phase, block);
        Eyelink('Message', 'FIXON');
        MarkCED(p.com.lpt.address, 3);

        %% Draw the stimulus to the buffer
        angle = 90*stim_id;
        %Screen('DrawTexture', p.ptb.w, p.ptb.gabortex, [], [0, 0, p.ptb.rect(3) p.ptb.rect(4)], ...
        %        angle, [], [], [], [], kPsychDontDoRotation, [0, p.stim.sf, 150, 100, 1, 0, 0, 0]);
        df = p.ptb.rect(3) -  p.ptb.rect(4);
        rect = [df/2., 0, p.ptb.rect(4)+df/2, p.ptb.rect(4)];
        Screen('DrawTexture', p.ptb.w, p.ptb.gabortex, [], rect, ...
                angle, [], [], [], [], [], [0, p.stim.sf, 150, 100, 1, 0, 0, 0]);
        oc = [p.ptb.midpoint(1)-25, p.ptb.midpoint(2)-25, p.ptb.midpoint(1)+25, p.ptb.midpoint(2)+25];
        Screen('FillOval', p.ptb.w, p.stim.bg, oc);
        %draw also the fixation cross
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
        Screen('DrawingFinished',p.ptb.w,0);

        %% STIMULUS ONSET
        TimeStimOnset  = Screen('Flip',p.ptb.w, TimeStimOnset,0);  %<----- FLIP
        p = Log(p,TimeStimOnset, 4, nan, phase, block);
        Eyelink('Message', 'StimOnset');
        Eyelink('Message', 'SYNCTIME');
        MarkCED( p.com.lpt.address, 4);

        %% Check for key events
        [keycode, secs] = KbQueueDump;%this contains both the pulses and keypresses.
        if numel(keycode)
            %log pulses
            pulses = (keycode == KbName(p.keys.pulse));
            if any(pulses);%log pulses if only there is one
                p = Log(p,secs(pulses), 0, keycode(pulses), p.phase, p.block);
            end
        end
        KbQueueFlush(p.ptb.device);
        %% Stimulus Offset
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
        TimeStimOffset  = Screen('Flip', p.ptb.w, TimeStimOnset+0.5, 0);  %<----- FLIP

        p = Log(p,TimeStimOffset, 5, nan, phase, block);
        Eyelink('Message', 'StimOff');
        MarkCED( p.com.lpt.address, 5);

        %% Now wait for response!
        start = GetSecs;
        response = nan;
        correct = nan;
        RT = nan;
        while (GetSecs-start) < 10
            [keycodes, secs] = KbQueueDump;
            if numel(keycodes)
                for iii = 1:length(keycodes)
                    RT = secs(iii);
                    keys = KbName(keycodes(iii));
                    switch keys
                        case  p.keys.quit
                            abort = true;
                            return
                        case {p.keys.answer_a, p.keys.answer_a_train}
                            response = 0;
                            break
                        case {p.keys.answer_b, p.keys.answer_b_train}
                            response = 1;
                            break
                        case p.keys.pulse
                          p = Log(p,RT, 0, NaN, phase, block);
                    end
                end
                if ~isnan(response)
                    break
                end
            end
        end
        MarkCED(p.com.lpt.address, 70+response);
        Eyelink('message', sprintf('ANSWER %i', response));
        p = Log(p,RT, 6, response, phase, block);
        p = Log(p,RT, 7, RT-start, phase, block);

        %% Show feedback
        TimeFeedbackOnset = RT + jitter;
        % Was the answer correct?
        % If rule A then seq.reward_probability(trial) == 0 and:
        %   Rule rewards ANSWER_A and STIM_A and ANSWER_B and STIM_B
        correct = 0;
        if response == stim_id
            rule = 0;
            give_reward = gv_a;
        else
            rule = 1;
            give_reward = gv_b;
        end
        cod = 0;
        if ~isnan(prev_rule) && rule ~= prev_rule
            % Implements the changeover delay
            cod = 1;
            give_reward = give_reward/3;
        end

        if pRP > 0.5 && rule == 0
            correct = 1;
        elseif pRP <= 0.5 && rule == 1
            correct = 1;
        end

        fprintf(' RESPONSE: %i, RP: %i, %2.2f, GR: %1.2f, C:%f, COD=%i\n', response, RP, pRP, give_reward, correct, cod)
        p = Log(p,RT, 8, correct, phase, block);
        Eyelink('message', sprintf('CORRECT %i', correct));
        MarkCED( p.com.lpt.address, 120+correct);

        Screen('FillRect', p.ptb.w , p.stim.bg, []);
        if give_reward > 0
            if cod
                Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
                Screen('FillRect',  p.ptb.w, [0,200,0], FixCross_s');
            else
                Screen('FillRect',  p.ptb.w, [0,200,0], FixCross');
            end
        else
           Screen('FillRect',  p.ptb.w, [200,0,0], FixCross');
        end

        TimeFeedback  = Screen('Flip',p.ptb.w,TimeFeedbackOnset,0);      %<----- FLIP

        Eyelink('message', sprintf('FEEDBACK %i', give_reward));
        p = Log(p,TimeFeedback, 9, give_reward, phase, block);
        MarkCED( p.com.lpt.address, 130+give_reward);

        Screen('FillRect', p.ptb.w , p.stim.bg, []); %always create a gray background
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');%draw the prestimus cross atop
        TimeFeedbackOffset = Screen('Flip',p.ptb.w,TimeFeedback+0.4, 0);     %<----- FLIP

        Eyelink('message', 'FEEDBACKOFF');
        p = Log(p,TimeFeedbackOffset, 10, 0, phase, block);
        MarkCED( p.com.lpt.address, 140);

    end

    function SetParams
        %mrt business
        p.mrt.dummy_scan              = 0; %this will wait until the 6th image is acquired.
        p.mrt.LastScans               = 0; %number of scans after the offset of the last stimulus
        p.mrt.tr                      = 2; %in seconds.

        %will count the number of events to be logged
        p.var.event_count             = 0;


        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);

        if strcmp(p.hostname, 'larry.local')
            p.display.resolution = [2560 1600];
            p.display.dimension = [28, 17.5];
            p.display.distance = [62, 59];
            p.path.baselocation           = '/Users/nwilming/u/immuno/data/';
        elseif strcmp(p.hostname, 'donnerlab-Precision-T1700')
            p.display.resolution = [1920 1080];
            p.display.dimension = [52, 29.5];
            p.display.distance = [62, 59];
            p.path.baselocation           = '/home/donnerlab/experiments/immuno/data';
        else
            p.path.baselocation           = 'C:\Users\...\Documents\Experiments\immuno/data';
        end
        p.display.ppd = ppd(mean(p.display.distance), p.display.resolution(1),...
            p.display.dimension(1));

        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0
            mkdir(p.path.baselocation);
        end

        p.subject                       = subject; %subject id
        p.timestamp                     = datestr(now, 30); %the time_stamp of the current experiment.

        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        p.stim.bg                   = [128, 128, 128];
        p.stim.white                = get_color('white');
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;
        p.text.fixsize                 = 60;


        %% keys to be used during the experiment:
        %This part is highly specific for your system and recording setup,
        %please enter the correct key identifiers. You can get this information calling the
        %KbName function and replacing the code below for the key below.
        %1, 6 ==> Right
        %2, 7 ==> Left
        %3, 8 ==> Down
        %4, 9 ==> Up (confirm)
        %5    ==> Pulse from the scanner

        KbName('UnifyKeyNames');
        p.keys.confirm                 = '4$';%
        p.keys.answer_a                = '1!';
        p.keys.answer_a_train          = 'x';
        p.keys.answer_b                = '2@';
        p.keys.answer_b_train          = 'm';
        p.keys.pulse                   = '5%';
        p.keys.el_calib                = 'v';
        p.keys.el_valid                = 'c';
        p.keys.escape                  = 'ESCAPE';
        p.keys.enter                   = 'return';
        p.keys.quit                    = 'q';
        p.keylist = {p.keys.confirm, p.keys.answer_a, p.keys.answer_b,  p.keys.answer_a_train,...
            p.keys.answer_b_train, p.keys.pulse,...
            p.keys.el_calib, p.keys.el_valid, p.keys.enter};
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address = 888;%parallel port of the computer.

        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        p.out.log                     = zeros(1000000, 5).*NaN;%Experimental LOG.

        %%
        p.var.current_bg              = p.stim.bg;%current background to be used.
        %save(p.path.path_param,'p');
    end

    function text = RewardText(reward, reward_rate, earned_money, total_money)
        text = [sprintf('Im letzten Block haben Sie %d Belohnungen erhalten (%0.2f)\n', reward, reward_rate)...
            sprintf('Das entspricht %1.2f EUR!\n', earned_money)...
            sprintf('Insgesamt haben sich damit %1.2f EUR Bonus angesammelt!', total_money)];
    end

    function ShowInstruction(nInstruct,waitforkeypress, train, text)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, ==> subject presses a button to proceed
        %if waitforkeypress is <0, ==> text is shown for -waitforkeypress seconds.

        if nargin == 3
            [text]= GetText(nInstruct, train);
        end

        ShowText(text);
        if waitforkeypress==1 %and blank the screen as soon as the key is pressed
            KbStrokeWait(p.ptb.device);
        else
            WaitSecs(-waitforkeypress);
        end
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        t = Screen('Flip',p.ptb.w);

        function ShowText(text)
            Screen('FillRect',p.ptb.w,p.var.current_bg);
            DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');
            fprintf(text);
            fprintf('=========================================================\n');

        end
    end

    function [text]=GetText(nInstruct, train)
        if nInstruct == 1 %Retinotopy.
            text = ['Ihre naechste Aufgabe ist es auf Veraenderungen des\n' ...
                'Fixationskreuzes zu achten. Sollte der linke Arm des Kreuzes\n'...
                'verschwinden druecken sie die Linke Taste! Verschwindet der rechte\n'...
                'Arm druecken Sie die rechte Taste\n'...
                'Druecken Sie einen Knopf um weiter zu machen.\n'];


        elseif nInstruct == 2 %Task.
            text = ['Nun beginnt ein weitere Block des Experimentes.\n'...
                'Finden Sie herraus welche Regel gerade korrekt ist!\n'...
                'Zur Erinnerung:\n     Regel I -> ANSWERA: ||  ANSWERB: =\n'...
                '    Regel II -> ANSWERA: =  ANSWERB: ||\n'...
                'Druecken Sie einen Knopf um weiter zu machen.\n'];

        elseif nInstruct == 3 %Q Rule I.
            text = ['Im naechsten Block ist Regel I die richtige.\n'...
                'Zur Erinnerung:\n ANSWERA: ||\n  ANSWERB: = \n'...
                'Druecken Sie einen Knopf um weiter zu machen.\n'];

        elseif nInstruct == 4 %Q Rule B.
            text = ['Im naechsten Block ist Regel II die richtige.\n'...
                'Zur Erinnerung:\n ANSWERA: =\n  ANSWERB: ||\n'...
                'Druecken Sie einen Knopf um weiter zu machen.\n'];
        else
            text = {''};
        end
        if ~train
            text = strrep(text, 'ANSWERA', '1');
            text = strrep(text, 'ANSWERB', '2');
        else
            text = strrep(text, 'ANSWERA', 'x');
            text = strrep(text, 'ANSWERB', 'm');
        end
    end

    function SetPTB
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
        if strcmp(p.hostname, 'larry.local')
            p.ptb.screenNumber          =  min(screens);%the maximum is the second monitor
            p.ptb.device        = 1;
        elseif strcmp(p.hostname, 'donnerlab-Precision-T1700')
            p.ptb.screenNumber          =  0;
            p.ptb.device        = 6;
        else
            p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor
            p.ptb.device        = -1;
        end
        p.ptb.screenNumber
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %set the resolution correctly
        res = Screen('resolution', p.ptb.screenNumber);
        HideCursor(p.ptb.screenNumber);%make sure that the mouse is not shown at the participant's monitor
        %spit out the resolution,
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);

        %Open a graphics window using PTB
        if ~small_window
            [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, [0.5, 0.5, 0.5]);
        else
            [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, [128, 128, 128], [0, 0, 1000, 500]);
        end

        %Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg

        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);

        %find the mid position on the screen.
        x = p.ptb.rect(1) + (p.ptb.rect(3)/2);
        y = p.ptb.rect(2) + (p.ptb.rect(4)/2);

        p.ptb.midpoint              = [x, y] % p.ptb.width./2 p.ptb.height./2];
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2);
        %cross position for the eyetracker screen.
        p.ptb.fc_size               = 10;

        Priority(MaxPriority(p.ptb.w));


        if IsWindows
            LoadPsychHID;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.

        %get all the required keys in a vector
        p.ptb.keysOfInterest = [];
        for i = fields(p.keys)';
            p.ptb.keysOfInterest = [p.ptb.keysOfInterest KbName(p.keys.(i{1}))];
        end
        RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        KbQueueCreate(p.ptb.device);%, p.ptb.keysOfInterest);%default device.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %prepare parallel port communication. This relies on cogent i
        %think. We could do it with PTB as well.options
        if IsWindows
            config_io;
            outp(p.com.lpt.address,0);
            if( cogent.io.status ~= 0 )
                error('inp/outp installation failed');
            end
        end

        %% Build a procedural gabor texture for a gabor with a support of tw x th
        % pixels, and a RGB color offset of 0.5 -- a 50% gray.
        p.display.ppd
        p.stim.radius = p.ptb.rect(4)/2;
        p.stim.radius_deg = (p.ptb.rect(4)/2)/p.display.ppd;
        p.stim.sf = 2/p.display.ppd;
        fprintf('R and SF: %f %f', p.stim.radius, p.stim.sf)
        %p.ptb.gabortex = CreateProceduralGabor(p.ptb.w, p.ptb.width, p.ptb.height, 0, [0.5 0.5 0.5 0.0]);
        p.ptb.gabortex = CreateProceduralSineGrating(p.ptb.w, 2*p.stim.radius, 2*p.stim.radius,...
            [], p.stim.radius);

        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Make final reminders to the experimenter to avoid false starts,
        %which are annoying. Here I specifically send test pulses to the
        %physio computer and check if everything OK.
        k = 0;
%         while ~(k == p.keys.el_calib);%press V to continue
%             pause(0.1);
%             outp(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
%             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%             fprintf('1/ Red cable has to be connected to the Cogent BOX\n');
%             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%             fprintf('2/ D2 Connection not to forget on the LPT panel\n');
%             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%             fprintf('3/ Switch the SCR cable\n');
%             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%             fprintf('4/ Button box has to be on\n');
%             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
%             fprintf('5/ Did the trigger test work?\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\n\nPress V(alidate) to continue experiment or C to continue sending test pulses...\n')
%             [~, k] = KbStrokeWait(p.ptb.device);
%             k = find(k);
%         end

    fprintf('Continuing...\n');



    end

    function [t]=StartEyelinkRecording(nTrial, phase, rp, stim, block_id, sumrw)
        if ~NoEyelink
            t = [];
            Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, RP: %04d, STIM: %04d, BLOCK %04d', nTrial, phase, rp, stim, block_id);
            Eyelink('Command', sprintf('record_status_message "Trial: %i, REW: %2.2f"', nTrial, sumrw));
            t = GetSecs;
        else
            t = GetSecs;
        end
    end

    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end

    function p=InitEyeLink(p)
        %
        if EyelinkInit(NoEyelink)%use 0 to init normaly
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
        el.drift_correction_targetp.ptb.wid_beep = [0 0 0];
        el.calibration_failed_beep      = [0 0 0];
        el.calibration_success_beep     = [0 0 0];
        el.drift_correction_failed_beep = [0 0 0];
        el.drift_correction_success_beep= [0 0 0];
        EyelinkUpdateDefaults(el);
        PsychEyelinkDispatchCallback(el);

        % open file.
        p.edffile = sprintf('%d%d%d.edf', p.subject, p.phase, p.block);
        res = Eyelink('Openfile', p.edffile);

        %Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearAmy Experiment (Selim Onat)''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);

        pw = p.display.dimension(1);
        ph = p.display.dimension(2);
        phys_coord = sprintf('screen_phys_coords = %ld, %ld, %ld, %ld'...
            , -floor(10*pw/2)... %half width
            ,  floor(10*ph/2)... %half height
            ,  floor(10*pw/2)... %half width
            , -floor(10*ph/2));   %half height %rv 2
        Eyelink('command', phys_coord);

        Eyelink('command', 'screen_distance = %ld %ld', ...
            10*p.display.distance(2), 10*p.display.distance(2)); %rv 3
        
        % set calibration type.
        Eyelink('command','auto_calibration_messages = YES');
        Eyelink('command', 'enable_automatic_calibration = YES');
        Eyelink('command', 'calibration_type = HV5');
        Eyelink('command', 'generate_default_targets = NO');
        pw = p.ptb.width;
        ph = p.ptb.height;
        targets = sprintf('calibration_targets = %i,%i %i,%i %i,%i %i,%i %i,%i',...
            pw/2, ph/2,...
            pw/2 -200, ph/2,...
            pw/2 +200, ph/2,...
            pw/2, ph/2-200,...
            pw/2, ph/2+200);
        vtargets = sprintf('validation_targets = %i,%i %i,%i %i,%i %i,%i %i,%i',...
            pw/2, ph/2,...
            pw/2-200, ph/2,...
            pw/2+200, ph/2,...
            pw/2, ph/2-200,...
            pw/2, ph/2+200);
        Eyelink('command', targets);
        Eyelink('command', vtargets);

        
        Eyelink('command', 'select_parser_configuration = 1');
        %what do we want to record
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'use_ellipse_fitter = no');
        % set sample rate in camera setup screen
        Eyelink('command', 'sample_rate = %d',1000);

    end

    function StopEyelink(filename, path_edf)
        if ~NoEyelink
            try
                fprintf('Trying to stop the Eyelink system with StopEyelink\n');
                Eyelink('StopRecording');
                WaitSecs(0.5);
                Eyelink('Closefile');
                display('receiving the EDF file...');
                Eyelink('ReceiveFile', filename, path_edf);
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
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p.var.ExpPhase  = 0;
        EyelinkDoTrackerSetup(el);
        %Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s', messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')

    end

    function p = Log(p, ptb_time, event_type, event_info, phase, block)
        %Phases:
        % 1 - training day one
        % 2 - fMRI day one
        % 3 - training day two
        % 4 - fMRI day two
        % 5 - training day three
        % 6 - fMRI day three

        % Blocks:
        % 0 - Instruction
        % 1 - Retinotopic mapping
        % 2 - Experiment
        % 3 - Quadrant mapping

        %event types are as follows:
        %
        % Pulse Detection      :     0    info: NaN;
        % Stimulus ID          :     1    info: stim_id         Log(TrialStart, 1, stim_id);
        % Reward Probability   :     2    info: RP              Log(TrialStart, 2, RP);
        % Fix Cross On         :     3    info: nan             Log(TimeCrossOn, 3, nan)
        % Stimulus On          :     4    info: nan             Log(TimeStimOnset, 4, nan);
        % Stimulus Off         :     5    info: nan             Log(TimeStimOffset, 5, nan);
        % Response             :     6    info: response        Log(RT, 5, response);
        % Response time        :     7    info: respones time   Log(RT, 6, RT-start);
        % Stim correct         :     8    info: correct         Log(RT, 7, correct);
        % Feedback             :     9    info: give_reward     Log(TimeFeedback, 8, give_reward);
        % Trial end            :    10    info: nan             Log(TimeFeedbackOffset, 9, 0);

        for iii = 1:length(ptb_time)
            p.var.event_count                = p.var.event_count + 1;
            p.out.log(p.var.event_count,:)   = [ptb_time(iii) event_type event_info(iii) phase block];
            %fprintf('LOG: %2.2f, %i, %i, %i, %i \n', p.out.log(p.var.event_count, :))
        end

    end

    function [secs, p]=WaitPulse(p, keycode,n)
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
                p = Log(p, dummy,0,NaN,0,0);
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
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet(p.ptb.device);
            n          = n + 1;
            keycode(n) = evt.Keycode;
            pressed(n) = evt.Pressed;
            secs(n)    = evt.Time;
        end
        i           = pressed == 1;
        keycode(~i) = [];
        secs(~i)    = [];

    end

    function [keyIsDown firstPress] = check_kbqueues(devices)
        firstPress = boolean(zeros(1, 256));
        keyIsDown = false;
        for device = devices
            [kD, fP] = PsychHID('KbQueueCheck', device);
            keyIsDown = keyIsDown | kD;
            firstPress = firstPress | boolean(fP);
        end
    end

    function p = save_data(p)
        path = fullfile(p.path.baselocation, sprintf('SUB_%i', p.subject), sprintf('PH_%d', p.phase, p.block)); %subject folder, first we save it to the temp folder.
        if ~exist(path)
            mkdir(path)
        end

        path_edf = fullfile(path, sprintf('S%d_P%d_B%d.edf', p.subject, p.phase, p.block));
        path_data = fullfile(path, sprintf('S%d_P%d_B%d_data.mat', p.subject, p.phase, p.block));

        %get the eyelink file back to this computer
        StopEyelink(p.edffile, path_edf);
        %trim the log file and save
        p.out.log = p.out.log(1:p.var.event_count,:);
        %shift the time so that the first timestamp is equal to zero
        p.out.log(:,1) = p.out.log(:,1) - p.out.log(1);
        p.out.log      = p.out.log;%copy it to the output variable.
        save(path_data, 'p');
        % Reset Log
        p.out.log      = zeros(1000000, 5).*NaN;%Experimental LOG.
    end

    function ppd = ppd(distance, x_px, width)
        o = tan(0.5*pi/180) * distance;
        ppd = 2 * o*x_px/width;
    end

end
