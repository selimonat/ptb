function s = seq_FirstOrderBalanced(ttrial, p)
%s = seq_FirstOrderBalanced(p)
%
%   Generates a random sequence which follows the probability of occurances
%   in P. P can be of any size. P must sum to 1.

if sum(p) ~= 1

    p = round(p*100);

else
    fprintf('P must sum to one, now it is %g.\n', sum(p));

end

