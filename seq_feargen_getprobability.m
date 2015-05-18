function [p,p2]=seq_feargen_getprobability(rr,oddball)
%[p,p2]=seq_feargen_getprobability(rr,oddball)
%
%   Will return a vector of probabilities in P as a function of reinforcement
%   and oddball rates, assuming there are 9 (8 face +1 null) conditions.
%   p*total_trial would return the number of required trials to maintain a
%   desired number of trials. P2 is the same but probabilities are computed
%   without taking null condition into account.
%
%   Use together with seq_feargen_FirstOrderBalanced.


%equatiom to solve following discussion with LK
%1 = 9p + rr./(1-rr)*p + ro; (nothing magic).
%p = 1/sum(....)

%a function handle to get to the number of UCSs to present given a rate and
%knowledge about csp.
f = @(csp,p) p*csp./(1-p);

p = (1-oddball)./(9+rr./(1-rr));%solve for p
p = [repmat(p,1,9)  p*f(1,rr) oddball];%return a vector of p


%do the same without the null condition
p2 = (1-oddball)./(8+rr./(1-rr));%solve for p
p2 = [repmat(p2,1,8)  p2*f(1,rr) oddball];%return a vector of p








