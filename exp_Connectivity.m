function [p]=exp_Connectivity(subject, phase, target_block, experiment)

if nargin == 3
    experiment = 'connectivity';
elseif ~ (strcmp(experiment, 'connectivity') || strcmp(experiment, 'immuno'))
    ME = MException('VerifyInput:ExperimentType', ...
        'experiment string must be connecvivity or immuno');
    throw(ME);
end
    

NoEyelink = 1; %is Eyelink wanted?
debug   = 0; %debug mode => 1: transparent window enabling viewing the background.
small_window = 1; % Open a small window only

%% >>>>> Set up a lot of stuff
% Load stimulus sequence
if strcmp(experiment, 'connectivity')
    if ~test_sequences
        sequences = load('connectivity_sequences.mat');
    else
        sequences = load('short_stimulus_sequences.mat');
    end
elseif strcmp(experiment, 'immuno')
    sequences = load('immuno_sequences.mat');
end
sequences = sequences.sequences;
sequence = sequences{subject}{phase};

fmri = sequence{1}.fmri; % if false skip waiting for pulses.

%replace parallel port function with a dummy function
if ~IsWindows
    outp = @(x,y) 1;
end

commandwindow; %focus on the command window, so that output is not written on the editor
%clear everything
clear mex global functions;%clear all before we start.

if IsWindows	%clear cogent if we are in Windows and rely on Cogent for outp.
    cgshut;
    global cogent; %#ok<TLEV>
end
GetSecs;
WaitSecs(0.001);

el        = [];%eye-tracker variable
p         = [];%parameter structure that contains all info about the experiment.

SetParams;%set parameters of the experiment
SetPTB;%set visualization parameters.

if ~fmri
    p.mrt.dummy_scan = 0;
end

if subject == -100 % <---- Do sample retino measurements.
    p = make_sample_textures(p);
    KbQueueStop(p.ptb.device);
    KbQueueRelease(p.ptb.device);
    p.phase = -100;
    p.block = -100;
    p = InitEyeLink(p);
    CalibrateEL;
    KbQueueCreate(p.ptb.device);
    KbQueueStart(p.ptb.device);
    KbQueueFlush(p.ptb.device);
    [p, abort] = MeasureSamplePupilResponses(p);
    StopEyelink(p.edffile, 'sample_test.edf')
    cleanup;
    return
end


%Time Storage
p.var.event_count         = 0;
p.possible_reward = 0;
p.earned_rewards  = 0;

% Load reward file
path_reward = fullfile(p.path.baselocation, sprintf('SUB_%i', p.subject));
if ~exist(path_reward) %#ok<EXIST>
    mkdir(path_reward)
end
reward_file = fullfile(path_reward,'rewards_latest.mat');

if strcmp(experiment, 'connectivity')    
    eur_per_reward = 0.07;
elseif strcmp(experiment, 'immuno')
    p = make_sample_textures(p);
    eur_per_reward = 0.017;
end

if exist(reward_file) %#ok<EXIST>
    all_rewards = load(reward_file);
    all_rewards = all_rewards.all_rewards;
    all_rewards.eur_per_reward = eur_per_reward;
    all_rewards.weight = 1;
else
    all_rewards.money = 0;
    all_rewards.total_rewards = 0;
    all_rewards.eur_per_reward = eur_per_reward;
    all_rewards.weight = 1;
    save(reward_file, 'all_rewards');
end

p.subject = subject;


% Vormessung
p.phase = phase;
ii = 0;

%while ~(k == KbName(p.keys.el_calib));
%    pause(0.1);
%    fprintf('Experimenter!! press V key when the vormessung is finished.\n');
%    [~, k] = KbStrokeWait(p.ptb.device);
%    k = find(k);
%end


if (numel(target_block) == 0) || (target_block == -1) 
    target_block = 1:length(sequence);
end

blocks_completed = 0;
ir_blocks_completed = 0;
gl_blocks_completed = 0;

calibrated = false;

Screen('TextSize', p.ptb.w,  20);
Screen('TextFont', p.ptb.w, 'Courier');
Screen('TextStyle', p.ptb.w, 1);

%% >>>>>>> Experiment starts.
%try
    for block = target_block
        fprintf('Running SUB=%i, PHASE=%i, BLOCK=%i\n', subject, phase, block);
        p.block = block;    
        p.sequence = sequence{block};


        if strcmp('IR', p.sequence.block_type)
            all_rewards.weight = 0.7;
            if blocks_completed > 0
                p = TakeABreak(p);
            end
            if ir_blocks_completed == 0
                explain_instructed_rule(p);
            end
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            p = InitEyeLink(p);
            CalibrateEL;
            [p, abort] = InstructedRuleBlock(p);
            ir_blocks_completed = ir_blocks_completed+1;


        elseif strcmp('GL', p.sequence.block_type)
            all_rewards.weight = 1;
            if blocks_completed > 0
                p = TakeABreak(p);
            end
            if gl_blocks_completed == 0
                explain_glaze_rule(p);
            end
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            p = InitEyeLink(p);
            CalibrateEL;
            [p, abort] = GlazeBlock(p);
            gl_blocks_completed = gl_blocks_completed+1;


        elseif strcmp('RW', p.sequence.block_type)
            all_rewards.weight = 0.0;
            if blocks_completed == 0
                explain_retino_block(p)
            end
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            p = InitEyeLink(p);
            if block == 1 || ~calibrated
                CalibrateEL;
                calibrated = true;
            end
            [p, abort] = RetinoBlock(p, 0.8, 5, 5.5, false, 1, 'wedge');
            p = InitEyeLink(p);
            [p, abort] = RetinoBlock(p, 0.8, 5, 5.5, true, 1, 'wedge');


        elseif strcmp('RR', p.sequence.block_type)
            all_rewards.weight = 0.0;
            if blocks_completed == 0
                explain_retino_block(p)
            end
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            p = InitEyeLink(p);
            if block == 1 || ~calibrated
                CalibrateEL;
                calibrated = true;
            end        
            [p, abort] = RetinoBlock(p, 0.8, 5, 5.5, false, 1, 'ring');
            p = InitEyeLink(p);
            [p, abort] = RetinoBlock(p, 0.8, 5, 5.5, true, 1, 'ring');


        elseif strcmp('NR', p.sequence.block_type)        
            % A block of the Nassar prediction task.
            all_rewards.weight = 0.6;
            if blocks_completed == 0
                %explain_nassar_block(p)
            end
            KbQueueStop(p.ptb.device);
            KbQueueRelease(p.ptb.device);
            p = InitEyeLink(p);
            if block == 1 || ~calibrated
                CalibrateEL;
                calibrated = true;
            end        
            [p, abort] = NassarPredictionBlock(p);        
        end

        blocks_completed = blocks_completed+1;
        if abort
            cleanup
            return
        end
    end
%end

