function [seq] = seq_StimDiff_pairwise
%function [seq] = seq_StimDiff_pairwise
%
%generates stimlists for every possible CS+ beforehand. Could be also done
%online but this is more convenient. To be used by
%"exp_StimDiff_pairwise.m"
%
%22.02.2018 - Lukas Neugebauer
%23.02.2018 - some minor updates and changed the name since it's no longer
%a MLDS task. Used to be called "seq_MLDS_pairwise.m"

    path.stimlist   = [fileparts(which('seq_StimDiff_pairwise.m')),filesep,'bin',filesep];
    path.file       = [path.stimlist,'stimPerCSP_equi.mat'];
    path.save       = [path.stimlist,'sequences_StimDiff'];
    
    load(path.file);
    WaitSecs(1); %will report an error otherwise

    if  exist('s','var') ~= 1
        disp('something went wrong');
        keyboard;
    end

    nstim       = size(s.stimlist,1); %how many stimuli?
    nposscomb   = size(nchoosek(1:nstim,2)) + nstim; %how many possible combinations?
    nreps       = 100; %how many versions per cs+?
    nruns       = 2; %how many times are all possible combinations shown?
    
    seq.sequence    = [];
    seq.stimlist    = [];

    for ii  = 1:size(s.stimlist,2) %loop over possible CS+ faces
        %dummy for list per cs+
        list    = s.stimlist(:,ii);
        fprintf('Processing potential CS+ #%d: %2d\n',ii,list(1));
        prestimlist     = [nchoosek(list,2);repmat(list,1,2)];
        for iii = 1:nreps
            dummy   = zeros(size(prestimlist,1),size(prestimlist,2),nruns);
            for iiii = 1:nruns
                %get combinations
                dummy(:,:,iiii)  = prestimlist;
                %switch columns for random half of the list
                switchInd   = false(size(prestimlist,1),1); %which rows to switch columns
                switchInd(datasample(1:size(prestimlist,1),floor(size(prestimlist,1)/2),'replace',false)) = true;
                [dummy(switchInd,2,iiii),dummy(switchInd,1,iiii)] = deal(dummy(switchInd,1,iiii),dummy(switchInd,2,iiii));
                %randomize rows
                dummy(:,:,iiii)  = dummy(randperm(size(dummy,1)),:,iiii);
            end
            dummy   = [dummy(:,:,1);dummy(:,:,2)];
            %put it into the big structure and move on 
            seq(iii,ii).sequence    = dummy;
            seq(iii,ii).stimlist    = sort(list);
            seq(iii,ii).nTrials     = size(dummy,1);
        end
    end
    save(path.save,'seq');
end