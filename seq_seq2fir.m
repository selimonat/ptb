function [X,CX,eff] = seq_seq2fir(s,nummods)

%%
s = s(:);
baseveclen = length(s)+nummods;
basevec    = s;
nevents    = max(unique(s));
order      = 3;
for k = 1:nevents
    thispattern = zeros(baseveclen,1);
    thispattern(find(basevec == k)) = 1;
    span = (1:nummods) + (k-1)*nummods;
    X(:,span) = toeplitz(thispattern,[thispattern(1) zeros(1,nummods-1)]);
end
%
X = demean(X);
%
% S  = legendremat(order,baseveclen );
% PS = eye(baseveclen)-S*pinv(S);
PS = eye(baseveclen);
K  = X'*PS*X;
CX = inv(K);