%WaitSecs(2.5);
cleanup;
lasterr

    %% ----------------------------------- 
    %  Experiment blocks
    %  -----------------------------------
    
    function [p, abort] = InstructedRuleBlock(p)
        p.start_time = datestr(now, 'dd-mmm-yy-HH:MM:SS');             

        Screen('FillRect',p.ptb.w,p.var.current_bg);
        Screen('Flip',p.ptb.w);
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
        
        [secs, p] = WaitPulse(p, p.keys.pulse, p.mrt.dummy_scan);%will log it
        
        KbQueueCreate(p.ptb.device);%, p.ptb.keysOfInterest);%default device.
        KbQueueStart(p.ptb.device);
        KbQueueFlush(p.ptb.device);
        
        Eyelink('StartRecording');
        WaitSecs(0.01);
        Eyelink('Message', sprintf('SUBJECT %d', p.subject));
        p = Log(p, GetSecs, 'START_IR', nan, p.phase, p.block);
        p = Log(p, GetSecs, 'SUBJECT', p.subject, p.phase, p.block);
        Eyelink('Message', sprintf('PHASE %d', p.phase));
        Eyelink('Message', sprintf('BLOCK %d', p.block));
        
        TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        
        % Reward stuff
        draw_fix(p);
        p.prev_sample=0;
        for trial  = 1:size(p.sequence.stim, 2);
            %Get the variables that Trial function needs.
            stim_id       = p.sequence.stim(trial);
            ISI           = p.sequence.isi(trial);
            jitter        = p.sequence.jitter(trial);
            validity      = p.sequence.validity(trial);
            rewarded_rule = p.sequence.rewarded_rule(trial);
            OnsetTime     = TimeEndStim + ISI;
            block_change  = p.sequence.onset(trial);
            
            if block_change
                show_block(p, validity, 2);
                OnsetTime = GetSecs + ISI + 4;
            end
            
            
            fprintf('%d of %d, STIM: %i,  VALIDITY: %0.2f,  ISI: %2.2f, Block: %i REWARDED_RULE: %i,',...
                trial, size(p.sequence.stim, 2), stim_id, validity, ISI,  p.block, rewarded_rule);
            
            StartEyelinkRecording(trial, p.phase, validity, stim_id, p.block, rewarded_rule);
            [p, TimeEndStim, abort, reward] = InstructedRuleTrial(phase, p.block, p, OnsetTime, stim_id, rewarded_rule, jitter);
            
            fprintf(' REWARD: %i, TOTAL: %i\n',reward, p.earned_rewards);
            p = dump_keys(p);
            
            if abort
                break
            end
        end
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        WaitPulse(p, p.keys.pulse, p.mrt.dummy_scan);%
        fprintf('OK!! Stop the Scanner\n');

        
        p = dump_keys(p);
        
        money_earned = p.earned_rewards*all_rewards.eur_per_reward*all_rewards.weight;
        all_rewards.money = all_rewards.money+money_earned;
        all_rewards.total_rewards = all_rewards.total_rewards + p.earned_rewards;
        
        text = RewardText(p.earned_rewards, p.earned_rewards/trial, money_earned, all_rewards.money);
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        start = GetSecs();
        p = save_data(p, all_rewards);
        while GetSecs() < start+5
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
    end


    function [p, abort] = GlazeBlock(p)
        abort=false;
        p.start_time = datestr(now, 'dd-mmm-yy-HH:MM:SS');
        %wait for the dummy scans

        Screen('FillRect',p.ptb.w,p.var.current_bg);
        Screen('Flip',p.ptb.w);
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
        show_glaze_block(p, 0); % <-- Show glaze block
        [secs, p] = WaitPulse(p, p.keys.pulse,p.mrt.dummy_scan);

        Screen('Flip', p.ptb.w);
        KbQueueCreate(p.ptb.device);
        KbQueueStart(p.ptb.device);
        KbQueueFlush(p.ptb.device);
        
        Eyelink('StartRecording');
        WaitSecs(.01);
        Eyelink('Message', sprintf('SUBJECT %d', p.subject));
        p = Log(p, GetSecs, 'START_GLAZE', nan, p.phase, p.block);
        p = Log(p, GetSecs, 'SUBJECT', p.subject, p.phase, p.block);
        Eyelink('Message', sprintf('PHASE %d', p.phase));
        Eyelink('Message', sprintf('BLOCK %d', p.block));
        
        TimeEndStim     = secs(end)- p.ptb.slack;
        WaitSecs(1);
        % Reward stuff
        draw_fix(p);
        p.prev_sample=0;
        ISI = .25;
        StartGlazeEyelinkRecording(p.block, p.phase);
        outcomes = [];
        for trial  = 1:size(p.sequence.stim, 2);
            
            %Get the variables that Trial function needs.
            stim_id       = p.sequence.stim(trial);            
            type          = p.sequence.type(trial);
            location      = p.sequence.sample(trial);
            gener_side    = p.sequence.generating_side(trial);
            OnsetTime     = TimeEndStim + ISI;
            
            if location < 0
                fprintf('-');
            else
                fprintf('+');
            end
            Eyelink('Command', 'record_status_message "Trial: %i/%i"', trial, size(p.sequence.stim, 2));
            Eyelink('Message', 'trial_id %i', trial);
            if ~isnan(stim_id)
                Eyelink('Message', 'stim_id %i', stim_id);
            end
            if ~isnan(gener_side)
                Eyelink('Message', 'gener_side %i', round(100*gener_side));
            end
            if ~isnan(location)
                Eyelink('Message', 'location %d', round(1000*location));
            end
            Eyelink('Message', 'type %i', type);
            
            if type == 0
                % Show a single sample
                [TimeEndStim, p] = show_one_sample(p, OnsetTime, location);
            elseif type == 1
                % Choice trial.
                fprintf('\nCHOICE TRIAL; stim_id:%i, gener_side:%02.2f ', stim_id, gener_side>0);
                [p, ~, response, rule, abort] = choice_trial(p, OnsetTime, stim_id, p.phase, p.block);
                fprintf(' RULE: %i ', rule)
                if rule == (gener_side>0)
                    outcomes = [outcomes 1]; %#ok<AGROW>
                    fprintf('REWARD!\n');
                else
                    outcomes = [outcomes 0]; %#ok<AGROW>
                    fprintf('NO REWARD!\n')
                end
                
            end
            p = dump_keys(p);
            
            if abort
                break
            end
            
            ISI           = p.sequence.isi(trial);
            
        end
        
        %wait 6 seconds for the BOLD signal to come back to the baseline...
        
        WaitPulse(p, p.keys.pulse, p.mrt.dummy_scan);%
        fprintf('OK!! Stop the Scanner\n');            
        
        p = dump_keys(p);
        
        % Need to show feedback here!
        p.earned_rewards = sum(outcomes);
        %money_earned = p.earned_rewards*all_rewards.eur_per_reward;
        money_earned = sum(outcomes)*all_rewards.eur_per_reward*all_rewards.weight;
        all_rewards.money = all_rewards.money+money_earned;
        all_rewards.total_rewards = all_rewards.total_rewards + p.earned_rewards;
        
        text = RewardText(p.earned_rewards, p.earned_rewards/trial, money_earned, all_rewards.money);
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        start = GetSecs();
        p = save_data(p, all_rewards);
        while GetSecs() < start+5
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
    end


    function [p, abort] = RetinoBlock(p, TR, nrep, IBI, reverse, wait_triggers, type)
        %
        % TR = repetition time
        % nrep = how often to repeat the stimulus
        % IBI 
        rule = binornd(1, 0.5);
        abort = false;
        p.start_time = datestr(now, 'dd-mmm-yy-HH:MM:SS');
        block_info = sprintf('NREP=%i, REVERSE=%i, TYPE=%s, RULE=%i', nrep, reverse, type, rule);
        p = Log(p, GetSecs, 'RETINO_START', block_info, p.phase, p.block);
        p = Log(p, GetSecs, 'SUBJECT', p.subject, p.phase, p.block);
        %IBI is inter change time for task in seconds
        % Prepare stimuli
        if strcmp(type, 'wedge')
            stimulus = load('retino_sequence.mat');
        else
            stimulus = load('retino_ring_sequence.mat');
        end
        stimulus = stimulus.stimulus;
        % Construct stimulus sequence
        ret_sequence = struct();
        ret_sequence.seq = [];
        ret_sequence.seqtiming = 0;
        isi = mean(diff(stimulus.seqtiming));   % sample diff in seconds
        for n = 1:nrep
            if reverse
                ret_sequence.seq = [ret_sequence.seq; flip(stimulus.seq)];
            else
                ret_sequence.seq = [ret_sequence.seq; stimulus.seq];
            end
            ret_sequence.seqtiming = [ret_sequence.seqtiming; stimulus.seqtiming + ret_sequence.seqtiming(end) + isi];
        end
        ret_sequence.seqtiming = ret_sequence.seqtiming(2:end);                
        images = nan*ones(size(stimulus.images{1}, 3), 1);
        for i = 1:length(images)
            images(i) = Screen('MakeTexture', p.ptb.w, stimulus.images{1}(:,:,i));
        end        
        w = size(stimulus.images{1},1)/2;
        h = size(stimulus.images{1},2)/2;
        stimulus = ret_sequence;
        [X,Y] = meshgrid(-w:w-1, -h:h-1);
        Z = ((X.^2+Y.^2).^.5)/p.display.ppd;
        mask = ones(2*w, 2*h, 2)*128;
        mask(:, :, 2) = (1-double((0.58<Z) & (Z<12)))*255;
        %invmask = Screen('MakeTexture', p.ptb.w, 255-mask);
        mask = Screen('MakeTexture', p.ptb.w, mask);       
        rect = [p.ptb.CrossPosition_x-w, p.ptb.CrossPosition_y-h, p.ptb.CrossPosition_x+w, p.ptb.CrossPosition_y+h];
        
        Eyelink('StartRecording');
        WaitSecs(0.01);
        Eyelink('Message', sprintf('SUBJECT %d', p.subject));
        Eyelink('Message', sprintf('PHASE %d', p.phase));
        Eyelink('Message', sprintf('BLOCK %d', p.block));
        Eyelink('Message', sprintf('Start_retino T=%s RV=%i RU=%i', type, reverse, rule));
        % Prepare Task        
        onsets = exprnd(IBI, 1000, 1);
        onsets = onsets((onsets>2) & (onsets < (2*IBI)));
        onsets = cumsum(onsets);        
        arrows = binornd(1, 0.5, length(onsets), 1);  
        KbQueueStop(p.ptb.device);
                
        p = dump_keys(p);
        
        show_block(p, -1, 10);
        
        % Break
        % Wait for trigger        
        Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        [secs, p] = WaitPulse(p, p.keys.pulse, wait_triggers);%will log it
        
        KbQueueRelease(p.ptb.device);        
        KbQueueCreate(p.ptb.device);
        KbQueueStart(p.ptb.device)
        KbQueueFlush(p.ptb.device)
        start = secs(end);
        StarRetinoEyelinkRecording(type, reverse);
        Screen('DrawTexture', p.ptb.w, images(1), [], rect)
        Screen('DrawTexture', p.ptb.w, mask, [], rect)
        start  = Screen('Flip',p.ptb.w, start+TR, 0);  %<----- FLIP
        Eyelink('message', 'first_flip');
        onsets = onsets+start;
        cnt = 1;
        first = true;
        vbl=0;
        %ay = p.FixCross(1, 2) - (p.FixCross(1, 2) - p.FixCross(1, 4))/2;
        %ax = p.FixCross(2, 1);
        p.FixCross(4)        
        last_stim_id = nan;
        last_response = nan;        
        for i = 2:length(stimulus.seq)
            onset = stimulus.seqtiming(i);
            image = images(stimulus.seq(i));
            Screen('DrawTexture', p.ptb.w, image, [], rect)
            Screen('DrawTexture', p.ptb.w, mask, [], rect)            
            if ~isnan(last_stim_id)
                % Still waiting for a response
                [p, abort, resp_rule] = handle_retino_response(p, last_stim_id);
                if isnan(resp_rule)
                    fix_color = [255, 255, 255];
                elseif rule==resp_rule
                    fix_color =  [0, 200, 0];
                    last_stim_id = nan;
                    last_response = GetSecs;
                else
                    fix_color = [200, 0, 0];
                    last_stim_id = nan;
                    last_response = GetSecs;
                end
            end      
            if (GetSecs-last_response)<0.5
                draw_fix(p, fix_color, rule);
            else
                draw_fix(p, [], rule);
                last_response = nan;
            end
            
            if vbl > onsets(cnt)   
                if first                               
                     p = dump_keys(p);
                     p = Log(p, GetSecs, 'RETINO_GRATIN_ONSET', arrows(cnt), p.phase, p.block);
                     first = false;
                end
                % Prompt for a choice!
                Screen('BlendFunction', p.ptb.w, 'GL_ONE', 'GL_ZERO');
                draw_very_small_stimulus(p, arrows(cnt))
                Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');                                
                last_stim_id = arrows(cnt);
                if vbl > (onsets(cnt)+0.5)
                    cnt = cnt+1;
                    first = true;
                end
            end
            
            vbl  = Screen('Flip',p.ptb.w, start+onset, 0);  %<----- FLIP
            p = Log(p, vbl, 'RETINO_SEQ_CNT', i, p.phase, p.block);
            if(abort)
                return
            end
            if binornd(1, 1/450)
                rule = ~rule;
            end
                
        end        
        Screen('BlendFunction', p.ptb.w, 'GL_ONE', 'GL_ZERO');
        draw_fix(p, [], rule);
        Screen('Flip',p.ptb.w, start+onset, 0);
        p = save_data(p, all_rewards);
    end


    function [p, abort] = NassarPredictionBlock(p)
        p.start_time = datestr(now, 'dd-mmm-yy-HH:MM:SS'); 
        [oldFontName,~,oldTextStyle] = Screen('TextFont', p.ptb.w, 'Courier');
        oldTextSize=Screen('TextSize', p.ptb.w,  70);
        abort = nan;
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        
        
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        t = Screen('Flip',p.ptb.w);
        

        KbQueueCreate(p.ptb.device);%, p.ptb.keysOfInterest);%default device.
        KbQueueStart(p.ptb.device)
        KbQueueFlush(p.ptb.device)


        Eyelink('StartRecording');
        WaitSecs(0.01);

        Eyelink('Message', sprintf('SUBJECT %d', p.subject));
        Eyelink('Message', sprintf('PHASE %d', p.phase));
        Eyelink('Message', sprintf('BLOCK %d', p.block));

        TimeEndStim     = GetSecs();
        

        % Reward stuff
        draw_prd_background(p);
        p.prev_sample=0;
        p.earned_rewards = 0;
        p.possible_reward = 0;
        prediction = p.sequence.sample(1);
        last_sample = p.sequence.sample(1);
        
        lower_bound = mean(abs(diff(p.sequence.sample)));
        upper_bound = mean(abs(p.sequence.sample(2:end) - p.sequence.mu(1:end-1)));
        prediction_errors = nan(size(p.sequence.stim,2));
        
        Log(p, vbl, 'PRD_LOWER_BOUND', lower_bound, p.phase, p.block);
        Log(p, vbl, 'PRD_UPPER_BOUND', upper_bound, p.phase, p.block);
        
        for trial  = 1:size(p.sequence.stim, 2);
            Log(p, vbl, 'PRD_TRIAL', trial, p.phase, p.block);
            %Get the variables that Trial function needs.
            stim_id         = p.sequence.stim(trial);
            ISI             = p.sequence.isi(trial);
            jitter          = p.sequence.jitter(trial);
            sample          = p.sequence.sample(trial);
            OnsetTime       = TimeEndStim + ISI;
            sample_duration = p.sequence.sample_duration(trial);                        

            
            fprintf('%d of %d, SAMPLE: %i, Block: %i \n',...
                trial, size(p.sequence.stim, 2), round(sample), p.block);

            StartEyelinkRecording(trial, p.phase, 0, 0, 0, 0); 
            %type, p, TimeStimOnset, stim_id, sample, jitter
            [TimeEndStim, p, abort, prediction] = PredictionTrial(p, OnsetTime, sample, sample_duration, jitter, prediction, last_sample);          
            last_sample = sample;
            
            prediction_errors(trial) = abs(prediction-sample);
            Log(p, vbl, 'PRD_ERROR', prediction_errors(trial), p.phase, p.block);
            
            [keycode, secs] = KbQueueDump(p); %this contains both the pulses and keypresses.
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
                p = save_data(p, all_rewards);
                %stop the queue
                KbQueueStop(p.ptb.device);
                KbQueueRelease(p.ptb.device);
                sca
                return
            end
        end
        
        mean_prediction_error = nanmean(prediction_errors(:));
        fprintf('Mean prediction error: %2.1f\n', mean_prediction_error);
        fprintf('Lower bound: %3.2f, upper bound: %3.2f', lower_bound, upper_bound);
        payout_weight = 1/4;
        if (lower_bound < mean_prediction_error) &&...
                (mean_prediction_error < ((2*lower_bound/3) + (upper_bound/3)))
            payout_weight = 2/4;
        elseif (((2*lower_bound/3) + (upper_bound/3)) < mean_prediction_error) &&...
                (mean_prediction_error < (lower_bound+upper_bound)/2)
            payout_weight = 3/4;
        elseif mean_prediction_error < (lower_bound+upper_bound)/2
            payout_weight = 1;
        end
             
        %money_earned = p.earned_rewards*all_rewards.eur_per_reward;
        money_earned = trial*all_rewards.eur_per_reward*all_rewards.weight*payout_weight;
        all_rewards.money = all_rewards.money+money_earned;
        all_rewards.total_rewards = all_rewards.total_rewards + p.earned_rewards;              

        %wait 6 seconds for the pupil signal to come back to the baseline...
        start = GetSecs();
        while GetSecs() < start+6
        end

        
        [keycode, secs] = KbQueueDump(p);%this contains both the pulses and keypresses.        
        pulses          = (keycode == KbName(p.keys.pulse));
        if any(~pulses);%log keys presses if only there is one
            p = Log(p,secs(~pulses), 1000,keycode(~pulses), p.phase, p.block);
        end
        if any(pulses);%log pulses if only there is one
            p = Log(p,secs(pulses), 0,keycode(pulses), p.phase, p.block);
        end
        text = NassarRewardText(mean_prediction_error, payout_weight, money_earned, all_rewards.money);


        Screen('FillRect',p.ptb.w,p.var.current_bg);
        Screen('TextSize', p.ptb.w,  15);
        Screen('TextFont', p.ptb.w, 'Courier');
        Screen('TextStyle', p.ptb.w, 1);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        Screen('Flip',p.ptb.w);
        start = GetSecs();
        p = save_data(p, all_rewards);
        while GetSecs() < start+10
        end
        %stop the queue
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
        Screen('TextFont', p.ptb.w, oldFontName, oldTextStyle);
        Screen('TextSize', p.ptb.w,  oldTextSize);
    end


    function [p, abort] = TakeABreak(p)
        % Display 'Take a break', info about next block and next task.
        Screen('Flip', p.ptb.w);     
        start = GetSecs();
        ShowText('1 Minute Pause!\n');
        ShowText('Weiter in 15s. \n', start+45);
        ShowText('Weiter in 5s. \n', start+55);                
    end


    function [p, abort] = MeasureSamplePupilResponses(p)
        % Display 'Take a break', info about next block and next task.
        Eyelink('StartRecording');
        WaitSecs(.01);
        Eyelink('Message', sprintf('SUBJECT %d', p.subject));
        p = Log(p, GetSecs, 'START_SAMPLE_MEASUREMENT', nan, p.phase, p.block);
        p = Log(p, GetSecs, 'SUBJECT', p.subject, p.phase, p.block);
        Eyelink('Message', sprintf('PHASE %d', p.phase));
        Eyelink('Message', sprintf('BLOCK %d', p.block));
        Screen('Flip', p.ptb.w);    
        abort = false;
        dt = 5;
        for sample = dt+1:dt:300            
            start = GetSecs();
            KbQueueFlush(p.ptb.device);
            [evt, n]   = KbEventGet(p.ptb.device);
            [evt, n]   = KbEventGet(p.ptb.device);
            while (GetSecs()-start) < 20           
                [evt, n]   = KbEventGet(p.ptb.device);
                if numel(evt)>0
                    keys = KbName(evt.Keycode);
                    switch keys
                        case  p.keys.quit
                            abort = true;
                            return
                        case {'space'}
                            break
                        case p.keys.pulse
                            p = Log(p,RT, 0, NaN, p.phase, p.block);
                    end
                end
            end
            
            draw_prd_sample(p, sample-dt);
            draw_fix_bg_angled(p, 0);
            Offset = Screen('Flip', p.ptb.w);
            Eyelink('message', 'TRIALID %d', sample);            
            draw_prd_sample(p, sample);
            draw_fix_bg_angled(p, 45);
            Screen('Flip', p.ptb.w, Offset+0.5)
            Eyelink('Message', 'sample %i', sample);
            draw_prd_sample(p, sample);
            draw_fix_bg_angled(p, 0);
            Screen('Flip', p.ptb.w, Offset+3.5)
            if abort 
                return
            end
        end
    end

    %% ----------------------------------- 
    %  Trial functions
    %  -----------------------------------

    function [p, TimeFeedbackOffset, abort, reward] = InstructedRuleTrial(...
            phase, block, p, TimeStimOnset, stim_id, rewarded_rule, jitter)
        %% Run one trial of the localizer block design task.
        rule = nan; %#ok<NASGU>
        abort = false; %#ok<NASGU>
        TimeFeedbackOffset = nan;
        
        TrialStart = GetSecs;
        trial_info = sprintf('STIM=%i, REW_RULE=%i', stim_id, rewarded_rule);
        p = Log(p, TrialStart, 'IR_TRIAL_START', trial_info, phase, block);
        
        
        
        p = dump_keys(p);
        
        if (TimeStimOnset-TrialStart) > 4
            [p, TimeCrossOn] = start_ir_trial(p, phase, block); %#ok<NASGU>
        else
            [p, TimeCrossOn] = start_ir_trial(p, phase, block); %#ok<NASGU>
        end
        [p, RT, ~, rule, abort] = choice_trial(p, TimeStimOnset, stim_id, phase, block);
        reward = nan;
        
        % Rewarded rule 1 => Left rule active:  || <> left, = <> right
        % Rewarded rule 0 => Right rule active: || <> right, = <> left
        if ~isnan(rule)
            if (rule == rewarded_rule)
                reward = 1;
            else
                reward = 0;
            end
            
        end
        [p, TimeFeedbackOffset] = show_feedback(p, 0, RT+jitter, rule, reward, phase, block);
        
        if ~isnan(reward)
            p.earned_rewards = p.earned_rewards + reward;
        end
        
    end


    function [TimeFeedbackOffset, p, abort, prediction] = PredictionTrial(p, TimeStimOnset, sample, sample_duration, jitter, old_prediction, last_sample)
        %% Run one trial
        fixerror = nan;
        rule = nan;
        abort = false;
        TimeFeedbackOffset = nan;
        TrialStart = GetSecs;
        p = Log(p,TrialStart, 'PRD_TRIAL_START', sample, p.phase, p.block);
        
        [p, prediction_time, prediction, abort] = predict_prd_sample(p, old_prediction, last_sample);
        if abort
            return
        end
        
        [TimeFeedbackOffset] = show_prd_sample(p, jitter, sample_duration, sample, prediction);

        p.prev_sample = sample;
    end


    function [p, abort, rule] = handle_retino_response(p, stim_id)
        [keycodes, secs] = KbQueueDump(p);        
        response = nan;
        abort = false;
        rule = nan;
        if numel(keycodes)
            for iii = 1:length(keycodes)
                RT = secs(iii);
                keys = KbName(keycodes(iii));     
                
                switch keys
                    case  p.keys.quit
                        abort = true;
                        return
                    case cat(2, p.keys.answer_a, p.keys.answer_a_train) 
                        % Answer a = Left                        
                        response = 0;
                        p = Log(p, RT, 'RETINO_RESP', 0, p.phase, p.block);
                    case cat(2, p.keys.answer_b, p.keys.answer_b_train) 
                        % Answer b = Right
                        response = 1;
                        p = Log(p, RT, 'RETINO_RESP', 1, p.phase, p.block);
                    case p.keys.pulse
                        fprintf('Logging pulse\n')
                        p = Log(p, RT, 0, KbName(p.keys.pulse), phase, p.block);
                end
            end
        end
        
        if isnan(response)
            rule = nan;
        elseif response == stim_id % Stim_id 0: ||, stim_id 1: =
            % Rule A: || <> Left, = <> Right
            rule = 1;
        else
            % Rule B: || <> Right, = <> Left
            rule = 0;
        end
    end
    

    function [p, TimeCrossOn] = start_ir_trial(p, phase, block)
        %% Start a trial, also allows time for blinks.
        Screen('FillRect', p.ptb.w , p.stim.bg, [] ); %always create a gray background
        draw_fix(p);
        
        Screen('FillRect',  p.ptb.w, [255, 255, 255], p.FixCross');%draw the prestimus cross atop
        TimeCrossOn  = Screen('Flip',p.ptb.w);      %<----- FLIP
        
        p = Log(p,TimeCrossOn, 'IR_TRIAL_FIXON', nan, phase, block);
        Eyelink('Message', 'IR_TRIAL_FIXON');
        %MarkCED( p.com.lpt.address, p.com.lpt.trialOnset);
    end


    function [p, RT, response, rule, abort] = choice_trial(p, TimeStimOnset, stim_id, phase, block)
        
        rule = nan;
        response = nan; %#ok<NASGU>
        RT = nan; %#ok<NASGU>
        abort = false;
        
        draw_stimulus(p, stim_id)
        % STIMULUS ONSET
        TimeStimOnset  = Screen('Flip',p.ptb.w, TimeStimOnset, 0);  %<----- FLIP
        start_rt_counter  = TimeStimOnset;
        p = Log(p,TimeStimOnset, 'CHOICE_TRIAL_ONSET', nan, phase, block);
        Eyelink('Message', 'CHOICE_TRIAL_ONSET');
        MarkCED( p.com.lpt.address, p.com.lpt.stim);
        % Check for key events
        p = dump_keys(p);
        KbQueueFlush(p.ptb.device);        
        % Now wait for response!
        start = GetSecs;
        response = nan;
        RT = nan;
        num_flips = 0.2/p.ptb.slack;
        phase = rand*180;        
        while (GetSecs-start) < (2)
            % Stimulus Offset
            draw_stimulus(p, stim_id, phase);
            step = randsample(45:10:360, 1);
            phase = mod(phase + step, 360);            
            draw_fix_bg(p);
            Screen('FillRect',  p.ptb.w, [255,255,255], p.FixCross');
            TimeStimOnset  = Screen('Flip', p.ptb.w, TimeStimOnset+(num_flips*p.ptb.slack), 0);  %<----- FLIP
        end
        
        p = Log(p,TimeStimOnset, 'CHOICE_TRIAL_STIMOFF', nan, phase, p.block);
        Eyelink('Message', 'CHOICE_TRIAL_STIMOFF');
        response = nan;
        [keycodes, secs] = KbQueueDump(p);
        if numel(keycodes)
            for iii = 1:length(keycodes)
                RT = secs(iii);
                keys = KbName(keycodes(iii));
                
                switch keys
                    case  p.keys.quit
                        abort = true;
                        return
                    case cat(2, p.keys.answer_a, p.keys.answer_a_train) %{p.keys.answer_a, p.keys.answer_a_train}
                        % Answer a = Left
                        response = 0;                        
                        break
                    case cat(2, p.keys.answer_b, p.keys.answer_b_train) %{p.keys.answer_b, p.keys.answer_b_train}
                        % Answer b = Right
                        response = 1;
                        break
                    case p.keys.pulse
                        fprintf('Logging pulse\n')
                        p = Log(p, RT, 0, KbName(p.keys.pulse), phase, p.block);
                end
            end
        end
        if ~isnan(RT)
            Eyelink('Message', sprintf('RT %i', round(1000*(RT-start_rt_counter))));
        end
        if response == 0
            MarkCED(p.com.lpt.address, p.com.lpt.resp0);
        else
            MarkCED(p.com.lpt.address, p.com.lpt.resp1);
        end
        Eyelink('message', sprintf('ANSWER %i', response));
        p = Log(p,RT, 'CHOICE_TRIAL_RESP', response, phase, block);
        p = Log(p,RT, 'CHOICE_TRIAL_RT', RT-start, phase, block);
        
        if ~isnan(response)
            if response == stim_id
                % Stim_id 0: ||, stim_id 1: =
                % Rule A: || <> Left, = <> Right
                rule = 1;
            else
                % Rule B: || <> Right, = <> Left
                rule = 0;
            end
        end
        fprintf('RULE: %i, ', rule);

    end


    function [p, TimeFeedbackOffset] = show_feedback(p, type, TimeFeedbackOnset, rule, reward, phase, block)
        %% Show feedback
        % Define rule correctness here. If sample < 0 then obs have to
        % respond with Rule 0, if sample > 0 have to respond with rule 1
        if type == 1
            % Feedback about correct vs. wrong answer.
            if reward  % Rewarded rule                        
                draw_fix(p, [20, 200, 20]);
            elseif ~isnan(rule)            
                draw_fix(p, [200, 20, 20]);
            end
            fprintf('RULE: %i, GET_REWARD? %i \n', rule, reward);
            p = Log(p, GetSecs, 'FEEDBACK', rule, phase, block);
            Eyelink('message', sprintf('RULE %i', rule));

            TimeFeedback  = Screen('Flip',p.ptb.w, TimeFeedbackOnset, 0);      %<----- FLIP
            Eyelink('message', sprintf('FEEDBACK %f', reward));
            p = Log(p,TimeFeedback, 'FEEDBACK_TYPE', reward, phase, block);
            MarkCED( p.com.lpt.address, p.com.lpt.sample);

            draw_fix(p);
            TimeFeedbackOffset = Screen('Flip',p.ptb.w,TimeFeedback+0.4, 0);     %<----- FLIP

            Eyelink('message', 'FEEDBACKOFF');
            p = Log(p,TimeFeedbackOffset, 'FEEDBACK_OFF', 0, phase, block);
        else
            if ~isnan(rule)
                draw_fix(p, [220, 220, 220]);
            else
                draw_fix(p);
            end
            TimeFeedback  = Screen('Flip',p.ptb.w);      %<----- FLIP
            draw_fix(p);
            TimeFeedbackOffset  = Screen('Flip',p.ptb.w, TimeFeedback+0.1);      %<----- FLIP
        end
        
    end


    function [TimeSampleOffset, p] = show_one_sample(p, SampleOnset, location)
        % Show one sample, such that black and white parts cancel.
        r_inner = p.stim.r_inner;
        o = p.stim.lumdiff;
        p.sample_duration=p.stim.sample_duration;
        x_outer = r_inner*(2^.5 -1);
        r_outer = (r_inner + x_outer)*p.display.ppd;
        r_inner = r_inner*p.display.ppd;
        cx = p.ptb.CrossPosition_x;
        cy = p.ptb.CrossPosition_y;
        
        
        % left, top, right, bottom        
        location = location*p.display.ppd;
        rin = [location-r_inner+cx, cy-r_inner, location+r_inner+cx, r_inner+cy];
        rout = [location-r_outer+cx, cy-r_outer, location+r_outer+cx, r_outer+cy];
        draw_fix(p);
        Screen('FillOval', p.ptb.w, [128-o, 128-o, 128-o], rout);
        Screen('FillOval', p.ptb.w, [128+o, 128+o, 128+o], rin);
        
        SampleOnset  = Screen('Flip',p.ptb.w, SampleOnset, 0);      %<----- FLIP
        Eyelink('message', sprintf('sample %f', location));
        p = Log(p,SampleOnset, 'SAMPLE_ONSET', location, p.phase, p.block);
        %MarkCED( p.com.lpt.address, p.com.lpt.event);
        draw_fix(p);

        TimeSampleOffset = Screen('Flip',p.ptb.w,SampleOnset+p.sample_duration, 0);     %<----- FLIP
        draw_fix(p);
        TimeSampleOffset = Screen('Flip',p.ptb.w,TimeSampleOffset+(.25), 0);
    end
  


    %% ----------------------------------- 
    %  Helper functions
    %  -----------------------------------

    function p = dump_keys(p)
        %dump the final events
        [keycode, secs] = KbQueueDump(p);%this contains both the pulses and keypresses.
        %log everything but "pulse keys" as pulses, not as keypresses.
        pulses          = (keycode == KbName(p.keys.pulse));
        if any(~pulses);%log keys presses if only there is one
            p = Log(p,secs(~pulses), 1000,keycode(~pulses), p.phase, p.block);
        end
        if any(pulses);%log pulses if only there is one
            p = Log(p,secs(pulses), 0,keycode(pulses), p.phase, p.block);
        end
    end


    function draw_stimulus(p, stim_id, phase)
        if nargin==2
            phase = 0;
        end
        angle = 90*stim_id;
        df = p.ptb.rect(3) -  p.ptb.rect(4);
        rect = [df/2., 0, p.ptb.rect(4)+df/2, p.ptb.rect(4)];
        draw_fix(p);
        Screen('DrawTexture', p.ptb.w, p.ptb.gabortex, [], rect, ...
            angle, [], [], [], [], [], [phase, p.stim.sf, 150, 100, 1, 0, 0, 0]);
        radius = 2.5;
        oc = [p.ptb.midpoint(1)-p.display.ppd*radius, p.ptb.midpoint(2)-p.display.ppd*radius,...
            p.ptb.midpoint(1)+p.display.ppd*radius, p.ptb.midpoint(2)+p.display.ppd*radius];
        Screen('FillOval', p.ptb.w, p.stim.bg, oc);
        %draw also the fixation cross
        Screen('FillRect',  p.ptb.w, [255,255,255], p.FixCross');
        Screen('DrawingFinished',p.ptb.w,0);
    end


    function draw_very_small_stimulus(p, stim_id)
        angle = 90*stim_id;
        df = p.ptb.rect(3) -  p.ptb.rect(4);
        %rect = [df/2., 0, p.ptb.rect(4)+df/2, p.ptb.rect(4)];
        ppd = p.display.ppd*0.5;
        oc = [p.ptb.midpoint(1)-ppd, p.ptb.midpoint(2)-ppd, p.ptb.midpoint(1)+ppd, p.ptb.midpoint(2)+ppd];
        Screen('DrawTexture', p.ptb.w, p.ptb.gabortex, [], oc, ...
            angle, [], [], [], [], [], [0, p.stim.sf/5, 150, 10, 1, 0, 0, 0]);
       
    end


    function draw_fix_bg(p, color)
        if nargin==1
            color=[255, 255, 255];
            
        end        
        cx = mean(p.FixCross(2,[1, 3]));
        cy = mean(p.FixCross(2,[2, 4]));            
        r = 0.25*p.display.ppd;            
        rr = [cx-r, cy-r, cx+r, cy+r];             
        Screen('FillOval', p.ptb.w, [128, 128, 128], rr);                               
        Screen('FillRect',  p.ptb.w, color, p.FixCross');
    end


    function draw_fix_bg_angled(p, angle)       
        cx = mean(p.FixCross(2,[1, 3]));
        cy = mean(p.FixCross(2,[2, 4]));            
        r = 0.25*p.display.ppd;            
        rr = [cx-r, cy-r, cx+r, cy+r]; 
        Screen('FillOval', p.ptb.w, [128, 128, 128], rr);     
        Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('DrawTexture',  p.ptb.w, p.stim.fix, [], [], angle);
        Screen('BlendFunction', p.ptb.w, 'GL_ONE', 'GL_ZERO');
        
    end


    function draw_square(p, angle)                      
        Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('DrawTexture',  p.ptb.w, p.stim.square, [], [], angle);
        Screen('BlendFunction', p.ptb.w, 'GL_ONE', 'GL_ZERO');
    end


    function draw_fix(p, color, rule)
        if nargin==1
            color=[255, 255, 255];
            rule = nan;
        elseif nargin == 2
            if numel(color) == 0;
                color = [255, 255, 255];
            end
            rule = nan;
        end
        if ~isnan(rule)        
            center = mean(p.FixCross(2,[2, 4]));
            left  = p.ptb.CrossPosition_x - 0.5*p.display.ppd;            
            right = p.ptb.CrossPosition_x + 0.5*p.display.ppd;
            rl = [left-3, center-3, left+3, center+3]; 
            rr = [right-3, center-3, right+3, center+3]; 
            if rule == 1
                Screen('FillOval', p.ptb.w, [100, 100, 100], rl);
                Screen('FrameOval', p.ptb.w,[10,  10,  10], rl);
                Screen('FillOval', p.ptb.w, [100, 100, 100], rr);
            else
                Screen('FillOval', p.ptb.w, [100, 100, 100], rl);
                Screen('FillOval', p.ptb.w, [100, 100, 100], rr);
                Screen('FrameOval', p.ptb.w,[10,  10,  10], rr);
            end                        
        end
        Screen('FillRect',  p.ptb.w, color, p.FixCross');
    end


    function TimeCrossOn= start_prd_trial(p, allow_blink)
        %% Start a trial, also allows time for blinks.
        Screen('FillRect', p.ptb.w , p.stim.bg, [] ); %always create a gray background
        draw_prd_background(p)

        if allow_blink>0 % Give time for blinks.
            %Screen('FillRect',  p.ptb.w, [0, 55, 200], p.FixCross');%draw the prestimus cross atop
            draw_fix_bg(p, [0, 55, 200]);
            TimeBlinkOn  = Screen('Flip',p.ptb.w, allow_blink+2);      %<----- FLIP
            draw_fix_bg(p);
            %Screen('FillRect',  p.ptb.w, [255, 255, 255], p.FixCross');%draw the prestimus cross atop
            draw_prd_background(p)

            TimeCrossOn  = Screen('Flip',p.ptb.w, TimeBlinkOn+1);      %<----- FLIP
        else
            %Screen('FillRect',  p.ptb.w, [255, 255, 255], p.FixCross');%draw the prestimus cross atop
            draw_fix_bg(p);
            TimeCrossOn  = Screen('Flip',p.ptb.w);      %<----- FLIP
        end
        %p = Log(p,TimeCrossOn, 3, nan, p.phase, p.block);
        Eyelink('Message', 'FIXON');
        MarkCED(p.com.lpt.address, 3);
    end
    

    function [TimeFeedbackOffset] = show_prd_sample(p, jitter, duration, sample, prediction)      
        draw_prd_background(p)
        draw_prd_sample(p, prediction)
        draw_fix_bg_angled(p, 45);        
        TimeFeedbackOnset  = Screen('Flip',p.ptb.w);      %<----- FLIP       
        draw_prd_background(p)
        draw_fix_bg_angled(p, 45);        
        draw_prd_sample(p, sample)
        error = false;
        TimeFeedback  = Screen('Flip',p.ptb.w, TimeFeedbackOnset+jitter, 0);      %<----- FLIP
        Eyelink('message', sprintf('FEEDBACK %f', sample));
        p = Log(p,TimeFeedback, 9, sample, p.phase, p.block);
        MarkCED( p.com.lpt.address, 130+sample);
        
        draw_prd_background(p)
        draw_fix_bg_angled(p, 45);
        draw_prd_sample(p, sample)
        eyeused = Eyelink('EyeAvailable')+1;
        % Now check eye movements
        xc = (p.ptb.rect(3) -  p.ptb.rect(1))/2;
        yc = (p.ptb.rect(4) -  p.ptb.rect(2))/2;
        error = false;
        while GetSecs() < (TimeFeedback+duration-p.ptb.slack)
            if ~NoEyelink && Eyelink('NewFloatSampleAvailable')
                esample = Eyelink('NewestFloatSample');
                x = esample.gx(eyeused);
                y = esample.gy(eyeused);
                distance = (((x-xc)^2 + (y-yc)^2)^.5)/p.display.ppd;
                if distance > 1.5
                    error = true;
                end
                
            end
        end
        TimeFeedbackOffset = Screen('Flip',p.ptb.w,TimeFeedback+duration-p.ptb.slack/2, 0);     %<----- FLIP
        Eyelink('message', 'FEEDBACKOFF');
        p = Log(p,TimeFeedbackOffset, 10, 0, p.phase, p.block);
        MarkCED( p.com.lpt.address, 140);
        
        if error
            draw_prd_background(p);
            draw_square(p, 45);
            draw_prd_sample(p, sample)
            TimeErrorOnset = Screen('Flip',p.ptb.w);     %<----- FLIP
            draw_prd_background(p);
            draw_square(p, 45);
            draw_prd_sample(p, sample)
            TimeErrorOffset = Screen('Flip',p.ptb.w, TimeErrorOnset+1);     %<----- FLIP
        end
    end


    function [p, TimeFeedbackOffset, prediction, abort] = predict_prd_sample(p, old_prediction, sample)
        % Predict sample trial
        abort = false;
        prediction = nan;
        update = nan;
        TimeFeedbackOffset = nan;
        %% STIMULUS ONSET              
        [keycode, secs] = KbQueueDump(p);
        if numel(keycode)            
            for iii = 1:length(keycode)
                pulses = (keycode(iii) == KbName(p.keys.pulse));
                if any(pulses);
                    p = Log(p,secs(pulses), 0, keycode(pulses), p.phase, p.block);
                else
                    Log(p, secs(iii), 'NASSAR_PRD_BEFORE_RESP', keycode(iii), p.phase, p.block);
                end
            end
        end
        KbQueueFlush(p.ptb.device);
        
        Screen('FillRect',  p.ptb.w, [20,20,255], p.FixCross');
        draw_prd_background(p);
        draw_prd_sample(p, old_prediction);
        draw_fix_bg_angled(p, 0);
        TimeStimOnset  = Screen('Flip',p.ptb.w);  %<----- FLIP                       
        Eyelink('Message', 'StimOnset');
        Eyelink('Message', 'SYNCTIME');
        MarkCED( p.com.lpt.address, 4);        
        p = Log(p, GetSecs, 'PRD_PREDICT_SAMPLE_ON', nan, p.phase, p.block); 
        p = Log(p,TimeStimOnset, 5, nan, p.phase, p.block);
        Eyelink('Message', 'StimOff');
        MarkCED( p.com.lpt.address, 5);

        % Now do prediction.
        % How do the controls work? Let's treat this thing as if
        % If stimulus = 0, then left = x, right = m
        % If stimulus = 1, then left = m, right = x
        % Needs to be checked for consistency!
        prediction = old_prediction;
        start = GetSecs;
        current = start;
        response = nan;
        RT = nan;
        next_flip = start+p.ptb.slack*2;
        modifier = 0;
        currentup=GetSecs()-0.02;
        while (current-start) < 20
            [evt, n]   = KbEventGet(p.ptb.device);
            %[keycodes, secs] = KbQueueDump(p);
            if numel(evt)>0                    
                    %keys = KbName(keycodes(i));
                    keys = KbName(evt.Keycode);                    
                        switch keys
                            case  p.keys.quit
                                abort = true;
                                return
                            case {p.keys.answer_a, p.keys.answer_a_train}
                                if evt.Pressed
                                    modifier = -1;
                                else
                                    modifier = 0;
                                end

                            case {p.keys.answer_b, p.keys.answer_b_train}
                                if evt.Pressed
                                    modifier = 1;
                                else
                                    modifier = 0;
                                end
                            case {'space'}
                                break
                            case p.keys.pulse
                                p = Log(p,RT, 0, NaN, p.phase, p.block);
                        end                                            
            end
            if GetSecs()-currentup > 0.1
                prediction = prediction + modifier;
                currentup = GetSecs();
            end
                  
            
            current = GetSecs();
            if (current-next_flip) < (p.ptb.slack/2)
                draw_prd_background(p)
                draw_prd_sample(p, prediction)
                draw_fix_bg_angled(p, 0);
                update  = Screen('Flip',p.ptb.w);
                next_flip = update+p.ptb.slack*2;
            end

        end        
        %draw_prd_background(p)
        %draw_prd_sample(p, prediction);
        %draw_fix_bg_angled(p, 0);
        %lastflip  = Screen('Flip',p.ptb.w);
        % Now show prediction error
        error = sample-prediction;
        TimeFeedbackOffset = update;

        Eyelink('message', 'PREDICTION');
        p = Log(p,TimeFeedbackOffset, 10, 0, p.phase, p.block);
        MarkCED( p.com.lpt.address, 140);
    end
    

    function draw_prd_sample(p, sample )           
        %text = sprintf('%03i', sample);
        %h = p.ptb.rect(2) + (p.ptb.rect(4)-p.ptb.rect(2))/2 + 10;
        %Screen('TextSize', p.ptb.w,  75);
        %DrawFormattedText(p.ptb.w, text, 'center', h, [168, 168, 168], [],[],[],2,[]);
        %Screen('TextSize', p.ptb.w,  72);
        %DrawFormattedText(p.ptb.w, text, 'center', h, [88, 88, 88], [],[],[],2,[]);                
        %Screen('TextSize', p.ptb.w,  70);
        %DrawFormattedText(p.ptb.w, text, 'center', h, [128, 128, 128], [],[],[],2,[]);
        Screen('BlendFunction', p.ptb.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('DrawTexture',  p.ptb.w, p.stim.sample_textures(sample));
        Screen('BlendFunction', p.ptb.w, 'GL_ONE', 'GL_ZERO');  
    end


    function draw_prd_background(p)
       %Screen('DrawTexture', p.ptb.w, p.stim.noise_texture, [], p.ptb.rect);
    end


    function vbl = show_block(p, validity, duration)
        switch validity
            case 1
                img=imread('instructions/instruction_A.png', 'BackgroundColor', [.5, .5, .5]);           
            case 0
                img=imread('instructions/instruction_B.png', 'BackgroundColor', [.5, .5, .5]);
            case -1
                img=imread('instructions/instruction_both.png', 'BackgroundColor', [.5, .5, .5]);
        end
        instructions = Screen('MakeTexture', p.ptb.w, img);
        Screen('DrawTexture', p.ptb.w, instructions, [], p.ptb.rect)
        draw_fix(p, [], validity);
        %text = ['Nochmal die Regeln als Erinnerung. Gleich gehts los'];
        %DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);
        vbl = Screen('Flip', p.ptb.w);
        draw_fix(p);
        vbl = Screen('Flip', p.ptb.w, vbl+duration);
    end


    function vbl = show_glaze_block(p, duration)
        img=imread('instructions/instruction_glaze.png', 'BackgroundColor', [.5, .5, .5]);
        instructions = Screen('MakeTexture', p.ptb.w, img);
        Screen('DrawTexture', p.ptb.w, instructions, [], p.ptb.rect)
        
        Screen('DrawTexture', p.ptb.w, p.stim.left_txt, [], p.stim.left_rect);
        Screen('DrawTexture', p.ptb.w, p.stim.right_txt, [], p.stim.right_rect);
        
        draw_fix(p);
        vbl = Screen('Flip', p.ptb.w);
        draw_fix(p);
        if duration > 0
            vbl = Screen('Flip', p.ptb.w, vbl+duration);
        end
    end


    function vbl = explain_retino_block(p)
        %Screen('DrawTexture', p.ptb.w, instructions, [], p.ptb.rect)
        text = ['Im n�chsten Block musst du auf kleine Muster mit einem Knopfdruck reagieren.\n',...
             'Welcher Knopf gedr�ckt werden muss h�ngt von der aktiven Regel ab.\n',...
             'Die aktive Regel wird durch Punkte neben dem Fixationskreuz angezeigt.\n'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);
        draw_fix(p);
        vbl = Screen('Flip', p.ptb.w);   
        KbStrokeWait(p.ptb.device);
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);
        draw_fix(p, [], 1);        
        DrawFormattedText(p.ptb.w, ['Jetzt ist die Linke Regel aktiv!'], 'center', round(p.ptb.rect(4)*.75), p.stim.white,[],[],[],2,[]);
        vbl = Screen('Flip', p.ptb.w);
        KbStrokeWait(p.ptb.device);
        
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);
        draw_fix(p, [], 0);        
        DrawFormattedText(p.ptb.w, ['Jetzt ist die Rechte Regel aktiv!'], 'center', round(p.ptb.rect(4)*.75), p.stim.white,[],[],[],2,[]);
        vbl = Screen('Flip', p.ptb.w);
        KbStrokeWait(p.ptb.device);
        
        
        Screen('DrawTexture', p.ptb.w, p.stim.left, [], p.ptb.rect)
        draw_fix(p, [], 0);     
        draw_very_small_stimulus(p, 1)
        text = ['Wenn die rechte Regel aktiv ist und ein\n',...
            'horizontales Muster erscheint muss die linke Taste gedr�ckt werden.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        Screen('DrawTexture', p.ptb.w, p.stim.right, [], p.ptb.rect)
        draw_fix(p, [], 0);     
        draw_very_small_stimulus(p, 0)
        text = ['Wenn die rechte Regel aktiv ist und ein\n',...
            'vertikales Muster erscheint muss die rechte Taste gedr�ckt werden.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        Screen('DrawTexture', p.ptb.w, p.stim.right, [], p.ptb.rect)
        draw_fix(p, [], 1);     
        draw_very_small_stimulus(p, 1)
        text = ['Wenn die linke Regel aktiv ist und ein\n',...
            'horizontales Muster erscheint muss die rechte Taste gedr�ckt werden.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        Screen('DrawTexture', p.ptb.w, p.stim.left, [], p.ptb.rect)
        draw_fix(p, [], 0);     
        draw_very_small_stimulus(p, 0)
        text = ['Wenn die linke Regel aktiv ist und ein\n',...
            'vertikales Muster erscheint muss die linke Taste gedr�ckt werden.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        Screen('DrawTexture', p.ptb.w, p.stim.instruction_both, [], p.ptb.rect)
        text = ['Hier noch einmal eine �bersicht:'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        
        text = ['Du hast jetzt die M�glichkeit diese Regeln zu �ben.\n\n'...
            'Das Fixationskreuz wird gr�n nach einer richtigen Regelanwendung\n'...
            'und rot nach einer falschen Regelanwendung.\n\n'...
            'Nicht vergessen: So wenig wie m�glich bewegen und immer (!) auf das\n'...
            'Fixationskreuz schauen. Das sich bewegende Zeug im Hintergrund einfach ignorieren...'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
    
    end


    function vbl = explain_instructed_rule(p)
        %Screen('DrawTexture', p.ptb.w, instructions, [], p.ptb.rect)
        text = ['Im n�chsten Block musst du auf gro�e Muster mit einem Knopfdruck reagieren.\n',...
             'Welcher Knopf gedr�ckt werden muss h�ngt wieder von der aktiven Regel ab.\n',...
             'Welche Regel aktiv ist zeigen wir dir bevor sie sich �ndert.\n'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);   
        KbStrokeWait(p.ptb.device);                
        
        Screen('DrawTexture', p.ptb.w, p.stim.rule_left, [], p.ptb.rect)
        draw_fix(p, [], 1);            
        text = ['Mit diesem Symbol zeigen wir dir, dass die linke Regel aktiv wird.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        Screen('DrawTexture', p.ptb.w, p.stim.rule_right, [], p.ptb.rect)
        draw_fix(p, [], 0);            
        text = ['Mit diesem Symbol zeigen wir dir, dass die rechte Regel aktiv wird.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        text = ['Bereit?\n\n'...
            'Ach, in diesem Block wirst du �brigens f�r richtige Antworten bezahlt.\nWie viel du verdient hast erf�hrst du am Ende vom Block.\n\n',...
            'Nicht vergessen: So wenig wie m�glich bewegen\n'...
            'und immer (!) auf das Fixationskreuz schauen.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
    
    end


    function vbl = explain_glaze_rule(p)
        %Screen('DrawTexture', p.ptb.w, instructions, [], p.ptb.rect)
        text = ['Im n�chsten Block musst du auf gro�e Muster mit einem Knopfdruck reagieren.\n',...
             'Welcher Knopf gedr�ckt werden muss h�ngt wieder von der aktiven Regel ab.\n',...
             'Welche Regel aktiv ist musst du dieses mal selber herrausfinden.\n\n',...
             'Du wirst gleich in schneller Reihenfolge Punkte aufblinken sehen, deren seitlicher\n'...
             'Verschub R�ckschl�sse auf die aktive Regel zul�sst.'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);   
        KbStrokeWait(p.ptb.device);                
        
        Screen('DrawTexture', p.ptb.w, p.stim.rule_left, [], p.ptb.rect)
        Screen('DrawTexture', p.ptb.w, p.stim.left_txt, [], p.stim.left_rect)        
        draw_fix(p, [], 1);            
        text = ['Wenn z.B. die linke Regel aktiv ist folgen die Punkte der unten angezeigten Verteilung.\n'];            
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        Screen('DrawTexture', p.ptb.w, p.stim.rule_right, [], p.ptb.rect)
        Screen('DrawTexture', p.ptb.w, p.stim.right_txt, [], p.stim.right_rect)        
        draw_fix(p, [], 1);            
        text = ['Wenn z.B. die rechte Regel aktiv ist folgen die Punkte dieser Verteilung.\n'];            
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
        
        Screen('DrawTexture', p.ptb.w, p.stim.right_txt, [], p.stim.right_rect)        
        Screen('DrawTexture', p.ptb.w, p.stim.left_txt, [], p.stim.left_rect)        
        draw_fix(p);            
        text = ['Wie du siehst sind beide Verteilungen stark �berlappend!\n',...
            'Deswegen reicht ein einzelner Punkt nicht aus um die richtige Regel zu bestimmen.\n'];            
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.1), p.stim.white,[],[],[],2,[]);        
        text = ['Stattdessen solltest du kontinuierlich �berlegen welche Regel am besten mit der\n Position der letzten Punkte �bereinstimmt.\n',...
            'Auch wichtig: Die aktive Regel �ndert sich unvorhersehbar!'];
        DrawFormattedText(p.ptb.w, text, 'center', round(p.ptb.rect(4)*.75), p.stim.white,[],[],[],2,[]);        
        vbl = Screen('Flip', p.ptb.w);        
        KbStrokeWait(p.ptb.device);
        
    end


    function text = RewardText(reward, reward_rate, earned_money, total_money)
        text = [sprintf('Im letzten Block haben Sie %d Belohnungen erhalten (%2.0f%%)\n', reward, 100*reward_rate)...
            sprintf('Das entspricht %1.2f EUR!\n', earned_money)...
            sprintf('Insgesamt haben sich damit %1.2f EUR Bonus angesammelt!', total_money)];
    end


    function text = NassarRewardText(error, reward_rate, earned_money, total_money)
        text = [sprintf('Im letzten Block war ihr mittlerer Fehler %3.1f.\n', roundn(error, -1))...
            sprintf('Damit bekommen Sie %2.0d%% der Belohung ausgezahlt\n', reward_rate*100),...
            sprintf('Das entspricht %1.2f EUR!\n', earned_money)...
            sprintf('Insgesamt haben sich damit %1.2f EUR Bonus angesammelt!', total_money)];
    end


    function ShowInstruction(waitforkeypress, text) 
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, ==> subject presses a button to proceed
        %if waitforkeypress is 2, ==> show text and immediately return
        %if waitforkeypress is <0, ==> text is shown for -waitforkeypress seconds.
        
        
        ShowText(text);
        
        if waitforkeypress==1 %and blank the screen as soon as the key is pressed
            KbStrokeWait(p.ptb.device);
        elseif waitforkeypress==2
            return
        else
            WaitSecs(-waitforkeypress);
        end
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        Screen('Flip',p.ptb.w);        
    end


    function ShowText(text, onset)
        
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        if nargin==1
            Screen('Flip',p.ptb.w);
        else
            Screen('Flip',p.ptb.w, onset);
        end
        %show the messages at the experimenter screen
    end

    
    function ShowImage(image, onset)
        
        Screen('FillRect',p.ptb.w,p.var.current_bg);
        DrawFormattedText(p.ptb.w, text, 'center', 'center', p.stim.white,[],[],[],2,[]);
        if nargin==1
            Screen('Flip',p.ptb.w);
        else
            Screen('Flip',p.ptb.w, onset);
        end
        %show the messages at the experimenter screen
    end
    
    
    function [text]=GetText(nInstruct, train)
        if nInstruct == 1 %Retinotopy.
            text = ['Im n�chsten Block hast du die Gelegenheit beide Regeln zu �ben.\n'...
                    ''];
            
            
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


    function SetParams
        %mrt business
        p.mrt.dummy_scan              = 5; %this will wait until the 6th image is acquired.
        p.mrt.LastScans               = 5; %number of scans after the offset of the last stimulus
        p.mrt.tr                      = 2; %in seconds.
        
        %will count the number of events to be logged
        p.var.event_count             = 0;
        
        
        %% relative path to stim and experiments
        %Path Business.
        [~, hostname]                 = system('hostname');
        p.hostname                    = deblank(hostname);
        
        if strcmp(p.hostname, 'larry.local')
            p.display.resolution = [1920 1200]; %For the EliteDisplay in the office
            p.display.dimension = [28, 17.5]; %Macbook display
            p.display.dimension = [52, 33]; %
            p.display.distance = [62, 59];
            p.path.baselocation           = '/Users/nwilming/u/flexible_rule/experiment/data/';
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
        p.stim.bar_width = 400;
        p.stim.bar_separation = 50;
        p.stim.r_inner = .1;
        p.stim.lumdiff = 50;
        p.stim.sample_duration = .1;
        p.stim.threshold = .5;
        p.stim.sigma = 1;
        %create the base folder if not yet there.
        if exist(p.path.baselocation) == 0 %#ok<EXIST>
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
        p.keys.answer_a                = {'1!', '2@', '3#', '4$'};
        p.keys.answer_a_train          = 'x';
        p.keys.answer_b                = {'6^', '7&', '8*', '9('};
        p.keys.answer_b_train          = 'm';
        p.keys.pulse                   = '5%';
        p.keys.el_calib                = 'v';
        p.keys.el_valid                = 'c';
        p.keys.escape                  = 'ESCAPE';
        p.keys.enter                   = 'return';
        p.keys.quit                    = 'q';
        p.keylist = {p.keys.confirm,...
            p.keys.answer_a{1}, p.keys.answer_a{2},p.keys.answer_a{3},p.keys.answer_a{4},...
            p.keys.answer_b{1}, p.keys.answer_b{2},p.keys.answer_b{3},p.keys.answer_b{4},...
            p.keys.answer_a_train,...
            p.keys.answer_b_train, p.keys.pulse,...
            p.keys.el_calib, p.keys.el_valid, p.keys.enter};
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address = 888;%parallel port of the computer.
        %codes for different events that are sent for logging in the
        %physiological computer.
        p.com.lpt.resp0     = 128;
        p.com.lpt.resp1     = 64;
        p.com.lpt.stim      = 32;
        p.com.lpt.sample    = 16;
        %Record which Phase are we going to run in this run.
        p.stim.phase                   = phase;
        p.out.log                     = cell(1000000,1);%Experimental LOG.
        
        %%
        p.var.current_bg              = p.stim.bg;%current background to be used.
        %save(p.path.path_param,'p');
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
            [idx, names, ~] = GetKeyboardIndices;
            p.ptb.device = nan;
            for iii = 1:length(idx)
                if strcmp(names{iii}, '')
                    p.ptb.device = idx(iii);
                    break
                elseif strcmp(names{iii}, 'Apple Internal Keyboard / Trackpad') && isnan(p.ptb.device)
                    p.ptb.device = idx(iii);
                    break
                end
            end
            fprintf('Device name is: %s\n', names{iii})
            gamma = load('dell241i_calibration.mat');
            p.ptb.gamma = gamma.gTmp;
        elseif strcmp(p.hostname, 'donnerlab-Precision-T1700')
            p.ptb.screenNumber          =  0;
            [idx, names, ~] = GetKeyboardIndices;
            p.ptb.device = nan;
            for iii = 1:length(idx)
                if strcmp(names{iii}, 'DELL Dell USB Entry Keyboard')
                    p.ptb.device = idx(iii);
                    break
                end
            end
            p.ptb.device            
            gamma = load('vpixx_gamma_table.mat');
            p.ptb.gamma = gamma.table;
        else
            p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor
            p.ptb.device        = -1;
            gamma = load('nne_uke_scanner.mat');
            p.ptb.gamma = gamma.gammaTable;
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
            [p.ptb.w, p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, [128, 128, 128]);
        else
            [p.ptb.w, p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, [128, 128, 128], [0, 0, 900, 700]);
        end
        
        BackupCluts();
        if numel(p.ptb.gamma, 2) > 0
            [old_table] = Screen('LoadNormalizedGammaTable', p.ptb.w, p.ptb.gamma);
            p.ptb.gamma_loaded = true;
            p.ptb.old_gamma = old_table;
            p.ptb.gamma_loaded = false;
        else
            p.ptb.gamma_loaded=false
        end
        Screen('Flip',p.ptb.w);%make the bg
        
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        
        %find the mid position on the screen.
        x = p.ptb.rect(1) + (p.ptb.rect(3)/2);
        y = p.ptb.rect(2) + (p.ptb.rect(4)/2);
        
        p.ptb.midpoint              = [x, y]; % p.ptb.width./2 p.ptb.height./2];
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
        p.stim.radius = p.ptb.rect(4)/2;
        p.stim.radius_deg = (p.ptb.rect(4)/2)/p.display.ppd;
        p.stim.sf = 1.2/p.display.ppd;
        fprintf('R and SF: %f %f', p.stim.radius, p.stim.sf)
        %p.ptb.gabortex = CreateProceduralGabor(p.ptb.w, p.ptb.width, p.ptb.height, 0, [0.5 0.5 0.5 0.0]);
        p.ptb.gabortex = CreateProceduralSineGrating(p.ptb.w, 2*p.stim.radius, 2*p.stim.radius,...
            [], p.stim.radius);
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        %Make final reminders to the experimenter to avoid false starts,
        %which are annoying. Here I specifically send test pulses to the
        %physio computer and check if everything OK.
        % k = 0;
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
        
        
        fix          = [p.ptb.CrossPosition_x p.ptb.CrossPosition_y];
        
        d = (p.ptb.fc_size(1)^2/2)^.5;
        p.square = [fix(1)-d, fix(2)-d, fix(1)+d, fix(2)+d];        
        p.FixCross     = [fix(1)-1,fix(2)-p.ptb.fc_size,fix(1)+1,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-1,fix(1)+p.ptb.fc_size,fix(2)+1];
        p.FixCross_s   = [fix(1)-1,fix(2)-p.ptb.fc_size/2,fix(1)+1,fix(2)+p.ptb.fc_size/2;fix(1)-p.ptb.fc_size/2,fix(2)-1,fix(1)+p.ptb.fc_size/2,fix(2)+1];
        p = make_dist_textures(p);
        l = p.ptb.rect(1); t = p.ptb.rect(2); r = p.ptb.rect(3); b = p.ptb.rect(4);
        p.stim.left_rect = [l, (b-t)/2-5-20, r, (b-t)/2+5-20];
        p.stim.right_rect = [l, 20+(b-t)/2-5, r, 20+(b-t)/2+5];
    end


    function [t]=StartEyelinkRecording(nTrial, phase, validity, stim, block_id, rewarded_rule)
        if ~NoEyelink
            Eyelink('Message', 'TRIALID: %04d, PHASE: %04d, VALIDITY: %04d, STIM: %04d, BLOCK %04d', nTrial, phase, validity, stim, block_id, rewarded_rule);
            Eyelink('Command', 'record_status_message "Trial: %i"', nTrial);
            t = GetSecs;
        else
            t = GetSecs;
        end
    end


    function [t]=StartGlazeEyelinkRecording(nTrial, phase)
        if ~NoEyelink
            Eyelink('Message', 'GLAZEBLOCK: %04d, phase:%04d', nTrial, phase);
            t = GetSecs;
        else
            t = GetSecs;
        end
    end


    function [t]=StarRetinoEyelinkRecording(type, reverse)
            if ~NoEyelink
                Eyelink('Message', 'RETINO_BLOCK_START %s %i', type, reverse);
                t = GetSecs;
            else
                t = GetSecs;
            end
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
        if p.subject == -100
            p.edffile = 'samptest.edf';
        else
            p.edffile = sprintf('%d%d%d.edf', p.subject, p.phase, p.block);
        end
        res = Eyelink('Openfile', p.edffile); %#ok<NASGU>
        
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
        Eyelink('command', 'calibration_type = HV13');
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
        RestoreCluts()
        %Screen('flip', p.ptb.w)
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
        if numel(p.ptb.gamma, 2) > 0
            [old_table] = Screen('LoadNormalizedGammaTable', p.ptb.w, p.ptb.gamma);
            p.ptb.gamma_loaded = true;
            p.ptb.old_gamma = old_table;
            p.ptb.gamma_loaded = false;
        else
            p.ptb.gamma_loaded=false;
        end
    end


    function p = Log(p, ptb_time, event_type, event_info, phase, block)
        for iii = 1:length(ptb_time)
            p.var.event_count                = p.var.event_count + 1;
            p.out.log{p.var.event_count}   = {ptb_time(iii) event_type event_info(iii) phase block};            
            %fprintf('LOG: %2.2f, %i, %s, %s, %i \n', ptb_time, event_type, event_info, phase, block)
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
        
        %KbQueueFlush(p.ptb.device);
        %KbQueueStop(p.ptb.device);
        %KbQueueRelease(p.ptb.device);
        
        
        fprintf('Will wait for %i dummy pulses...\n',n);
        if n ~= 0
            secs  = nan(1,n);
            pulse = 0;
            %dummy = [];
            while pulse < n
                dummy         = KbTriggerWait(KbName(keycode), p.ptb.device);
                pulse         = pulse + 1;
                fprintf('.')
                secs(pulse+1) = dummy;
                p = Log(p, dummy, 0, NaN, 0, 0);
            end
        else
            secs = GetSecs;
        end
        fprintf('\n')
    end


    function [keycode, secs] = KbQueueDump(p)
        %[keycode, secs] = KbQueueDump
        %   Will dump all the events accumulated in the queue.
        keycode = [];
        secs    = [];
        pressed = [];
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet(p.ptb.device);
            n          = n + 1;
            keycode(n) = evt.Keycode; %#ok<AGROW>
            pressed(n) = evt.Pressed; %#ok<AGROW>
            secs(n)    = evt.Time; %#ok<AGROW>
        end
        i           = pressed == 1;
        keycode(~i) = [];
        secs(~i)    = [];
        
    end
    

    function [keyIsDown, firstPress] = check_kbqueues(devices) %#ok<DEFNU>
        firstPress = boolean(zeros(1, 256));
        keyIsDown = false;
        for device = devices
            [kD, fP] = PsychHID('KbQueueCheck', device);
            keyIsDown = keyIsDown | kD;
            firstPress = firstPress | boolean(fP);
        end
    end


    function p = save_data(p, all_rewards) %#ok<INUSD>
        p.save_time = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
        rst = randstr(5);
        p.random_stirng = rst;
        path = fullfile(p.path.baselocation, sprintf('SUB_%i', p.subject), sprintf('PH_%d', p.phase, p.block)); 
        if ~exist(path) %#ok<EXIST>
            mkdir(path)
        end
        
        path_reward = fullfile(p.path.baselocation, sprintf('SUB_%i', p.subject)); 
        if ~exist(path) %#ok<EXIST>
            mkdir(path)
        end
        
        path_edf = fullfile(path, sprintf('S%d_P%d_B%d_%s_%s.edf', p.subject, p.phase, p.block, p.start_time, rst));
        path_data = fullfile(path, sprintf('S%d_P%d_B%d_%s_%s_data.mat', p.subject, p.phase, p.block, p.start_time, rst));
        path_rewards = fullfile(path_reward,'rewards_latest.mat');
        path_rewards_ts = fullfile(path_reward, sprintf('rewards_%s_%s.mat', p.start_time, rst));
        %get the eyelink file back to this computer
        StopEyelink(p.edffile, path_edf);
        %trim the log file and save
        p.out.log = p.out.log(1:p.var.event_count);
        
        %shift the time so that the first timestamp is equal to zero
        %p.out.log(:,1) = p.out.log(:,1) - p.out.log(1);
        %p.out.log      = p.out.log;%copy it to the output variable.
        save(path_data, 'p');
        save(path_rewards, 'all_rewards')
        save(path_rewards_ts, 'all_rewards')
        
    end


    function r = randstr(n)
        symbols = ['a':'z' 'A':'Z' '0':'9'];
        stLength = randi(n);
        nums = randi(numel(symbols),[1 stLength]);
        r = symbols (nums);
    end


    function ppd = ppd(distance, x_px, width)
        o = tan(0.5*pi/180) * distance;
        ppd = 2 * o*x_px/width;
    end


    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end


    function p = make_dist_textures(p)
        ppd = p.display.ppd;
        w = p.ptb.rect(3)-p.ptb.rect(1);
        h = p.ptb.rect(4)-p.ptb.rect(2);
        x = (1:w)/ppd;
        x = x- ((w/2)/ppd);
        left = (normpdf(x, -p.stim.threshold, p.stim.sigma));
        left = left-min(left);
        right = (normpdf(x, p.stim.threshold, p.stim.sigma));
        right = right-min(right);
        left = 128+128*(left/max(left));
        right = 128+128*(right/max(right));
        
        p.stim.left_txt =  Screen('MakeTexture', p.ptb.w, left);
        p.stim.right_txt = Screen('MakeTexture', p.ptb.w, right);
        
        img=imread('instructions/left.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.left = Screen('MakeTexture', p.ptb.w, img);
        
        img=imread('instructions/right.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.right = Screen('MakeTexture', p.ptb.w, img);
        
        img=imread('instructions/instruction_both.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.instruction_both = Screen('MakeTexture', p.ptb.w, img);
        
        img=imread('instructions/instruction_A.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.rule_left = Screen('MakeTexture', p.ptb.w, img);
        
        img=imread('instructions/instruction_B.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.rule_right = Screen('MakeTexture', p.ptb.w, img);
        
        img=imread('instructions/instruction_connectivity_B_S1.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.instruction_B1S1 = Screen('MakeTexture', p.ptb.w, img);
        
        img=imread('instructions/instruction_connectivity_B_S2.png', 'BackgroundColor', [.5, .5, .5]);
        p.stim.instruction_B1S2 = Screen('MakeTexture', p.ptb.w, img);
        
        
        noise = round(rand(round(h), round(w))*255);
        %noise = imresize(noise, [h, w], 'nearest');
        %noise = 255*(noise>mean(noise(:)));        
        p.stim.noise_texture = Screen('MakeTexture', p.ptb.w, noise);
        
        I = cat(3, ones(h, w)*128, ones(h, w)*0);
        p.stim.fix = Screen('MakeTexture', p.ptb.w, I);
        Screen('FillRect',  p.stim.fix, [255, 255, 255], p.FixCross')
        %cross = cat(3, [[0, 255, 0]; [255, 255, 255]; [0, 255, 0]], [[0, 255, 0]; [255, 255, 255]; [0, 255, 0]]);
        %p.stim.fix = Screen('MakeTexture', p.ptb.w, cross);
        %cx = w/2;
        %cy = h/2;
        %d = p.display.ppd*0.5;
        %p.stim.fix_rect = [cx-d, cy-d, cx+d, cy+d];
        I = cat(3, ones(h, w)*128, ones(h, w)*0);
        p.stim.square = Screen('MakeTexture', p.ptb.w, I);
        Screen('FrameRect', p.stim.square, [255, 255, 255], p.square, 2);
    end
    

    function p = make_sample_textures(p)
        tic;
        [~, hostname] = system('hostname');
        hostname = hostname(1:end-1);
        cachefile = sprintf('%s_nassar_sample_spec.mat', hostname);
        stimuli = {};
        if exist(cachefile, 'file')
            stimuli = load(cachefile);
            stimuli = stimuli.stimuli;
        else
            w = p.ptb.rect(3)-p.ptb.rect(1);
            h = p.ptb.rect(4)-p.ptb.rect(2);

            I = cat(3, ones(h, w)*0);
            noise = (double(rand(round(h), round(w))>0.5))*255;
            fprintf('Uniques....\n')
            unique(noise)
            for ii = 1:300
                txt = Screen('MakeTexture', p.ptb.w, I);
                Screen('TextSize', txt,  50);
                Screen('TextFont', txt, 'Courier');
                Screen('TextStyle', txt, 1);
                hpos = p.ptb.rect(2) + (p.ptb.rect(4)-p.ptb.rect(2))/2 + 10;
                %Screen('FillRect', txt , p.stim.bg, [] );
                DrawFormattedText(txt, sprintf('%03d', ii), 'center', hpos, [255, 255, 255], [],[],[],2,[]);
                imageArray= double(Screen('GetImage', txt));      
                
                b = double(mean(imageArray, 3)>128);           
                [w, h] = size(b);
                cx = w/2;
                cy = h/2;
                b = b(cx-200:cx+200, cy-200:cy+200);
                
                img_incl_alpha = cat(3, b.*noise(cx-200:cx+200, cy-200:cy+200), b*255);                
                stimuli{ii} = img_incl_alpha; %#ok<AGROW>
            end
            
            save(cachefile, 'stimuli', '-v7.3');
        end    
        %noise = (noise>mean(noise(:)));
        textures = [];
        target_rect = [1960/2-200, 1080/2-200, 1960/2+200, 1080/2+200];
        for ii = 1:300
            if mod(ii, 10)==0
                fprintf('.')
            end
            stim = stimuli{ii};
            %stim = cat(3, stim, (~(stim==128))*255);
            txt = Screen('MakeTexture', p.ptb.w, stim);
            textures = [textures, txt]; %#ok<AGROW>
        end
        fprintf('\n')
        p.stim.sample_textures = textures;
        toc;
    end

end