function [s]=seq_feargen_mseq_pruned(method,pr,po)
%1: concat power 2 and then prune
%2: same as 1 but null it instead of pruning
%22: same for conditioning
%3: generate power 3 and the prune
%4: same as 3 but null it instead of pruning


if method == 1  
    %% will prune a 360 trial long mseq, the result is a bit longer than 300 but comparable
    s   = [];
    for n = 1:3
        s = [s; mseq2(11,2,0,RandSample(1:18,[1 1]))];
    end                    
    [s] = seq_feargen_prune(s,pr,po);
    
elseif method == 2
    %% will zero all the unnecessary trials, the result is 240 trial long and extremely efficient. 
    %% maybe this is the one I am looking since ages now ;)
    
    %%use this if you want to combine two shorter seqs into one
    %     s = [];
    %     for n = 1:2
    %         s = [s; mseq2(11,2,RandSample(1:100,[1 1]),RandSample(1:18,[1 1]))];
    %     end
    [s]    = mseq2(11,2,RandSample(1:100,[1 1]),RandSample(1:18,[1 1]));
    [s]  = seq_feargen_prune(s,pr,po,0);
    %seq_feargen_information(s);
    
elseif method ==22;
    %this is for conditioning
     [s]  = mseq2(5,3,RandSample(1:100,[1 1]),RandSample(1:18,[1 1]));
     [s]  = seq_feargen_prune(s,pr,po,0);
     %seq_feargen_information(s);
     
elseif method == 3
    %WORK to be done: GET AN M-sequence and equalize the transition to UCS
    %and ODDBALL trials that is it.
    s    = mseq2(11,3,0,RandSample(1:18,[1 1]));
    [s]  = seq_feargen_prune(s,pr,po,0);        
    s    = s(1:300);
elseif method == 4
    
end