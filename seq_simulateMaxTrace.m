%%
N       = 1000;
nevent  = 1;
trep    = 1;
pc      = 0;
t       = [];
t2      = [];
s       = [];
ps      = linspace(.01,.99,50);
for p = ps
    pc  = pc + 1;
    rep = 0;
    while rep < trep
        X           = [ kron(eye(nevent) , ones(round(N*p),1)) ; zeros(round(N*(1-p)),nevent) ];
        X           = demean(X);
        CX          = X'*X;
        imagesc(X);drawnow;
%         if rank(CX) == size(CX,2)
            rep          = rep + 1;
            t(pc)    = trace(inv(CX));            
%         end
    end
end
plot(ps , 1./t);
