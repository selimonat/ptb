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

truealpha=45;

%load the three guys here
psi1=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSI_3SDs_end.mat');
psi2=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSImarg2AFC_3SDs_end.mat');
psi3=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSImargYN_3SDs_end.mat');

% big plot for all three SDs and all three methods

mean1=squeeze(nanmean(psi1.d.alpha(:,1,1:3,:)));%average estimation       
mean2=squeeze(nanmean(psi2.d.alpha(:,1,1:3,:)));
mean3=squeeze(nanmean(psi3.d.alpha(:,1,1:3,:)));
E1=squeeze(nanstd(psi1.d.alpha(:,1,1:3,:)));
E2=squeeze(nanstd(psi2.d.alpha(:,1,1:3,:)));
E3=squeeze(nanstd(psi3.d.alpha(:,1,1:3,:)));
% rows=SD [15 30 45]

% % these guys are for one Method but 3 parameters of SD

% mean1=squeeze(nanmean(psi1.d.sd(:,1,1,:)));%average estimation       
% mean2=squeeze(nanmean(psi1.d.sd(:,1,2,:)));
% mean3=squeeze(nanmean(psi1.d.sd(:,1,3,:)));
% E1=squeeze(nanstd(psi1.d.sd(:,1,1,:)));
% E2=squeeze(nanstd(psi1.d.sd(:,1,2,:)));
% E3=squeeze(nanstd(psi1.d.sd(:,1,3,:)));

trials  = unique(psi1.d.param.ttrials(~isnan(psi1.d.param.ttrials)));

alphafig=figure;
for i=1:3
subplot(3,1,i);
line([0 max(trials)], [truealpha truealpha],'color','yellow','linewidth',2)
hold on;
errorbar(trials,mean1(i,:),E1(i,:),'bo-','linewidth',3)
hold on;
errorbar(trials,mean2(i,:),E2(i,:),'ro-','linewidth',3)
hold on;
errorbar(trials,mean3(i,:),E3(i,:),'ko-','linewidth',3)
legend('true threshold \alpha=45','PSI','PSI marginal 2AFC','PSI marginal Y/N')
title('Threshold Estimation by 3 PSI methods','FontSize',14)
saveas(alphafig,'C:\Users\onat\Dropbox\feargen_lea\Ethno Master\simdata\diffSDs\plotAlpha15.png')

% % % % 
% same for the beta estimation

truebeta=15;

meanslope1=squeeze(nanmean(psi1.d.sd(:,1,1,:)));%average estimation       
meanslope2=squeeze(nanmean(psi2.d.sd(:,1,1,:)));
meanslope3=squeeze(nanmean(psi3.d.sd(:,1,1,:)));

trials  = unique(psi1.d.param.ttrials(~isnan(psi1.d.param.ttrials)));

betafig=figure;
line([0 max(trials)], [truebeta truebeta],'color','yellow','linewidth',2)
hold on;
plot(trials,meanslope1,'bo-','linewidth',3)
hold on;
plot(trials,meanslope2,'ro-','linewidth',3)
hold on;
plot(trials,meanslope3,'ko-','linewidth',3)
legend('true slope SD=15','PSI','PSI marginal 2AFC','PSI marginal Y/N')
title('Slope(SD) Estimation by 3 PSI methods','FontSize',14)
gca;
SaveAs(betafig,'C:\Users\onat\Dropbox\feargen_lea\Ethno Master\simdata\diffSDs\plotBeta15.png')