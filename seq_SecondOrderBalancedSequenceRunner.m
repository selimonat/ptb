function [out]=SecondOrderBalancedSequenceRunner(total,repeatvector)
%[out]=SecondOrderBalancedSequenceRunner(total,repeatvector)
%
% will return TOTAL amount of second order balanced stimulus sequences/
% Use these possibilities for RepetVector = {[4 4 4 4 4 4 4 4 1 1] [28 28
% 2]} for test and conditioning phases.
%
% Selim Onat, 26-Apr-2013 12:47:55

%%
rng('shuffle');%shuffle the random generator to a different state.

I     = single(zeros(10,10,4,total));
S     = uint8(zeros(293,total));

matlabpool local 6;

parfor ncount = 1:total
    fprintf('%06d\n',ncount);
    [s,i]           = SecondOrderBalancedSequence( 10, repeatvector, randsample(1:8,1) );
    S(:,ncount)     = uint8(s(:));
    I(:,:,:,ncount) = single(i);
end
%
out.S            = S;
out.I            = I;
out.repeatvector = repeatvector;
save(['~/tmp/BigPool_' GetHostName '.mat'],'out');