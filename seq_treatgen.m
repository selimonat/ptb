%% testphase
for nsub = 1:200;
    for csp            = 1:8;
        cond_id        = [];
        ok = 0;
        while ~ok
            ok =1 ;
            %random
            s = Shuffle([repmat(1:8,[1 4]) 9 9]);
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
            % don't repeat any condition three times
            if any(diff(diff(s)))==0
                ok = 0;
            end
            %second ucs not in the last 8 trials
            if any(find(s==9) > length(s)-8)
                ok = 0;
            end
            if any(diff(find(s==9))<8)
                ok = 0;
            end
        end
        for n = 1:9;fprintf('%g: %g\n',n,sum(s == n));end        
        % put the data to format usable by the presentation script.
        seq2 = [];
        seq2.cond_id               = s;
        seq2.ucs                   = s == 9;
        seq2.tonicpain             = seq_BalancedDist(s,[5 6 7 6]); %take as many isi possibilities as reps for conds
        seq2.tonicpain(s ==9)      = Shuffle([5 6]); % because there is only two, it would not be distributed the same across sequences otherwise
%         seq2.isi2                  = 6 - seq2.isi1;
%         seq2.isi3                  = seq_BalancedDist(s,[.5 .75 1]);
%         seq2.poststim              = 1 - seq2.isi3;
        seq2.ratepain              = zeros(length(s),1);
        seq2.ratepain([1 17])      = 1;
        seq2.stim_id               = s;
        seq2.stim_id(s==9)         = csp;
        seq2.dist                  = MinimumAngle((seq2.stim_id-1)*45,(csp-1)*45);
        seq2.tTrial                = length(seq2.cond_id);
        %ucs=500
        seq2.dist(seq2.cond_id == 9)= 500;
        % balance the cross Positions, left right for the face conditions.
        seq2.CrossPosition        =  seq_feargen_fixcross(seq2);
        if nsub == 1
            fprintf('seq is about %g minutes long and has %g trials...\n',(3*5+length(s)*(1+.5+6+5)+sum(seq2.tonicpain))/60,length(s));
        end
        %
        seq(nsub,csp) = seq2;
    end
end
%% conditioning
for nsub = 1:200;
    for csp            = 1:8;
        csn   = mod( csp + 8/2-1, 8)+1;
        cond_id        = [];
        ok = 0;
        while ~ok
            ok =1 ;
            %random
            s = Shuffle([ones(1,5) ones(1,5)*2]);
            %constraints
            % one of the first three trials has to be an ucs
            if all(find(s==3)> 3)
                ok = 0;
            end
            % don't repeat any condition three times
            if any(diff(diff(s)))==0
                ok = 0;
            end
        end
        for n = 1:length(unique(s));fprintf('%g: %g\n',n,sum(s == n));end        
        % put the data to format usable by the presentation script.
        seq2 = [];
        seq2.cond_id               = s;
        seq2.ucs                   = s == 1;
        seq2.tonicpain             = seq_BalancedDist(s,[5 5.5 6 6.5 7]); %take as many isi possibilities as reps for conds
        seq2.tonicpain(s == 3)     = Shuffle([5 6 6 7]); % because there is only two, it would not be distributed the same across sequences otherwise
%         seq2.isi2                  = 6 - seq2.isi1;
%         seq2.isi3                  = seq_BalancedDist(s,[.5 .75 1]);
%         seq2.poststim              = 1 - seq2.isi3;
        seq2.ratepain              = zeros(length(s),1);
        seq2.ratepain([1 length(s)])= 1;
        seq2.stim_id               = csp;
        seq2.stim_id(s==2)         = csn;
        seq2.dist                  = MinimumAngle((seq2.stim_id-1)*45,(csp-1)*45);
        seq2.tTrial                = length(seq2.cond_id);
        %ucs=500
        seq2.dist(seq2.cond_id == 3)= 500;
        % balance the cross Positions, left right for the face conditions.
        seq2.CrossPosition        =  seq_feargen_fixcross(seq2);
        if nsub == 1
            fprintf('seq is about %g minutes long and has %g trials...\n',(length(s)*(1.5+.85+5)+sum(seq2.tonicpain))/60,length(s));
        end
        %
        seq(nsub,csp) = seq2;
    end
end