
%one chain first
% 1 - CS-1
% 2 - CS+1+UCS
% 3 - CS+1
% 4 - CS+2+UCS
% 5 - CS+2
% 6 - CS+1neg
% 7 - CS+1pos
% 8 - CS+2neg
% 9 - CS+2pos
clear all
reps = [10 8 2 8 2 2 2 2 2 ];

trun = 6;
for nsub = 1:200;
    for nrun = 1:trun
        ok = 0;
        while ~ok
            ok = 1 ;
            %random
            s=[];
            for cond = 1:9
                s = [s cond*ones(1,reps(cond))];
            end
            s = Shuffle(s);
            %constraints??
            %             % never two ucs after each other
            %             ind = find(s==9);
            %             if any(ismember(find(diff(s)==0),ind))
            %                 ok = 0;
            %             end
            %             % one of the first three trials has to be an ucs
            %             if all(find(s==9)> 3)
            %                 ok = 0;
            %             end
            %             %ucs not in the last 5 trials
            %             if any(find(s==9) > length(s)-5)
            %                 ok = 0;
            %             end
            %             %ucses not too close to each other
            %             if any(diff(find(s==9))<12)
            %                 ok = 0;
            %             end
            
            % %             not too far away also
            % %              if any(diff(find(s==9))>15)
            % %                 ok = 0;
            % %             end
            seq0.cond_id    = s;
            seq0.ucs        = ismember(s,[2 4]);
            seq0.isi        = repmat(4,1,length(s));%jitter comes extra in mainscript %seq_BalancedDist(s,[4 4.5 5]); %take as many isi possibilities as reps for conds
            seq0.tTrial     = length(s);
            seq0.jitter     = rand(1,length(s)).*1000; %jitter
            seq0.world      = 2-mod(nrun,2);
            seq0.trialsperblock  = length(seq0.cond_id);
            seq0.tTrial          = trun*seq0.trialsperblock;%Total Trials
            seq0.press2shock    = [5 10];
            

            if mod(nsub,2)==1
                
            end
            if nsub == 1 && nrun ==1
                dur_stim = 3;
                dur_outcomedelay = 3;
                dur_isi = 4;
                dur_jitter = 1;
                fprintf('seq is about %g minutes long and has %g trials...\n',(length(s)*(dur_stim+dur_outcomedelay+dur_isi+dur_jitter)/60),length(s));
            end
            %
            seq(nsub,nrun) = seq0;
        end
    end
end
save('C:\Users\Lea\Documents\Experiments\FearAdapt_Pilote\seq\exp\seq.mat','seq')

