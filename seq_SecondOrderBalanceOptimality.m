function [o,n]=seq_SecondOrderBalanceOptimality(s,repeat)
%[o]=seq_SecondOrderBalanceOptimality(s,repeat)
% will return a value quantifying second order optimality of a sequence.

s = s(:);
%
tcond  = length(unique(s));
n      = hist3([s(1:end-1) s(2:end)],repmat(tcond,1,2));
% o      = sum(abs(n(:) - mean(n(:))));
o      = 100-std(n(:));
% o      = max(n(:));
fprintf('2nd order optimality of %g.\n',o);

