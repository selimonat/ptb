function stimuli = make_sequence(ns, mean_inter_change_length, trials, reward_probabilities)
stimuli = {};

% Course of experiment:
% 1. Training, exp only
% 2. fMRI, E Q E Q E Q E Q E
% 3. Training, exp only
% 4. fMRI, E Q E Q E Q E Q E
% 5. Training, exp only
% 6. fMRI, E Q E Q E Q E Q E

for s = 1:ns
    stimuli{s} = {};
    for p = 1:6 % This iterates over days.
        if mod(p, 2) == 1   % Training session
            block_types = {'E', 'E', 'E', 'E', 'E', 'E', 'E'};
        else
            block_types = {'E', 'QA', 'E', 'QB', 'E', 'QA', 'E', 'QB', 'E'};
        end
        blocks = {};
        for block = 1:length(block_types)
            type = block_types(block);
            if strcmp(type, 'E')
                es = 0;
                while abs(mean(es)-mean_inter_change_length) > 1
                    [seq, es] = make_exp_sequence(mean_inter_change_length, trials);
                end
            else
                seq = make_Q_sequence(trials, type);
            end
            blocks{block} = seq; %#ok<AGROW>
            
        end
        stimuli{s}{p} = blocks; %#ok<AGROW>
    end
end

    function [seq, es] = make_exp_sequence(mean_inter_change_length, trials)
        %% Makes a sequence of rules that change with a specific hazard rate.
        seq.type = 'EXP';
        seq.reward_probability = [];
        seq.pRP = [];
        seq.stim = randi(2, 1, trials)-1;
        es = [];
        
        start = [0,1,2];
        nexts = [[1,2]; [0, 2]; [0,1]];
        
        while length(seq.reward_probability)<trials
            e = round(exprnd(mean_inter_change_length));
            if e <= 1 || e > 20
                continue
            end
            if numel(seq.reward_probability)==0
                next_rp = randsample(start,1);
            else
                next_rp = randsample(nexts(seq.reward_probability(end)+1,:), 1);
            end
            next_set = repmat(next_rp, 1, e);
            
            seq.reward_probability = [seq.reward_probability, next_set];
            es = [es e]; %#ok<AGROW>
        end
        
        seq.reward_probability = seq.reward_probability(1:trials);
        seq.isi = 2. + (8-2).*rand(1, trials);
        gv = [];
        for iii = 1:trials
            seq.pRP = [seq.pRP reward_probabilities(seq.reward_probability(iii)+1)];
            P = seq.pRP(iii);
            P = max(P, 1-P);
            gv = [gv binornd(1, P)]; %#ok<AGROW>
        end
        seq.give_reward = gv;
    end

    function [seq, es] = make_Q_sequence(trials, type)
        %% Makes a sequence with one rule active
        seq.type = type;
        if strcmp(type, 'QA')
            seq.reward_probability = 0*ones(1, trials);
        else
            seq.reward_probability = 2*ones(1, trials);
        end
        seq.stim = randi(2, 1, trials)-1;
        es = [];
        seq.isi = 2. + (8-2).*rand(1, trials);
        seq.give_reward = ones(1, trials);
    end
end