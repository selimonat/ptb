%so an initial guess for duration would be 900 seconds at an ISI of 3. This
%corresponds to ~ 300 trials and 15 minutes. RR is 0.25 and RO 0.01-0.03,
%there shouldn't be more than 3 oddballs, I think 2 is a good choice.

%% test how duration influences efficiency on a random sequence.
clear i;
for t = 20:10:1000;
    s = seq_feargen_FirstOrderBalanced(t,.5,.5);%create a sequence
    i(t/10-1)=seq_feargen_information(s);%get the efficiency.
end
figure(1001);
plot(20:10:1000,[i(:).eff_norm],'o-')
xlabel('#trial')
ylabel('normalized efficiency')
% Conclusion: Efficiency increases initially very fast but then slows
% downs. This is expected given that long sequences are more likely to
% reduce orthogonality. we should not present less then 300-350 trials.
% This speaks against having a sequence of [ones(1,9)*3 1 1] but rather
% [ones(1,9)*4 1 1] (see the difference of 3 vs. 4?).

%% TEST EFFICIENCY OF DIFFERENT SEQUENCES CREATED WITH DIFFERENT FLAVOURS
clear info
%set the repvec
rep_vec = [ones(1,9)*3 1 1];
%create a dummy seq to get the number of trials, that will be used to
%create a random signal with the same number of trials.
dummy_seq = seq_SecondOrderBalancedSequence(rep_vec,1)-1;
ttrial    = length(dummy_seq);
n    = 1;
while n <= 1000
    s         = seq_feargen_FirstOrderBalanced(ttrial,pr,po);
    info(1,n) = seq_feargen_information(s,[0 0]);%[0 0] no visuals, no verbose
    %    
    s         = seq_SecondOrderBalancedSequence(rep_vec,1)-1;
    info(2,n) = seq_feargen_information(s,[0 0]);    
    %
    n         = n + 1;
end
% concat all
e = [info(1,:).eff_norm ;info(2,:).eff_norm]';
figure(2001);subplot(1,2,1);hist(e,20);subplot(1,2,2);boxplot(e);
% random sequence of length 365 is a bit more efficient than its comparable
% secondorder balanced sequences generated with [ones(1,9)*4 1 1]. (shit!).
% ~365 is relatively long, so testing it with a sequence of 280 trials
% ([ones(1,9)*3 1 1]) gives the opposite result. This means that second
% order balancing helps when the sequence length is short. For longer
% sequences it doesn't matter sooo much.
%% What about an pruned mseq with comparable event probability? 
% For this I generate an mseq of base 11, with power of 2 to get a seq of
% 120 and I concat it to get 240 or 360. 
%the following shows that non-pruned m-seq is quiet efficient.
s = [];
for n = 1:3
    s = [s; mseq2(11,2,0,randsample(1:18,1))];
end
seq_feargen_information([s])
%prune
pr       = .25;
po       = .01;
[s]=seq_prune_any(s,pr,po);
seq_feargen_information([s])
%% so now do the same efficiency test but include also mseq pruned.
%
% second order sequence can be either 285 or 365 trial long. mseq after
% pruning is about 305. So when length is considered m-seq will be most
% handicapped.
clear info
%set the repvec
rep_vec = [ones(1,9)*4 1 1];
%create a dummy seq to get the number of trials, that will be used to
%create a random signal with the same number of trials.
dummy_seq = seq_SecondOrderBalancedSequence(rep_vec,1)-1;
ttrial    = length(dummy_seq);
pr        = .25;
po        = .0033;
n         = 1;
while n <= 500
    %    1st order
    s         = seq_feargen_FirstOrderBalanced(ttrial,pr,po);
    info(1,n) = seq_feargen_information(s,[0 0]);
    %    2nd order
    s         = seq_SecondOrderBalancedSequence(rep_vec,1)-1;
    info(2,n) = seq_feargen_information(s,[0 0]);    
    %    pruned mseq
    s = [];
    for N = 1:3
        s = [s; 0; mseq2(11,2,0,randsample(1:18,1))];
    end
    [s]=seq_feargen_prune(s,pr,po);
    info(3,n) = seq_feargen_information(s,[0 0]);
    %   
    n         = n + 1
end
%% concat all the efficiencies
e = [info(1,:).eff_norm ;info(2,:).eff_norm ;info(3,:).eff_norm]';
figure(2001);subplot(1,2,1);hist(e,20);subplot(1,2,2);boxplot(e);
%good!!! we are getting there, the pruned mseq is better than both of the
%sequences in terms of their efficiency.
%% ok now let's look at the Kao's toolbox.

%% and finally we look at the optseq2 program 
clear info
basepath = '/Users/onat/Desktop/optseq/';
suffix   = 'fg-*';
files    = ListFiles(sprintf('%s%s*',basepath,suffix))';
n        = 0;
for f = files
    n = n + 1;
    s         = seq_feargen_FirstOrderBalanced(298,pr,po);%298 is same length as optseq
    info(1,n) = seq_feargen_information(s,[0 0]);
    %
    [s] = seq_optseq22s(sprintf('%s%s',basepath,f{1}));
    info(2,n) = seq_feargen_information(s,[0 0]);    
end
e = [info(1,:).eff_norm ;info(2,:).eff_norm]';
hist(e)
%well this graph shows us that the optseq performs about 70-75% level,
%sofar the worst choice. Sadly for optseq it performs worst than balanced
%random.







