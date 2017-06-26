function stimuli = make_connectivity_sequence(ns, block_length)
%%
% Generate sequences for the complete connectivity experiment.
%
% Course of experiment:
% 1. Day 1. Phase 1. Behavioral only.
%    Start with block that makes rule associations clear. 
%
% 2. Day 2. Phase 2. fMRI:
%   Wedge, Ring, Wedge - 3x Inference, 2x Localizer, T1
%
% 3. Day 2. Phase 3. fMRI:
%   Wedge, Ring, Wedge - 3x Inference, 2x Localizer, TSE



duration = [2, 8];
hazard_rate = 1/70;
stimuli = {};


% Define sequence of blocks.
block_types = {...
    {'RW', 'IR', 'GL', 'GL', 'GL', 'GL', 'GL'},...
    {'RW', 'RR', 'RW', 'GL', 'GL', 'GL', 'IR', 'IR', 'T1'},...
    {'RW', 'RR', 'RW', 'GL', 'GL', 'GL', 'IR', 'IR', 'T1'}...
    };
           

for s = 1:ns % Iterates over subjects
    stimuli{s} = {};
    for p = 1:3 % This iterates over sessions!       
        blocks = {};
        for block = 1:length(block_types{p})                
            type = block_types{p}(block);
                   
            if strcmp(type, 'IR') % Instructed rule
                % Match block length to hazard rate.
                avg_trials = 1/hazard_rate;
                avg_trial_length = 7.; % 2 sec Stim (incl. resp) + 5s
                % Compute how long a rule is on display on average;
                %avg_glaze_block_length = duration_glaze* avg_trials + choice_length*(duration_glaze*avg_trials*Q_rate);
                avg_glaze_block_length = 1/hazard_rate;
                trials_per_block = floor(avg_glaze_block_length/avg_trial_length);
                n_trials = round(block_length/avg_trial_length);               
                validities = [0, 1];
                [seq, es] = make_instructed_rule_sequence(n_trials, validities, trials_per_block, duration);
                blocks{block} = seq; 
                
            elseif strcmp(type, 'GL')                
                [seq, es] = make_glaze_block(block_length);
                blocks{block} = seq; %#ok<*AGROW>
                
            else
                seq = struct();
                seq.block_type = type{1};
                seq.rule = mod(block, 2);
                blocks{block} = seq;
            end
            
        end
        
        stimuli{s}{p} = blocks; %#ok<AGROW>
    end
end

    function [seq, es] = make_instructed_rule_sequence(trials, validities, block_length, duration)
        %% Makes a sequence of rules that change with a specific hazard rate.
        %validities = [0, 0.25, 0.75, 1];
        seq.block_type = 'IR';
        seq.stim = randi(2, 1, trials)-1;
        es = [];
        seq.validity = repmat(randsample(validities, 1), 1, block_length);
        seq.onset = [1, zeros(1, block_length-1)];
        seq.rewarded_rule = binornd(1, seq.validity(end), 1, block_length);
        while length(seq.validity)<trials
            newset = setdiff(validities, seq.validity(end));
            if length(newset)>1
                vs = randsample(newset, 1);
            else
                vs = newset;
            end
            seq.validity = [seq.validity, repmat(vs, 1, block_length)];
            seq.onset = [seq.onset, 1, zeros(1, block_length-1)];
            rewarded_rule = binornd(1, vs, 1, block_length);
            seq.rewarded_rule = [seq.rewarded_rule, rewarded_rule];
        end
        seq.validity = seq.validity(1:trials);
        seq.isi = duration(1) + (duration(2)-duration(1)).*rand(1, trials);
        seq.jitter = 0.3 + 0.7*rand(1, trials);
        seq.isi = seq.isi-seq.jitter;
    end

       
end