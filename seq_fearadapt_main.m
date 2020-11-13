function [seq log] =seq_fearadapt_main
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
% clear all
reps = [10 8 2 8 2 2 2 2 2 ];
reps = reps/2;
trun = 5;
ucs1 = 2;
ucs2 = 4;
csp1 = 3;
csp2 = 5;
occ_trip =0;
occ_trans = 0;
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
            % never three times the same ucs after each other
            flag = check4rep(s,3);
            if flag==1
                ok = 0;
                occ_trip = occ_trip+1;
                fprintf('Discarding one.\n');
            end
            %balance out transitions.. (by eyeballing: we can do less than
            %3 reps per transition).
            s=s(:);
            n                      = hist3([s(1:end-1) s(2:end)],{1:9 1:9});
            nvec = n(:);
            if any(nvec>2)
                ok = 0;
                occ_trans = occ_trans+1;
                fprintf('Discarding one.\n');
            end
            s=s';
            %             % one of the first three trials has to be an ucs
            %             if all(find(s==9)> 3)
            %                 ok = 0;
            %             end
            %             %ucs not in the last 5 trials
            %             if any(find(s==9) > length(s)-5)
            %                 ok = 0;
            %             end
            %ucses not too close to each other
            %             if any(diff(find(s==9))<12)
            %                 ok = 0;
            %             end
            
            %             not too far away also
            %              if any(diff(find(s==9))>15)
            %                 ok = 0;
            %             end
            seq0.cond_id    = s;
            seq0.stim_id    = cond2stim_id(seq0.cond_id);
            seq0.ucs        = ismember(s,[2 4]);
            seq0.isi        = seq_BalancedDist(s,[4 4.5 5]);%repmat(4,1,length(s));%jitter comes extra in mainscript %seq_BalancedDist(s,[4 4.5 5]); %take as many isi possibilities as reps for conds
            seq0.tTrial     = length(s);
            seq0.jitter     = rand(1,length(s)).*1000; %jitter
            seq0.world      = 2-mod(nrun,2);
            seq0.trialsperblock  = length(seq0.cond_id);
            seq0.tTrial          = trun*seq0.trialsperblock;%Total Trials
            seq0.press2shock    = [3 10];
            seq0.transmat   = n;
            
            
            if mod(nsub,2)==1
                
            end
            if nsub == 1 && nrun ==1 %just so we don't print it every iteration
                dur_stim = 3;
                dur_outcomedelay = 3;
                dur_isi = mean(seq0.isi);
                dur_jitter = 1;
                fprintf('seq is about %g minutes long and has %g trials...\n',(length(s)*(dur_stim+dur_outcomedelay+dur_isi+dur_jitter)/60),length(s));
            end
            %
        end
        seq(nsub,nrun) = seq0;
    end
    log.occ_trip = occ_trip;
    log.occ_trans = occ_trans;
end
save('C:\Users\Lea\Documents\Experiments\FearAdapt_Pilote\seq\exp\seq.mat','seq')
%%%Subfunction CheckTriplets
    function [flag] = check4rep(seq,nrep)
        flag = 0;
        for id = 1:length(seq)-nrep-1
            cutseq = seq(id:id+nrep-1);
            if cutseq(1)==cutseq(2) && cutseq(2)==cutseq(3)
                flag = 1;
                fprintf('found triplet.\n')
                return
            end
        end
    end % End of function CheckTrips
    function [stim_id] = cond2stim_id(cond_id)
        % dir files will sor t like this:
        % (1)CSminus,(2)CSplus1, (3)CSplus1nTheta, (4)CSplus1pTheta, (5)CSplus2, (6)CSplus2nTheta, (7)CSplus2pTheta.
        % so we just assign the correct stims from the stimmatrix loaded in
        % SetPTB or SetParams in main scrip.
        stim_id = nan(size(cond_id));
        lookup = [1 2 3 4 5 6 7 8 9; 1 2 2 3 3 4 5 6 7]';
        for ind = 1:length(cond_id);
        stim_id(ind) = lookup(lookup(:,1)==cond_id(ind),2);
        end
    end
%%
%%
% a=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_1.mat');C(1,:)=histc(a.TestTrialMatrix,1:9);M(1,:)=a.TestTrialMatrix;
% b=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_2.mat');C(2,:)=histc(b.TestTrialMatrix,1:9);M(2,:)=b.TestTrialMatrix;
% c=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_3.mat');C(3,:)=histc(c.TestTrialMatrix,1:9);M(3,:)=c.TestTrialMatrix;
% d=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_4.mat');C(4,:)=histc(d.TestTrialMatrix,1:9);M(4,:)=d.TestTrialMatrix;
% e=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_5.mat');C(5,:)=histc(e.TestTrialMatrix,1:9);M(5,:)=e.TestTrialMatrix;
%
figure;
ncol = 5;
nrow = 2;
conds = 1:9;
s = seq(1,1).cond_id; s= s(:);
for nrun = 1:5;
    s = seq(1,nrun).cond_id; s= s(:);
    n                      = hist3([s(1:end-1) s(2:end)],{conds conds});
    
    subplot(nrow,ncol,nrun)
    plot(s,'.-','markersize',10);hold on;
    plot(find(s == 2),s(s == 2),'+r','markersize',10);
    plot(find(s == 4),s(s == 4),'+r','markersize',10);
    xlabel('trials')
    set(gca,'ytick',1:9,'yticklabel',{'1' '2' '3' '4' '5' '6' '7' '8' '9'})
    grid on;
    box off
    hold off;
    ylim([0 10])
    %
    subplot(nrow,ncol,nrun+5)
    
    imagesc(n);
    colorbar('vertical');
    axis square
end
end
%
%
% %% efficiency
% %s has to be col vector
% s=s(:);
% m = length(s);n=length(s);
% X = zeros(m,n);
% temp = s;
% for i=1:n
%     X(:,i) = temp;
%     temp = [0;temp(1:end-1)];
% end
% E = 1/trace(inv(X'*X));




