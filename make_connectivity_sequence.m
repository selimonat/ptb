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
duration_glaze = .4;
hazard_rate = 1/60;
Q_rate = 1/20;
stimuli = {};
choice_length = 3;

sigma = 1;
threshold = 0.5;


% Define sequence of blocks.
block_types = {...
    {'RW', 'IR', 'GL', 'GL', 'GL', 'GL', 'GL'},...
    {'RW', 'RR', 'RW', 'GL', 'GL', 'GL', 'IR', 'IR', 'T1'},...
    {'RW', 'RR', 'RW', 'GL', 'GL', 'GL', 'IR', 'IR', 'T1'}...
    };
           

for s = 1:ns
    stimuli{s} = {};

    for p = 1:3 % This iterates over sessions!       
        blocks = {};
        for block = 1:length(block_types{p})                
            type = block_types{p}(block);
                   
            if strcmp(type, 'IR') % Instructed rule
                % Match block length to hazard rate.
                avg_trials = 1/hazard_rate;
                avg_trial_length = 5.; %seconds
                % Compute how long a rule is on display on average;
                %avg_glaze_block_length = duration_glaze* avg_trials + choice_length*(duration_glaze*avg_trials*Q_rate);
                avg_glaze_block_length = 20;
                trials_per_block = floor(avg_glaze_block_length/avg_trial_length);
                n_trials = round(block_length/avg_trial_length);               
                validities = [0, 1];
                [seq, es] = make_instructed_rule_sequence(n_trials, validities, trials_per_block, duration);
                blocks{block} = seq; 
                
            elseif strcmp(type, 'GL')
                mean_duration = duration_glaze;                
                trials = ceil(block_length/mean_duration);
                dur_choice = Q_rate*trials * choice_length;
                trials = trials - (dur_choice/mean_duration);
                [seq, es] = make_glaze_sequence(hazard_rate, trials, threshold, sigma, Q_rate, [duration_glaze, duration_glaze]);
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

    
    function [seq, es] = make_glaze_sequence(hazard_rate, trials, threshold, sigma, Q_rate, duration)
        %% Makes a sequence of rules that change with a specific hazard rate.
        seq.sigma = sigma;
        seq.block_type = 'GL';
        seq.sample = [];
        seq.generating_side = [];
        seq.type = [];
        seq.isi = [];
        
        seq.stim = [];
        es = [];
        mean_inter_change_length = 1/hazard_rate;
        sides = [1, -1];
        side = randsample(sides, 1);
        cnt = 0;
        while length(seq.sample)<trials
            e = round(exprnd(mean_inter_change_length));
            if e <= 5 || e > (mean_inter_change_length*2)
                continue
            end
            for i = 1:e                
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  duration(1) + (duration(2)-duration(1)).*rand;
                seq.isi = [seq.isi, isi]; 
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt +1;
                if ((binornd(1, Q_rate) > 0.5) && (cnt > 10)) || (cnt > 20/.4)                    
                    seq.sample = [seq.sample, nan];
                    seq.generating_side = [seq.generating_side, side*threshold];
                    seq.type = [seq.type, 1];
                    seq.isi = [seq.isi, 2 + (3-2)*rand];
                    seq.stim = [seq.stim randi(2, 1)-1];
                    cnt = 0;
                end
            end
            side = side*-1;
            es = [es e]; %#ok<AGROW>
            
            
        end
     end

end