function [ucs]=BalancedUCSSelection(seq,nRepetition,rr,cs)
%[ucs]=BalancedUCSSelection(seq,nRepetition,tStim,rr,cs)
%
%   From a second order balanced stimulus sequence SEQ with NREPETITION and
%   TSTIM different stimuli, it select those CS stimuli so that the
%   following stimulus id is always balanced. RR is the reinforcement
%   rating.
%   
%
%   See also: SecondOrderBalancedSequence
%
%   Selim Onat, 15-May-2012 23:12:03
tStim       = length(unique(seq));
%
SelectionMatrix = [];
for ns = 1:tStim
    t = Shuffle(1:nRepetition);
    SelectionMatrix = [SelectionMatrix t'>(nRepetition*(1-rr))];
end
%Will contain the indices of transitions FROM 2 to the Column index.
TransitionMatrix = zeros(nRepetition,tStim);
i  = find(seq == cs);
%following stimulus... %Y will contain sorted next stimuli, this will be something like [1 1 1 1..
%, 2 2 2 2 2..., 3 3 3 3 3..., ...]. IND will contain the trial indices of
%these sorted presentation. This is just a trick so that
[y ind] = sort(seq(i+1));
%%all the entries in TRANSITIONMATRIX are the indices of CS stimuli, these
%are reshaped so that the indices in the Nth column correspond to the
%indices of CS trials where the next stimuli is N.
TransitionMatrix(1:end) = i(ind);
%
ucs_ind = TransitionMatrix(logical(SelectionMatrix));
%this will be the output a logical array with 1s where the shock has 2 be
%delivered.
ucs = zeros(1,length(seq));
ucs(ucs_ind) = 1;

