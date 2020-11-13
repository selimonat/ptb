%generate test stimuli for psychometric discrimination task
mkdir('C:\Users\Lea\Documents\Experiments\FearAdapt_Pilote\');
cd('C:\Users\Lea\Documents\Experiments\FearAdapt_Pilote\');
mkdir('stim')
cd('stim')
R = 12.5; %radius
nSpikes=5; % number of spikes
rhoCSplus1 = .25; % rho of 1st CS+ (for counterbalancing)
rhoCSplus2 = .75; % rho of 2nd CS+ (for counterbalancing)
rhoCSs = [rhoCSplus1 rhoCSplus2];
nCS = 2;
delta_rho = [0 .05 .075 .1 .15];

for CS = 1:nCS
    for drho = delta_rho(:)'
        fname = sprintf('CSplus%d_p%03d_0.png',CS,drho*1000);
        q = gen_shape(rhoCSs(CS)+drho,nSpikes,R);
        print(q,fname,'-dpng');
        close all;
        exp_fearadapt_centerfish(fname)
        %         sprintf('CSplus%d_p%03d',CS,drho*1000)
        
        if drho>0
        fname = strrep(fname,'_p','_n'); %make pos to neg, underscore avoids png
        q = gen_shape(rhoCSs(CS)-drho,nSpikes,R);
        print(q,fname,'-dpng');
        close all
        exp_fearadapt_centerfish(fname)
        %         sprintf('CSplus%d_n%03d',CS,drho*1000)
        end
        
        
    end
end
%% make sequence.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Norbury trialtypes:
% switch  trialtypes
%     case 1
%         loadpict('CSplus1_p0.png',2,0,0,sizex,sizey);
%         seq(n).delta(nTrial)=0;
%     case 2
%         loadpict('CSplus1_p05.png',2,0,0,sizex,sizey);
%         delta=0.05;
%     case 3    loadpict('CSplus1_p075.png',2,0,0,sizex,sizey);
%         delta=0.075;
%     case 4
%         loadpict('CSplus1_p10.png',2,0,0,sizex,sizey);
%         delta=0.10;
%     case 5
%         loadpict('CSplus1_p15.png',2,0,0,sizex,sizey);
%         delta=0.15;
%     case 6
%         loadpict('CSplus1_n05.png',2,0,0,sizex,sizey);
%         delta=0.05;
%     case 7
%         loadpict('CSplus1_n075.png',2,0,0,sizex,sizey);
%         delta=0.075;
%     case 8    
%         loadpict('CSplus1_n10.png',2,0,0,sizex,sizey);
%         delta=0.10;
%     case 9    
%         loadpict('CSplus1_n15.png',2,0,0,sizex,sizey);
%         delta=0.15;
%     case 10    
%         loadpict('CSplus2_p0.png',2,0,0,sizex,sizey);
%         delta=0;
%     case 11    
%         loadpict('CSplus2_p05.png',2,0,0,sizex,sizey);
%         delta=0.05;
%     case 12    
%         loadpict('CSplus2_p075.png',2,0,0,sizex,sizey);
%         delta=0.075;
%     case 13    
%         loadpict('CSplus2_p10.png',2,0,0,sizex,sizey);
%         delta=0.10;
%     case 14    
%         loadpict('CSplus2_p15.png',2,0,0,sizex,sizey);
%         delta=0.15;
%     case 15    
%         loadpict('CSplus2_n05.png',2,0,0,sizex,sizey);
%         delta=0.05;
%     case 16    
%         loadpict('CSplus2_n075.png',2,0,0,sizex,sizey);
%         delta=0.075;
%     case 17    
%         loadpict('CSplus2_n10.png',2,0,0,sizex,sizey);
%         delta=0.10;
%     case 18    
%         loadpict('CSplus2_n15.png',2,0,0,sizex,sizey);
%         delta=0.15;
% end
trialsPerCond=8;
%generate trial type matrix for each subject:
TestTrials=[repmat([1 1 2 3 4 5 6 7 8 9 10 10 11 12 13 14 15 16 17 18],[1,trialsPerCond])]; %as in norbury discrim_test_del_p_main

conds  = 1:18;
delta  = [0 .05 .075 .1 .15 .05 .075 .1 .15 0 .05 .075 .1 .15 .05 .075 .1 .15];
deltas = [0 .05 .075 .1 .15 -.05 -.075 -.1 -.15 0 .05 .075 .1 .15 -.05 -.075 -.1 -.15];
nCS    = [ones(1,9) 2*ones(1,9)];

M = [conds;delta;deltas;nCS];


for n = 1:200
TestTrialMatrix=TestTrials(randperm(size(TestTrials,2)));
seq(n).cond = TestTrialMatrix;
seq(n).delta = M(2,seq(n).cond);
seq(n).sdelta = M(3,seq(n).cond);
seq(n).nCS   =  M(4,seq(n).cond);
seq(n).total_trials = length(TestTrialMatrix);
end

trialtypes = unique(TestTrialMatrix);

function q = gen_shape(rho, nSpikes, R)

%%GEN_SHAPE is function to generate perceptually linear 'spiky' shapes parameterised by 
% spikiness parameter rho, number of spikes, and full shape radius R, as 
% defined in van Dam & Ernst (2015), PloS Comp Biol
% (https://doi.org/10.1371/journal.pcbi.1004172)
%   set 'spikiness' rho param using values between 0.01 and 1 [surface area is constant]
%   in vD & E, nSpikes=5, and R=12.5(mm)


%%define outer (r_o) and inner (r_i) radii based on shape param rho 
if rho<1
    r_o = R * sqrt( (2*log(rho)) / (rho^2 - 1) ); 
else
    r_o = R;
end
r_i = rho * r_o;


%%draw shape based distance from centre of polar coordinates:
theta_i=1; 
theta_o=theta_i + (360/(2*nSpikes));

for a=1:nSpikes
      
    for theta_deg = theta_i:theta_o
        
        r_deg(theta_deg) = r_i * exp( (theta_deg - theta_i)/(theta_i - theta_o) * log(r_i/r_o) );
        
    end
    
    theta_i = theta_i + (360/nSpikes);
    
    for theta_deg = theta_o:theta_i 
        
        r_deg(theta_deg) = r_i * exp( (theta_deg - theta_i)/(theta_i - theta_o) * log(r_i/r_o) );
        
    end
    
    theta_o=theta_o + (360/nSpikes);

end

theta = (1:length(r_deg)).*(pi/180);
r = r_deg.*(pi/180);

q=figure;
set(q,'Resize','off')
p=polar(theta, r);

ax=gca;
%set(ax,'Position',[0.,0,0.55,0.55])
%set(ax,'XlimMode','manual')
set(ax,'Ylim',[-0.5,0.5])

z = findall(gcf,'type','patch');
z(q == z) = [];
delete(z);

set(p, 'Color', [0.5 0.5 0.5])
j=patch(get(p,'XData'), get(p,'YData'), [0 0.8 0.8]);
set(j, 'LineStyle', 'none')

h = findall(gcf,'type','line');
h(h == q) = [];
delete(h);

t = findall(gcf,'type','text');
delete(t);


end