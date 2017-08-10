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
fudge_factor = 0.7; % Determines by how much the instructed rule block 
                    % length should be shortened to account for illusionary block changes.
glaze_duration = 0.4;
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
                avg_trial_length = 7.; % 2 sec Stim (incl. resp) + 5s
                % Compute how long a rule is on display on average;
                %avg_glaze_block_length = duration_glaze* avg_trials + choice_length*(duration_glaze*avg_trials*Q_rate);
                avg_glaze_block_length = (1/hazard_rate) * glaze_duration * fudge_factor;
                trials_per_block = floor(avg_glaze_block_length/avg_trial_length);
                duration_per_block = trials_per_block*avg_trial_length;
                n_trials = round(block_length/avg_trial_length);               
                validities = [0, 1];
                % Account for switches which also have 5s ISI+2 on average.
                n_switches = floor(n_trials/(trials_per_block+1));
                [seq, es] = make_instructed_rule_onsets(600, validities, trials_per_block, duration);
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
            if p == 1
                blocks{block}.fmri = false;
            else
                blocks{block}.fmri = true;
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
        seq.isi2 = duration(1) + (duration(2)-duration(1)).*rand(1, trials);
        seq.jitter = 0.3 + 0.7*rand(1, trials);
        seq.isi = seq.isi-seq.jitter;
    end

    function [seq, es] = make_instructed_rule_onsets(block_duration, validities, block_length, duration)
        %% Makes a sequence of rules that change with a specific hazard rate.
        % validities = [0, 0.25, 0.75, 1];
        isi = duration(1) + (duration(2)-duration(1)).*rand;
        seq.block_type = 'IR';
        seq.stimulus_onset = isi;
        seq.type = 0;        
        seq.stim = nan;
        seq.rewarded_rule = binornd(1, 0.5, 1);
        es = [];
        %First determine stimulus onsets and number of trials
        cur_block = 1;
        while seq.stimulus_onset(end)<(block_duration-2)
            isi = duration(1) + (duration(2)-duration(1)).*rand;        
            if seq.stimulus_onset(end) + isi > block_duration-2                   
                break
            end
            seq.stimulus_onset = [seq.stimulus_onset (seq.stimulus_onset(end) + isi +2)];
            % Determine next trial type
            

            if cur_block == (block_length+1)
                cur_block = 0;
                seq.type = [seq.type 0];
                newset = setdiff(validities, seq.rewarded_rule(end));
                seq.stim = [seq.stim nan];
                rewarded_rule = binornd(1, newset, 1, block_length);
                seq.rewarded_rule = [seq.rewarded_rule, rewarded_rule];
            else
                seq.type = [seq.type 1];
                seq.stim = [seq.stim randi(2, 1, 1);];
                seq.rewarded_rule = [seq.rewarded_rule, seq.rewarded_rule(end)];
            end
            cur_block = cur_block +1;
            seq.stimulus_onset(end);
        end
              
    end

       
end