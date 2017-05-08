
function stimuli = make_connectivity_sequence(ns, trials)
duration = [2, 8];
hazard_rates = [1/60, 1/90];
Q_rate = 1/50;
stimuli = {};
choice_length = 3;
% Course of experiment:
% 1. Training, exp only
% 2. fMRI, E Q E Q E Q E Q E
% 3. Training, exp only
% 4. fMRI, E Q E Q E Q E Q E
% 5. Training, exp only
% 6. fMRI, E Q E Q E Q E Q E

for s = 1:ns
    stimuli{s} = {};
    if mod(s, 2)==0
        block_types = {'F', 'F', 'G', 'G', 'G', 'G'};
    else
        block_types = {'G', 'G', 'G', 'G', 'F', 'F'};
    end
    for p = 1:4 % This iterates over sessions!       
        blocks = {};
        hazard_rates = hazard_rates(randperm(2));
        for block = 1:length(block_types)            
            type = block_types(block);
            if p < 3
                hr = hazard_rates(1);
            else
                hr = hazard_rates(2);
            end
            
            if strcmp(type, 'F')
                % Match block length to hazard rate.
                avg_trials = 1/hr;
                avg_trial_length = 5.5; %seconds
                % Compute how long a rule is on display on average;
                avg_glaze_block_length = 0.25* avg_trials + choice_length*(0.25*avg_trials*Q_rate);
                block_length = round(avg_glaze_block_length/avg_trial_length);
                validities = [0, 1];
                [seq, es] = make_exp_sequence(trials, validities, block_length, duration);
                blocks{block} = seq; %#ok<AGROW>
            else
                mean_duration = .25;                
                trials = ceil(10*60/mean_duration);
                dur_choice = Q_rate*trials * choice_length;
                trials = trials - (dur_choice/mean_duration);
                [seq, es] = make_glaze_sequence(hr, trials, 1, 2, Q_rate);
                blocks{block} = seq;
            end
            
        end
        stimuli{s}{p} = blocks; %#ok<AGROW>
    end
end

    function [seq, es] = make_exp_sequence(trials, validities, block_length, duration)
        %% Makes a sequence of rules that change with a specific hazard rate.
        %validities = [0, 0.25, 0.75, 1];
        seq.block_type = 'Localizer';
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

    
    function [seq, es] = make_glaze_sequence(hazard_rate, trials, threshold, sigma, Q_rate)
        %% Makes a sequence of rules that change with a specific hazard rate.
        seq.sigma = sigma;
        seq.block_type = 'Glaze';
        seq.sample = [];
        seq.generating_side = [];
        seq.type = [];
        seq.isi = [];
        
        seq.stim = [];
        es = [];
        mean_inter_change_length = 1/hazard_rate;
        sides = [1, -1];
        side = randsample(sides, 1);
        while length(seq.sample)<trials
            e = round(exprnd(mean_inter_change_length));
            if e <= 5 || e > (mean_inter_change_length*2)
                continue
            end
            for i = 1:e                
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = round([seq.sample,samples]);
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  .2 + (.3-.2).*rand;
                seq.isi = [seq.isi, isi]; 
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                if binornd(1, Q_rate) > 0.5
                    seq.sample = [seq.sample, nan];
                    seq.generating_side = [seq.generating_side, side*threshold];
                    seq.type = [seq.type, 1];
                    seq.isi = [seq.isi, 2 + (3-2)*rand];
                    seq.stim = [seq.stim randi(2, 1)-1];
                end
            end
            side = side*-1;
            es = [es e]; %#ok<AGROW>
            
            
        end
     end

end