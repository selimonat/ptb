
function stimuli = make_immuno_sequence(ns, block_length)
%%
% One tral is:
%   Prediction -> [wait] -> sample -> [wait] -> next trial
% Nassar has:
%   [unknown]  -> [0]    -> [2s]   -> [0]    ->
% ns                        : number subjects
% mean_inter_change_length  : 1/(hazard rate)
% trials                    : number of trials
% sigma                     : width of samples in degree
% pred_to_sample            : [low, high] time between prediction and
%                             sample
% sample_to_pred            : [low, high] time between sample and
%                             prediciton.
% ps                        : [p prediction, p choice, p sample_only]

stimuli = {};

NS_mean_inter_change_length = 10;
NS_sample_duration = 3;
NS_sigma = 5;

% Define sequence of blocks.
block_types = {...
    {'GL', 'GL', 'GL', 'GL', 'GL', 'GL', 'GL'},...
    {'NS', 'NS', 'NS', 'NS', 'NS', 'NS', 'NS'},...
    {'GL', 'GL', 'GL', 'GL', 'GL', 'GL', 'GL'},...
    {'NS', 'NS', 'NS', 'NS', 'NS', 'NS', 'NS'},...
    {'GL', 'GL', 'GL', 'GL', 'GL', 'GL', 'GL'},...
    {'NS', 'NS', 'NS', 'NS', 'NS', 'NS', 'NS'},...
    };
         

for s = 1:ns % Iterates over subjects
    stimuli{s} = {};
    for p = 1:6 % This iterates over sessions!       
        blocks = {};
        for block = 1:length(block_types{p})                
            type = block_types{p}(block);           
            if strcmp(type, 'NS')      
                avg_duration = NS_sample_duration + 2;
                num_trials = block_length/avg_duration;
                [seq, es] = make_nassar_sequence(NS_mean_inter_change_length, num_trials);
            elseif strcmp(type, 'GL')
                [seq es] = make_glaze_block(block_length);
            end
            blocks{block} = seq; %#ok<AGROW>
            blocks{block}.fmri = false; %#ok<AGROW>
            
        end
        stimuli{s}{p} = blocks; %#ok<AGROW>
    end
end

   

    function [seq, es] = make_nassar_sequence(mean_inter_change_length, trials)
        %% Make a sequence of random numbers drawn from a normal distribution,
        %  where the mean changes on average every
        %  mean_inter_change_length
        seq.block_type = 'NR';
        seq.sigma = NS_sigma;
        seq.sample = [];
        seq.mu = [];
        seq.stim = randi(2, 1, trials)-1;
        es = [];        
        while length(seq.sample)<trials
            e = exprndtrunc(mean_inter_change_length, 3, 5*mean_inter_change_length);
            mu = (rand()*300);            
            seq.sample = round([seq.sample, randn(1,e)*NS_sigma + mu]);
            seq.mu = [seq.mu, repmat(mu, 1, e)];
            es = [es e]; %#ok<AGROW>
        end
        seq.mu = seq.mu(1:trials);
        seq.sample = seq.sample(1:trials);
        seq.isi = 0;%duration(1) + (duration(2)-duration(1)).*rand(1, trials);
        seq.jitter = 0.3 + 0.7*rand(1, trials);
        seq.isi = seq.jitter;
        seq.sample_duration = 0*seq.isi + NS_sample_duration;
    end


  
end