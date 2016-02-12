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
ok     = 1000;
tseq   = 20;
%
while ok
    %
    %build a sequence by randomly walking on this matrix and cancelling the
    %past steps so that they are not again stepped in
    now            = 4;%start with a mesoblock where UCS is last one;
    seq            = now;
    distz          = [];
    for nseq = 1:tseq
        T          = t;%transition matrix that will be reduced again and again.
        while any(~isnan(T(now,:)))
            next             = find(~isnan(T(now,:)));%next posibilities
            next             = RandSample(next,[1 1]);%select one
            distanz          = T(now,next);
            T (T == distanz) = NaN;%cancel all transitions with this distance
            seq              = [seq next];
            distz            = [distz distanz];
            now              = next;            
        end
    end    
    %
    %well if the sequence has the proper length, this means we have
    %succeeded without entering into an impasse.
    if length(seq) == length(unique(t(:)))*tseq+1
        %if this is the first time a sequence is found
        if isempty(store)
            store  = seq;
            dstore = distz;
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
%% much simpler approach

for nsub = 1:100;
    for csp            = 1:8;
        cond_id        = [];
        mblock         = [];
        n_micro        = 1;
        n_meso         = 0;
        n_micro_ucs    = 0;
        n_micro_odd    = 0;
        
        condpool       = 0:8;
        %
        %all mesoblocks where second microblock is of type 1 and 18th microblock of type 4...
        %these will be later set to oddball...
        meso_i         = find(store(:,2) == 1 & store(:,18) == 4,1);
        meso_sequence  = [store(meso_i,:)];%all experiments will be based on this meso_sequence, so that UCS events are delivered with the same pace to all subjects.
        
        [meso_sequence;[NaN dstore(meso_i,:)]]
        %
        isi = [];
        %
        for n_meso = 1:16;%8 mesoblock balances all UCS to UCS distances. 16 too.
            %16x9=144 microblocks = 576 trials
            fprintf('mesosequence: %g\n',n_meso)
            trials = [];%reset it...
            for n  = 1:4;%expand the current mesoblock to 4 microblocks.
                n_micro = n_micro + 1;%global microblock counter
                if n == meso_sequence(1,n_meso)%this is a UCS microblock
                    micro     = [csp Shuffle(setdiff(condpool,csp))];
                    micro(1)  = 9;
                else
                    micro     = Shuffle(condpool);
                end
                trials        = [trials micro];
                mblock        = [mblock repmat(n_micro,1,9)];%this will count from 2 on, but the 1st microblocks will be aded later
            end
            cond_id  = [cond_id trials];
            isi      = [isi     seq_BalancedDist(trials,[3 4 5 6])];
        end
        %
        cond_id = [Shuffle(condpool) cond_id];%add one more microblock for the baseline
        isi     = [seq_BalancedDist(condpool,[3 4 5 6])  isi];%assign ISI for these
        mblock  = [repmat(1,1,9) mblock];%and increment the micro_block index
        %assign oddballs
        cond_id(find(cond_id == 9,1,'last')) = 10;%last UCS turned to ODD
        cond_id(max(find(cond_id == 9,2,'first'))) = 10;%second UCS turned to ODD
        for n = 0:10;fprintf('%g: %g\n',n,sum(cond_id== n));end
        fprintf('seq is %g minutes long and has %g trials...\n',length(cond_id)*4.5/60,length(cond_id));
        fprintf('There are a total %g microblocks and %g UCS microblocks\n',length(cond_id)./9,sum(cond_id == 9))
        seq_information(cond_id,isi)
        % put the data to format usable by the presentation script.
        seq2 = [];
        seq2.cond_id              = cond_id;
        seq2.mblock               = mblock
        seq2.isi                  = isi;
        seq2.ucs                  = cond_id == 9;
        seq2.oddball              = cond_id == 10;
        seq2.stim_id              = seq2.cond_id;
        seq2.stim_id(seq2.ucs)     = csp;
        seq2.stim_id(seq2.oddball) = 9;
        seq2.tTrial               = length(seq2.cond_id);
        seq2.dist                 = MinimumAngle((seq2.stim_id-1)*45,(csp-1)*45);
        seq2.dist(seq2.cond_id==0)=NaN;
        %oddball=1000
        seq2.dist(seq2.cond_id==max(seq2.cond_id))=1000;
        %ucs=500
        seq2.dist(seq2.cond_id==max(seq2.cond_id)-1)=500;
        seq2.CrossPosition        = ones(1,seq2.tTrial);
        %
        seq(nsub,csp) = seq2;
    end
end
%%

save([fileparts(which('exp_FearAmy.m')) '/bin/fearamy_seq.mat'],'seq');