function [seq, es] = make_glaze_block(block_length)
duration = [2, 8];
duration_glaze = .4;
hazard_rate = 1/70;
Q_rate = 1/35;
sigma = 1;
threshold = 0.5;

% Compute number of trials necessary for specific block length.
mean_duration = duration_glaze;                
trials = ceil(block_length/mean_duration);
[seq, es] = make_glaze_sequence(hazard_rate, block_length, threshold, sigma, Q_rate, [duration_glaze, duration_glaze]);

 function [seq, es] = make_glaze_sequence(hazard_rate, block_length, threshold, sigma, Q_rate, duration)
        %% Makes a sequence of rules that change with a specific hazard rate.        
        seq.sample = [];
        seq.generating_side = [];
        seq.type = [];
        %seq.isi = [];
        seq.stimulus_onset = [0];
        seq.stim = [];
        es = [];
        mean_inter_change_length = 1/hazard_rate;
        sides = [1, -1];
        side = randsample(sides, 1);
        cnt = 0;
        last_choice = false;
        while seq.stimulus_onset(end)<block_length
            %e = round(exprnd(mean_inter_change_length));
            %if e <= 5 || e > (mean_inter_change_length*2)
            %    continue
            %end
            e = exprndtrunc(mean_inter_change_length, 5, 2*mean_inter_change_length);
            for i = 1:e                
                samples = (randn(1, 1)*sigma + side*threshold);
                seq.sample = [seq.sample,samples];
                seq.generating_side = [seq.generating_side, side*threshold];
                % Sample spacing is between 200 and 300ms.
                isi =  duration(1) + (duration(2)-duration(1)).*rand;
                %seq.isi = [seq.isi, isi]; 
                %if last_choice
                %    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                %    last_choice = false;
                %else
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end)+isi];
                %end
                seq.type = [seq.type, 0];
                seq.stim = [seq.stim nan];
                cnt = cnt +1;
                
                if ((binornd(1, Q_rate) > 0.5) && (cnt > 10)) || (cnt > 20/.4)                    
                    seq.sample = [seq.sample, nan];
                    seq.generating_side = [seq.generating_side, side*threshold];
                    seq.type = [seq.type, 1];
                    %seq.isi = [seq.isi, isi];
                    seq.stimulus_onset = [seq.stimulus_onset, seq.stimulus_onset(end) + 2 + isi + (3-2)*rand];
                    seq.stim = [seq.stim randi(2, 1)-1];
                    cnt = 0;
                    last_choice = true;
                end
            end
            side = side*-1;
            es = [es e]; %#ok<AGROW>                        
        end
        idx = seq.stimulus_onset < block_length;
        fields = fieldnames(seq);
        for field = 1:length(fieldnames(seq))
            k = seq.(fields{field});
            seq.(fields{field}) = k(idx);
        end
        seq.sigma = sigma;
        seq.block_type = 'GL';
    end

end

