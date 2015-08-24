%%%%%%%%%%600ms version analysis and plot script....

global project_path;project_path='C:\Users\onat\Google Drive\EthnoMaster\data\'

subjects=[40,42,44,45,46,47,48,49,51];
pmf=isn_getPMF(subjects,[1 5]);

n=length(subjects);

betaSD=10.^-pmf.beta;
%compute the means and stds 
alpha.mean=mean(pmf.alpha);
alpha.std=std(pmf.alpha);
alpha.sem=alpha.std/sqrt(n);
beta.mean=mean(pmf.beta);
beta.std=std(pmf.beta);
beta.sem=beta.std/sqrt(n);
gamma.mean=mean(pmf.gamma);
lambda.mean=mean(pmf.lambda);


%%%%%%SCATTERPLOT 2x2
betaSD=10.^-(pmf.beta);

fig=figure('Position',[3 50 700 500]);
subplot(2,2,1)%CS+ alpha
plot(pmf.alpha(:,1,1),pmf.alpha(:,1,2),'go','MarkerFaceColor','g');
ylabel(sprintf('after'))
axis square
xlim([0 170])
ylim([0 170])
DrawIdentityLine(gca);
title('CS+ alpha')
box off
hold on;
plot(mean(pmf.alpha(:,1,1)),mean(pmf.alpha(:,1,2)),'k+','MarkerSize',10)

subplot(2,2,2)%CS+ beta
plot(betaSD(:,1,1),betaSD(:,1,2),'go','MarkerFaceColor','g');
title('CS+ beta')
axis square
xlim([0 100])
ylim([0 100])
DrawIdentityLine(gca);
box off
hold on;
plot(mean(betaSD(:,1,1)),mean(betaSD(:,1,2)),'k+','MarkerSize',10)

subplot(2,2,3)%CS- alpha
plot(pmf.alpha(:,2,1),pmf.alpha(:,2,2),'ko','MarkerFaceColor','y');
xlim([0 170])
ylim([0 170])
xlabel('before')
ylabel(sprintf('after'))
axis square
DrawIdentityLine(gca);
title('CS- alpha')
box off
hold on;
plot(mean(pmf.alpha(:,2,1)),mean(pmf.alpha(:,2,2)),'k+','MarkerSize',10)

subplot(2,2,4)%CS- beta
plot(betaSD(:,2,1),betaSD(:,2,2),'ko','MarkerFaceColor','y');
xlabel(sprintf('before'))
axis square
xlim([0 100])
ylim([0 100])
DrawIdentityLine(gca);
title('CS- beta')
box off
hold on;
plot(mean(betaSD(:,2,1)),mean(betaSD(:,2,2)),'k+','MarkerSize',10)

t=supertitle(['mean threshold \alpha and slope \beta, 600ms version, ' sprintf('N=%d',n)]);
set(t,'FontSize',14)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%barplot for means
%compute the mean 
alpha.mean=mean(pmf.alpha);
alpha.std=std(pmf.alpha);
alpha.sem=alpha.std/sqrt(length(subjects));
beta.mean=mean(pmf.beta);
beta.std=std(pmf.beta);
beta.sem=beta.std/sqrt(length(subjects));
gamma.mean=mean(pmf.gamma);
lambda.mean=mean(pmf.lambda);
lower=10.^-(beta.mean+beta.sem);
upper=10.^-(beta.mean-beta.sem);
ubar=upper-(10.^-beta.mean);
lbar=10.^-beta.mean-lower;
beta.errorbars=NaN(2,2,2);
beta.errorbars(:,:,1)=squeeze(lbar);
beta.errorbars(:,:,2)=squeeze(ubar);

fig=figure('Position',[3 50 700 500]);
subplot(1,2,1)
[h,e] = barwitherr(squeeze(alpha.sem),squeeze(alpha.mean));
set(gca,'XTickLabel',{'CS+','CS-'})
set(e,'LineWidth',1.5)
set(h(1), 'FaceColor','r') 
set(h(2), 'FaceColor',[143/255 0 0])
ylabel('threshold \alpha (degrees)')
axis square
legend('before','after','orientation','horizontal','location','southoutside')

subplot(1,2,2)
[h,e] = barwitherr(beta.errorbars,squeeze(10.^-mean(pmf.beta)));
set(gca,'XTickLabel',{'CS+','CS-'})
set(h(1), 'FaceColor','b') 
set(h(2), 'FaceColor',[0 0.05 0.2])
set(e,'LineWidth',1.5)
legend('before','after','orientation','horizontal','location','southoutside')
ylabel('slope \beta (SD)')
ylim([0 80])
axis square

t=supertitle(['mean threshold \alpha and slope \beta, 600ms version, ' sprintf('N=%d',n)]);
set(t,'FontSize',14)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[p_csp_alpha,h,stats]=signtest(pmf.alpha(:,1,1),pmf.alpha(:,1,2))
[p_csn_alpha,h,stats]=signtest(pmf.alpha(:,2,1),pmf.alpha(:,2,2))
[p_csp_beta,h,stats]=signtest(pmf.beta(:,1,1),pmf.beta(:,1,2))
[p_csn_beta,h,stats]=signtest(pmf.beta(:,2,1),pmf.beta(:,2,2))

[p_csp_alpha,h]=signrank(pmf.alpha(:,1,1),pmf.alpha(:,1,2))
[p_csn_alpha,h]=signrank(pmf.alpha(:,2,1),pmf.alpha(:,2,2))
[p_csp_beta,h]=signrank(pmf.beta(:,1,1),pmf.beta(:,1,2))
[p_csn_beta,h]=signrank(pmf.beta(:,2,1),pmf.beta(:,2,2))

[h,p_csp_alpha]=ttest(pmf.alpha(:,1,1),pmf.alpha(:,1,2))
[h,p_csn_alpha]=ttest(pmf.alpha(:,2,1),pmf.alpha(:,2,2))
[h,p_csp_beta]=ttest(pmf.beta(:,1,1),pmf.beta(:,1,2))
[h,p_csp_beta]=ttest(pmf.beta(:,2,1),pmf.beta(:,2,2))

alph=[pmf.alpha(:,1,1),pmf.alpha(:,2,1);pmf.alpha(:,1,2),pmf.alpha(:,2,2)];
beta=[pmf.beta(:,1,1),pmf.beta(:,2,1);pmf.beta(:,1,2),pmf.beta(:,2,2)];
[p_a,table,stats]=anova2(alph,n);
[p_b,table,stats]=anova2(beta,n);

