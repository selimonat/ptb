function stimuli = make_sequence(ns, mean_inter_change_length, trials)
stimuli = {};
for s = 1:ns
    stimuli{s} = {};
    for p = 1:6
        blocks = [];
        for block = 1:7
            es = 0;
            while abs(mean(es)-mean_inter_change_length) > 1
                [seq, es] = make_one_sequence(mean_inter_change_length, trials);
            end
            blocks = [blocks seq];
        end
        stimuli{s}{p} = blocks;
    end
end

    function [seq, es] = make_one_sequence(mean_inter_change_length, trials)
        %% Makes a sequence of rules that change with a specific hazard rate.
        seq.reward_probability = [];
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
            
            es = [es e];
        end
        
        seq.reward_probability = seq.reward_probability(1:trials);
        seq.isi = 2. + (8-2).*rand(1, trials);
    end
end