function [p]=seq_feargen_getprobability(rr,oddball)
%[p]=seq_feargen_getprobability(rr,oddball)
%
%   Will return a vector of probabilities as a function of reinforcement
%   and oddball rates, assuming there are 9 (8 face +1 null) conditions.
%   p*total_trial would return the number of required trials to maintain a
%   desired number of trials.
%
%   Use together with seq_feargen_FirstOrderBalanced.


%equatiom to solve following discussion with LK
%1 = 9p + rr./(1-rr)*p + ro; (nothing magic).
%p = 1/sum(....)

%a function handle to get to the number of UCSs to present given a rate and
%knowledge about csp.
f = @(csp,p) p*csp./(1-p);

p     = (1-oddball)./(9+rr./(1-rr));%solve for p
p     = [repmat(p,1,9)  p*f(1,rr) oddball];%return a vector of p

fprintf('p sums to %g...\n',sum(p))






