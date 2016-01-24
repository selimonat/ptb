%we have three types of mesoblocks (3 microblocks) depending on where the
%UCS is occuring: in the first, second or third microblocks of a mesoblock.
%
%The matrix below indicates the distance between UCS microblocks for all
%possible transitions of mesoblocks. so for example the transition from
%mesoblock 3 to 1 results in two successive microblocks.
% t = [ 2 3 4;...
%       1 2 3;...
%       0 1 2];
t = [ 3 4 5 6; 2 3 4 5; 1 2 3 4; 0 1 2 3]
%%now we will go select elements from this matrix in such a way to obtain a
%%sequence of mesoblocks which will be balanced in terms of transitions.
T      = t;
store  = [];
dstore = [];
n      = 0;
ok     = 10000;
tseq   = 20;
%
while ok
    %%
    %build a sequence by randomly walking on this matrix and cancelling the
    %past steps so that they are not again stepped in
    now            = 4;%start with a mesoblock where UCS is last one;
    seq            = now;
    distz          = [];    
    for nseq = 1:tseq
        T          = t;        
        while any(~isnan(T(now,:)))
            next             = find(~isnan(T(now,:)));
            next             = RandSample(next,[1 1]);
            distanz          = T(now,next);
            T (T == distanz) = NaN;
            seq              = [seq next];
            distz            = [distz distanz];
            now              = next;
        end
    end            
    %
%     ml = max(ml,length(seq))
    %well if the sequence has the proper length, this means we have
    %succeeded without entering into an impasse.
    if length(seq) == length(unique(t(:)))*tseq+1
        %if this is the first time a sequence is found
        if isempty(store)
            store = seq;
        end
        %don't store this sequence if we had it already.
        if ~any(ismember(store,seq,'rows'))
            ok         = ok - 1;
            store      = [store ;seq];
            dstore     = [dstore    ;distz];
            fprintf('Found already %d sequences.\n',size(store,1));
        end
    end
end
% transform mesoblock seq to a stim sequence
repeat = 1;
while repeat
    seq        = [];
    csp        = 4;
    macroblock = [];
    isi        = [];
    
    for meso_id = store(randsample(size(store,1),1),:);
        %build a mesoblock
        mesoblock = [];        
        n          = max(store(:));%length of a mesoblock
        while n
            n         = n - 1;
            micro     = Shuffle(0:8);                      
            mesoblock = [mesoblock micro];
        end
        isi                                            = [isi seq_BalancedDist(mesoblock,[3 4.5 6])];
        mesoblock(max(find(mesoblock == csp,meso_id))) = 9;%assign UCS
        macroblock                                     = [macroblock  mesoblock];
    end
    %constrains
    if 1
        %         macroblock(1:100) == 9
        repeat = 0;
    end
end
run_length = length(macroblock)./3;
length(macroblock)*mean(isi)/60
mean(isi)
plot(macroblock,'o-')
%%
% macroblock(RandSample(find(macroblock == 9),[1 3])) = 10;


%% much simpler approach
csp            = 6;
cond_id            = [];
n_micro        = 0;
n_meso         = 0;
n_micro_ucs    = 0;
n_micro_odd    = 0;
condpool       = 0:8;
%
meso_i = find(store(:,2) == 1 & store(:,18) == 4,1);
meso_sequence  = [store(meso_i+1,:)];
%
isi = [];
while length(cond_id) < length(unique(condpool))*64
    n_meso = n_meso + 1;
    fprintf('mesosequence: %g\n',n_meso)
    meso   = [];
    for n = 1:4;
        n_micro = n_micro + 1;        
        if n == meso_sequence(1,n_meso)%this is a UCS microblock
            meso_sequence(1,n_meso)
            micro     = [csp Shuffle(setdiff(condpool,csp))];
            micro(1)  = 9;
        else
            micro   = Shuffle(condpool);
        end
        meso    = [meso micro];        
    end
    cond_id  = [cond_id meso];
    isi  = [isi seq_BalancedDist(meso,[3 4 5 6])];
end
cond_id = [Shuffle(condpool)                     cond_id];
isi = [seq_BalancedDist(condpool,[3 4 5 6])  isi]
cond_id(find(cond_id == 9,1,'last')) = 10;
cond_id(max(find(cond_id == 9,2,'first'))) = 10;
for n = 0:10;fprintf('%g: %g\n',n,sum(cond_id== n));end
fprintf('seq is %g minutes long and has %g trials...\n',length(cond_id)*4.5/60,length(cond_id));
fprintf('There are a total %g microblocks and %g UCS microblocks\n',length(cond_id)./9,sum(cond_id == 9))
plot(cond_id,'o-')

%%
seq.cond_id       = cond_id;
seq.isi           = isi;
seq.ucs           = cond_id == 9;
seq.oddball       = cond_id == 10;
seq.stim_id       = seq.cond_id;
seq.stim_id(seq.ucs)     = csp;
seq.stim_id(seq.oddball) = 9;
seq.tTrial        = length(seq.cond_id);
seq.dist          = MinimumAngle((seq.stim_id-1)*45,(csp-1)*45);
for ncond = unique(cond_id)
    i                    = find(cond_id == ncond);
    cp                   = seq_BalancedDist(ones(1,length(i)),[1 2]);
    seq.CrossPosition(i) = cp;
end
save([fileparts(which('exp_FearAmy.m')) '/bin/fearamy_seq.mat'],'seq');