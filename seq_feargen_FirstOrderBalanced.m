function [s] = seq_feargen_FirstOrderBalanced(ttrial,rr,ro)
%s = seq_feargen_FirstOrderBalanced(ttrial, rr,ro);
%
%   Generates a random sequence of conditions which follows the probability
%   of occurances in P, The sequence has a length of TTRIAL. P can be of
%   any size. P must sum to 1. RR and RO are reinforcement and oddball
%   rates, respectively. Due to rounding off errors the required TTRIAL.
%
%   See also: seq_SecondOrderBalanced



%% get probability vector
p      = seq_feargen_getprobability(rr,ro);
ntrial = round(p*ttrial);
fprintf('Total number of trials: %g (wanted %g) \n',sum(ntrial),ttrial);

%% now create a block vector for all conditions and finally randomize it...
s = [];
for ncond = 1:length(p)
    s = [s;repmat(ncond-1,ntrial(ncond),1)];%-1 because of null trial;
end
s = Shuffle(s);