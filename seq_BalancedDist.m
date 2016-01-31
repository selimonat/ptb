function [final]=seq_BalancedDist(stim_seq , Categories)
%Distributes values in CATEGORIES,  in
%a balanced way to the stimulus sequence so that levels given in
%CATEGORIES are distributed in such a way that they are equally
%present in stimulus vector.
%CATEGORY is the thing that we want to distribute to the stimulus
%sequence in a balanced way. For example cross positions


tCategory      = length(Categories);%number of categories to be distributed
tSample        = length(stim_seq);%number of total trials
tcond          = length(unique(stim_seq));%number of stimulus conditions
%
%Category_index = Shuffle(1:tCategory,tCategory)';
% |-----tRepet----| * tCond
%[1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 ...]%stimulus id (STIM_SEQ)
%[A A A B B B C C C A A A B B B C C C ...]%categories  (SEQ2)
% |----SEQ--------| * tCategory

%Get SEQ
seq2 = [];
for cond = unique(stim_seq)
    %number of times each condition is repeated.
    tRepet   = sum(stim_seq == cond);
    seq  = [];
    for categorie = Categories
        seq      = [ seq repmat(categorie, 1, floor(tRepet./tCategory)) ];
    end
    
    %will add NaN's to the unbalanceable indices.
    if rem(tRepet,tCategory) ~= 0
        fprintf('Cannot deal perfectly, will try best...\n');
        fillup = tRepet - length(seq);
        seq = [ seq NaN(1,fillup) ];
    end
    %
    seq2 = [seq2 Shuffle(seq)];
end

%randomly fill the unbalancable trials. Would be just the perfect location
%to make a recursive function here.
if sum(isnan(seq2)) ~= 0;
    nani       = find(isnan(seq2));
    seq2(nani) = randsample(Categories,length(nani),true);
end
%
%order the stimulus and
[~, i] = sort(stim_seq);
%use the ordering index to align the SEQ variable
final = [];
final(i) = seq2;

    function shuffled = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:)';
    end
end



