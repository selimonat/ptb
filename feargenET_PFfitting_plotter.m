alphas  = unique(d2.param.alpha(~isnan(d2.param.ttrials)));
sds     = unique(d2.param.sd(~isnan(d2.param.ttrials)));
trials  = unique(d2.param.ttrials(~isnan(d2.param.ttrials)));

%
cmap    = jet(length(alphas));%in rgb
cmap    = rgb2hsv(cmap);%in hsv, it is easier to change color and brightness separately
%%
%plot the bias separately for different trials
figure(1);
clf;
hold on;
for i_a = 1:length(alphas)
   for i_s = 1:length(sds)       
       %select a color for each a, and change its brightness for different
       %s values.
       color = [cmap(i_a,1) (i_s)./length(sds) (i_s)./length(sds)];
       m     = squeeze(nanmean(d.alpha(:,i_a,i_s,:)));%average estimation       
       plot(trials, m , 'o-' , 'color' , hsv2rgb(color),'linewidth',4);
   end
end
hold off


%plot the different methods in one plot
% 1) PSI method
% 2) PSI marginal 2 AFC, means with marginalized Lambda
% 3) PSI marginal Yes/No, menas marginalized Gamma and Lambda

%load the three guys here
psi1=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSI_3SDs_end.mat');
psi2=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSImarg2AFC_3SDs_merged.mat');
psi3=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSImargYN_3SDs_endof200merged.mat');

% how many trial levels do you want to display?
t=5;

mean1=squeeze(nanmean(psi1.d.alpha(:,1,1:3,1:t)));%average estimation       
mean2=squeeze(nanmean(psi2.d.alpha(:,1,1:3,1:t)));
mean3=squeeze(nanmean(psi3.d.alpha(:,1,1:3,1:t)));
E1=squeeze(nanstd(psi1.d.alpha(:,1,1:3,1:t)));
E2=squeeze(nanstd(psi2.d.alpha(:,1,1:3,1:t)));
E3=squeeze(nanstd(psi3.d.alpha(:,1,1:3,1:t)));
% rows=SD [15 30 45]

% % these guys are for one Method but 3 parameters of SD

% mean1=squeeze(nanmean(psi1.d.sd(:,1,1,:)));%average estimation       
% mean2=squeeze(nanmean(psi1.d.sd(:,1,2,:)));
% mean3=squeeze(nanmean(psi1.d.sd(:,1,3,:)));
% E1=squeeze(nanstd(psi1.d.sd(:,1,1,:)));
% E2=squeeze(nanstd(psi1.d.sd(:,1,2,:)));
% E3=squeeze(nanstd(psi1.d.sd(:,1,3,:)));



trials  = unique(psi1.d.param.ttrials(~isnan(psi1.d.param.ttrials)));
trials  = trials(1:t);

truealpha=45;
for i=1:3
alphafig15=figure(i);
title(sprintf('Threshold Estimation by 3 PSI methods, SD=%d',i*15),'FontSize',14)
line([0 max(trials)+10], [truealpha truealpha],'color','yellow','linewidth',2)
hold on;
errorbar(trials-2,mean1(i,:),E1(i,:),'bo--','linewidth',2)
hold on;
errorbar(trials,mean2(i,:),E2(i,:),'ro--','linewidth',2)
hold on;
errorbar(trials+2,mean3(i,:),E3(i,:),'ko--','linewidth',2)
legend('true Threshold','PSI','PSI marginal 2AFC',...
        'PSI marginal Y/N','Location','southoutside','orientation','horizontal')
xlabel('ntrials');
ylabel('Mean estimated threshold in degrees (\pm std)');
ylim([30 100])
end

% same for the beta estimation



meanslope1=squeeze(nanmean(psi1.d.sd(:,1,1:3,1:t)));%average estimation       
meanslope2=squeeze(nanmean(psi2.d.sd(:,1,1:3,1:t)));
meanslope3=squeeze(nanmean(psi3.d.sd(:,1,1:3,1:t)));

slopeE1=squeeze(nanstd(psi1.d.sd(:,1,1:3,1:t)));
slopeE2=squeeze(nanstd(psi2.d.sd(:,1,1:3,1:t)));
slopeE3=squeeze(nanstd(psi3.d.sd(:,1,1:3,1:t)));

trials  = unique(psi1.d.param.ttrials(~isnan(psi1.d.param.ttrials)));
trials  = trials(1:t);



for i=1:3

betafig=figure(i);
truebeta=i*15;

line([0 max(trials)+10], [truebeta truebeta],'color','yellow','linewidth',2)
hold on;
errorbar(trials-2,meanslope1(i,:),slopeE1(i,:),'bo--','linewidth',2)
hold on;
errorbar(trials,meanslope2(i,:),slopeE2(i,:),'ro--','linewidth',2)
hold on;
errorbar(trials+2,meanslope3(i,:),slopeE3(i,:),'ko--','linewidth',2)
xlabel('ntrials');
ylabel('Mean estimated Slope in SD (\pm std)');
legend('true slope','PSI','PSI marginal 2AFC',...
        'PSI marginal Y/N','Location','southoutside','orientation','horizontal')
title('Slope Estimation by 3 PSI methods, constant \alpha=45','FontSize',14)
ylim([0 80])

end