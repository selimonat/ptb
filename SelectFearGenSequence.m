function [seq]=SelectFearGenSequence(out)
%[seq]=SelectFearGenSequence(out)
%
%   Create a sequence file that is used by the Feargen stimulus presentation
%   function. 
%
%
%   Selim Onat, 27-Apr-2013 12:16:01




total_sequence    = 10;%it will return a total of 10 sequences for each face
isis              = [1 2 3];%in units of TRs
tisis             = length(isis);
%
%contains the pool of possible sequences (see SecondOrderBalancedSequence
%script);
pool              = out.S;
%contains the location of transitions
order             = [];
%load
tFace             = 8;
tCond             = length(unique(pool(:,1)));
tTrial            = size(pool,1);
tTrainTrial         = 9;%number of training trials.
%
randgen_uniform     = @(n,mini,range) rand(1,n).*range+mini;
prestim             = 0.5;%This is not being used anymore.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%this is the matrix where for each transition possible ISIs are presented.
for c = 1:10
    unbalanced(:,c)          = circshift( [1 2 3 1 2 3 1 2 ]',[c-1 0]);
end
isi_mat = [];
isi_mat = cat(3, unbalanced, ones(8,10), ones(8,10)*2, ones(8,10)*3);
%now add the transitions from the shock
isi_mat = [isi_mat ; cat(3,repmat(3,[2 10]), nan(2,10,3)) ];
isi_mat(:,9:10,2:end) = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%run across all possible sequences.
counter_condition = zeros(1,8);%will iterate with each acceptance.
counter           = 0;
for ns = 1:size(pool,2);    
    %
    stim_id           = pool(:,ns);
    ucs               = stim_id == 9;
    oddball           = stim_id == 10;
    %
    if EqualHalfBalancing(ucs) && Consecutiveness(ucs,3) && ExcludeEvent(ucs,0.9) && RateControl(ucs,3,30) && ClosestTrial(oddball,10) && SlopeCheck(ucs+oddball)        
        %
        %get the cs_plus face, this depends on the rank of the sequence
        counter                     = counter + 1;
        cs_plus                     = mod(counter-1,tFace)+1;
        cs_neg                      = mod( cs_plus + tFace/2-1, tFace)+1;%the opposite face
        %
        counter_condition(cs_plus)  = counter_condition(cs_plus) + 1;
        nseq                        = counter_condition(cs_plus);
        %
        tTrial                      =  length(stim_id);
        %
        fprintf('Sequence %05d: ',ns );fprintf('+\n');
        order    = out.I(:,:,:,ns);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Now prepare the ISIs
        isi = [];
        for x = 1:tCond
            for y = 1:tCond
                loc                 = Shuffle( squeeze(order(y,x,:)));
                loc(isnan(loc))     = [];
                dummy               = isi_mat(y,x,:);
                dummy(isnan(dummy)) = [];
                isi(loc)            = Shuffle(dummy);
            end
        end
        isi(end+1)        = NaN;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        prestim_duration  = randgen_uniform( tTrial, prestim, prestim);
        cross_position    = ones(1,length(stim_id)).*2;
        %oddball identities, same in baseline and test, so it is not
        %updated in the for loop below.
        oddball_id         = randsample(setdiff(1:8,[cs_plus cs_neg]),sum(oddball),1);
        %baseline phase;
        for nphase = [2 4]
            seq(nseq,cs_plus).phase(nphase).presentation.cond_id          = double(stim_id(:));%will (not yet) contain all the original condition indices
            seq(nseq,cs_plus).phase(nphase).presentation.stim_id          = double(stim_id(:));%will contain the condition indices
            seq(nseq,cs_plus).phase(nphase).presentation.isi              = double(isi(:));
            seq(nseq,cs_plus).phase(nphase).presentation.prestim_duration = double(prestim_duration(:));
            seq(nseq,cs_plus).phase(nphase).presentation.ucs              = double(ucs(:));
            seq(nseq,cs_plus).phase(nphase).presentation.cross_position   = double(cross_position(:));
            seq(nseq,cs_plus).cs_plus                                     = double(cs_plus(:));
            seq(nseq,cs_plus).cs_neg                                      = double(cs_neg(:));
            seq(nseq,cs_plus).phase(nphase).presentation.oddball          = double(oddball(:));
            %
            %now we need to replace the odd trials with face identities.
            %Here we exclude the UCS trials, so oddball trial cannot contain
            %the CS+ face.
            seq(nseq,cs_plus).phase(nphase).presentation.stim_id(find(oddball))  = oddball_id(:);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %we are done iwth the baseline now find out the conditioning
        %sequence.
        ok = 1;
        while ok
            [stim_id order]   = GetStim_Sequence;
            
            oddball           = stim_id == 10;
            csplus_i          = find(stim_id == cs_plus);
            %kill half of the trials
            csplus_i          = randsample( csplus_i , round(length(csplus_i)./2));
            stim_id(csplus_i) = 9;
            ucs               = stim_id == 9;
            tTrial            = length(stim_id);
            
            if EqualHalfBalancing(ucs) & Consecutiveness(ucs,3) & IncludeEvent(ucs,0.9) & Consecutiveness(oddball,3) & EqualHalfBalancing(oddball) & LongestNoEventDistance(oddball+ucs,12)
                ok = 0;
                
                prestim_duration  = randgen_uniform( tTrial, prestim, prestim);
                cross_position    = ones(1,tTrial).*2;
                %
                isi = [];
                for x = 1:3%tCond
                    for y = 1:3%tCond
                        loc             = Shuffle(squeeze(order(y,x,:)));
                        loc(isnan(loc)) = [];
                        tloc            = length(loc);
                        isi(loc)        = randsample(isis,tloc,true);
                    end
                end
                %
                isi(end+1)  = NaN;
                %
                seq(nseq,cs_plus).phase(3).presentation.cond_id          = double(stim_id(:));%will (not yet) contain all the original condition indices
                seq(nseq,cs_plus).phase(3).presentation.stim_id          = double(stim_id(:));%will contain the condition indices
                seq(nseq,cs_plus).phase(3).presentation.isi              = double(isi(:));
                seq(nseq,cs_plus).phase(3).presentation.prestim_duration = double(prestim_duration(:));
                seq(nseq,cs_plus).phase(3).presentation.ucs              = double(ucs(:));
                seq(nseq,cs_plus).phase(3).presentation.cross_position   = double(cross_position(:));
                seq(nseq,cs_plus).cs_plus                                = double(cs_plus(:));
                seq(nseq,cs_plus).cs_neg                                 = double(cs_neg(:));
                seq(nseq,cs_plus).phase(3).presentation.oddball          = double(oddball(:));
                
                oddball_id                                                      = randsample(setdiff(1:8,[cs_plus cs_neg]),sum(oddball),1);
                seq(nseq,cs_plus).phase(3).presentation.stim_id(find(oddball))  = oddball_id(:);
                %for the conditioning and test phases we replace 9 with the cs+
                %index
                for tobereplaced = [3 4]
                    ucs_i                                                              = seq(nseq,cs_plus).phase(tobereplaced).presentation.stim_id == 9;
                    seq(nseq,cs_plus).phase(tobereplaced).presentation.stim_id(ucs_i)  = cs_plus;
                end
                %
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %and finally prepare the training sequence
                seq(nseq,cs_plus).phase(1).presentation.stim_id              = double(randsample(setdiff(1:8,cs_plus),tTrainTrial,1));
                seq(nseq,cs_plus).phase(1).presentation.isi                  = double(ones(1,tTrainTrial));%make same isis all over
                seq(nseq,cs_plus).phase(1).presentation.prestim_duration     = double(randgen_uniform( tTrainTrial, prestim, prestim));
                seq(nseq,cs_plus).phase(1).presentation.ucs                  = double(zeros(1,tTrainTrial));
                seq(nseq,cs_plus).phase(1).presentation.cross_position       = double(ones(1,tTrainTrial)*2);
                seq(nseq,cs_plus).phase(1).presentation.oddball              = double(zeros(1,tTrainTrial));
                seq(nseq,cs_plus).phase(1).presentation.oddball([4 6])       = double(1);
            end
        end
    end
    %stop if the ziel ist reached.
    if sum(counter_condition == total_sequence) == length(counter_condition)
        return
    end
end


%




    function [out]=EqualHalfBalancing(seq)
        %are UCSs equally balanced between first and second halves?
        out = sum(find(seq) <= ceil(length(seq)./2) ) == round( sum(seq)/2);
    end

    function [out]=Consecutiveness(seq,rep)
        %Checks consecutiveness in a sequence, out is 0 if event occurs
        %more than or equal to REP times consecutively.
        out = sum(conv(double(seq),ones(1,rep)) == rep) == 0;
    end

    function [out]=IncludeEvent(seq,part)
        %returns TRUE if there is an event on the last percentage of the
        %sequence.
        [out]=sum(find(seq) >= part*length(seq)) ~= 0;
    end

    function [out]=ExcludeEvent(seq,part)
        %returns TRUE if there is no event on the last percentage of the
        %sequence.
        [out]=sum(find(seq) >= part*length(seq)) == 0;
    end

    function [out]=RateControl(seq,E,N)
        %No more E events in N events
        out = sum(conv(double(ucs),ones(1,N),'same') > E) == 0;
    end

    function [out]=ClosestTrial(seq,closestdistance)
        %the closest distance (excluding the one case
        %where two events always follow each other) is ClosestDistance. So
        %nothing should happen within the ClosestDistance trials.
        x = sort(diff(find(seq)));
        out = x(2) >= closestdistance;
    end

    function [out]=LongestNoEventDistance(seq,distance)
        %the longest distance where nothing happens.
        out = max(sort(diff(find(seq)))) < distance;
        
        
    end

    function [out]=SlopeCheck(seq)
        out = false;
        rate     = conv(double(seq),ones(1,30),'valid');
        if sum(rate > 4) == 0
            X        = [[1:length(rate)]' ones(length(rate),1)];
            [b bint] = regress( rate(:), X );
            if bint(1) <=0 && bint(1,2)>=0
                out = true;
            end
        end
    end

    function [stim_id order]=GetStim_Sequence
        
        %first and last stimulus should not be the CS+ stimulus...
        %This is 1/ not nice 2/ UCS's cannot be balanced with
        %respect to the following stimulus identity%furthermore it
        %is stupied to start with null trials. We deal with these
        %constrainst with setdiff and ignoring the last conditions.
        %tCond(nphase)-1: we don't want to start with null trials
        
        %We want to select with which condition we start the
        %experiment. This must exclude CS_PLUS,
        %NULL, UCS and ODDBALL trials.
        %
        valid_conditions = [ cs_plus cs_neg 10];
        [stim_id order]  = SecondOrderBalancedSequence( 3, [28 28 2], 2);%start condition always two
        %get the real condition index.
        stim_id          = valid_conditions(stim_id);
        
    end





end