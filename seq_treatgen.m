%% testphase
for nsub = 1:200;
    for csp            = 1:8;
        others = setdiff(1:8,csp);
        cond_id        = [];
        ok = 0;
        while ~ok
            ok = 1 ;
            %random
            s = Shuffle([repmat(others,[1 6]) ones(1,3)*csp ones(1,3)*9]);
            s = [0 s];
            %constraints
            % never two ucs after each other
            ind = find(s==9);
            if any(ismember(find(diff(s)==0),ind))
                ok = 0;
            end
            % one of the first three trials has to be an ucs
            if all(find(s==9)> 3)
                ok = 0;
            end
            %ucs not in the last 5 trials
            if any(find(s==9) > length(s)-5)
                ok = 0;
            end
            %not too close to each other
            if any(diff(find(s==9))<8)
                ok = 0;
            end
% %             not too far away also
% %              if any(diff(find(s==9))>15)
% %                 ok = 0;
% %             end
        end
        for n = 1:9;fprintf('%g: %g\n',n,sum(s == n));end        
        % put the data to format usable by the presentation script.
        seq2 = [];
        seq2.cond_id               = s;
        seq2.ucs                   = s == 9;
        seq2.tonicpain             = seq_BalancedDist(s,[5 6 7]); %take as many isi possibilities as reps for conds
%         seq2.tonicpain(s ==9)      = Shuffle([5 6 7 5.5 6.5]); % because there is only two, it would not be distributed the same across sequences otherwise
        seq2.tonicpain(s ==0)      = 6; % because there is only two, it would not be distributed the same across sequences otherwise
%         seq2.isi2                  = 6 - seq2.isi1;
%         seq2.isi3                  = seq_BalancedDist(s,[.5 .75 1]);
%         seq2.poststim              = 1 - seq2.isi3;
        seq2.ratepain              = zeros(length(s),1);
        seq2.ratepain(mod(1:length(s),floor(length(s)/3))==1)      = 1;
        seq2.ratepain(end)         = 0;
        seq2.stim_id               = s;
        seq2.stim_id(s==9)         = csp;
        seq2.dist                  = MinimumAngle((seq2.stim_id-1)*45,(csp-1)*45);
        seq2.tTrial                = length(seq2.cond_id);
        %ucs=500
        seq2.dist(seq2.cond_id == 9)= 500;
        seq2.dist(seq2.cond_id == 0)= 3000;
        % balance the cross Positions, left right for the face conditions.
        seq2.CrossPosition        =  seq_feargen_fixcross(seq2);
        seq2.CrossPosition(1,:)   = seq2.CrossPosition(end,:);
        if nsub == 1
            fprintf('seq is about %g minutes long and has %g trials...\n',(3*10+length(s)*(1.5+1+6+5)+sum(seq2.tonicpain))/60,length(s));
        end
        %
        seq(nsub,csp) = seq2;
    end
end
%% conditioning
for nsub = 1:200;
    nsub
    for csp            = 1:8;
        csn   = mod( csp + 8/2-1, 8)+1;
        cond_id        = [];
        ok = 0;
        while ~ok
            ok =1 ;
            %random
            s = [0 2 3 Shuffle([ones(1,5) ones(1,9)*2 ones(1,4)*3])]; % 1 = CSP 2 = CSN 3 = UCS
            %constraints
%             % one of the first three trials has to be an ucs
%             if all(find(s==3)> 3)
%                 ok = 0;
%             end
            % don't repeat any condition three times
            if any(diff(diff(s))==0)
                ok = 0;
            end
            % never more than 8 trials without reinforcement
            if any(diff(find(s==3))>5)
                ok = 0;
            end
        end
        if nsub == 200;for n = 1:length(unique(s));fprintf('%g: %g\n',n,sum(s == n));end;end        
        % put the data to format usable by the presentation script.
        seq2 = [];
        seq2.cond_id               = s;
        seq2.ucs                   = s == 3;
        seq2.tonicpain             = seq_BalancedDist(s,[5 6 7 5.5 6.5]); %take as many isi possibilities as reps for conds
%         seq2.tonicpain(s == 3)     = Shuffle([5 6 7 5.5 6.5]); % because there is an equal number, it would not be distributed the same across sequences, i.e. peoples otherwise
        seq2.tonicpain(s == 0)     = 6; % because there 
%         seq2.isi2                  = 6 - seq2.isi1;
%         seq2.isi3                  = seq_BalancedDist(s,[.5 .75 1]);
%         seq2.poststim              = 1 - seq2.isi3;
        seq2.ratepain              = zeros(length(s),1);
        seq2.ratepain(mod(1:length(s),floor(length(s)/2))==1)      = 1;
        seq2.ratepain(end)         = 0; %is taken care of anyway in the experiment
        seq2.stim_id               = s;
        seq2.stim_id(s==1)         = csp;
        seq2.stim_id(s==2)         = csn;
        seq2.stim_id(s==3)         = csp;
        seq2.dist                  = MinimumAngle((seq2.stim_id-1)*45,(csp-1)*45);
        seq2.tTrial                = length(seq2.cond_id);
        %ucs=500
        seq2.dist(seq2.ucs)= 500;
        seq2.dist(seq2.cond_id==0) = 3000;
        % balance the cross Positions, left right for the face conditions.
        seq2.CrossPosition        =  seq_feargen_fixcross(seq2);
        seq2.CrossPosition(1,:)   = seq2.CrossPosition(end,:);
        if nsub == 1
            fprintf('seq is about %g minutes long and has %g trials...\n',(length(s)*(1.5+.85+6+5)+sum(seq2.tonicpain))/60,length(s));
        end
        %
        seq(nsub,csp) = seq2;
    end
end