
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%What is a PMF?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig=figure('position',[3 100 1000 400]);
subplot(1,3,1)
x=0:1:150;
plot(x,...
    PAL_CumulativeNormal([45 1/15 0.1 0.05],x),'r','linewidth',2)
hold on;
ylim([0 1])
xlim([0 100])
set(gca,'XTick',0:15:100)
ylabel('p("different")')
xlabel('stimulus intensity x (degrees)')
plot(45,PAL_CumulativeNormal([45 1/15 0.1 0.05],45),'bsquare','MarkerFaceColor','b')
line([45 45],[0 PAL_CumulativeNormal([45 1/15 0.1 0.05],45)],'linestyle',':','linewidth',2)
line([0 45],[PAL_CumulativeNormal([45 1/15 0.1 0.05],45) PAL_CumulativeNormal([45 1/15 0.1 0.05],45)],'linestyle',':','linewidth',2)
axis square

subplot(1,3,2)
plot(x,...
    PAL_CumulativeNormal([45 1/15 0.1 0.05],x),'r','linewidth',2)
hold on;
plot(45,PAL_CumulativeNormal([45 1/15 0.1 0.05],45),'bsquare','MarkerFaceColor','b')
ylim([0 1])
xlim([0 100])
set(gca,'XTick',0:15:100)
ylabel('p("different")')
plot(x,...
    PAL_CumulativeNormal([30 1/15 0.1 0.05],x),'r--','linewidth',2)
plot(x,...
    PAL_CumulativeNormal([60 1/15 0.1 0.05],x),'r--','linewidth',2)
axis square

subplot(1,3,3)
p(1)=plot(x,...
    PAL_CumulativeNormal([45 1/15 0.1 0.05],x),'r','linewidth',2)

hold on;
ylim([0 1])
xlim([0 100])
xlabel('x (deg)')
set(gca,'XTick',0:15:100)
p(2)=plot(x,...
    PAL_CumulativeNormal([45 1/7.5 0.1 0.05],x),'r--','linewidth',2)
plot(x,...
    PAL_CumulativeNormal([45 1/22.5 0.1 0.05],x),'r--','linewidth',2)
plot(45,PAL_CumulativeNormal([45 1/15 0.1 0.05],45),'bsquare','MarkerFaceColor','b')
axis square

legend(p,'before','after','location','eastoutside')

s=supertitle('Varying parameters in psychometric functions');
set(s,'FontSize',14)





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1---COMPARE METHODS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
psi1=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSI_3SDs_end.mat');
psi2=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSImarg2AFC_3SDs_end.mat');
psi3=load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\d_PSImargYN_3SDs_end.mat');

% how many trial levels do you want to display?
t=7;

mean1=squeeze(nanmean(psi1.d.alpha(:,1,1:3,1:t)));%average estimation       
mean2=squeeze(nanmean(psi2.d.alpha(:,1,1:3,1:t)));
mean3=squeeze(nanmean(psi3.d.alpha(:,1,1:3,1:t)));
E1=squeeze(nanstd(psi1.d.alpha(:,1,1:3,1:t)));
E2=squeeze(nanstd(psi2.d.alpha(:,1,1:3,1:t)));
E3=squeeze(nanstd(psi3.d.alpha(:,1,1:3,1:t)));

mean11=squeeze(nanmean(psi1.d.sd(:,1,1:3,1:t)));%average estimation       
mean22=squeeze(nanmean(psi2.d.sd(:,1,1:3,1:t)));
mean33=squeeze(nanmean(psi3.d.sd(:,1,1:3,1:t)));
E11=squeeze(nanstd(psi1.d.sd(:,1,1:3,1:t)));
E22=squeeze(nanstd(psi2.d.sd(:,1,1:3,1:t)));
E33=squeeze(nanstd(psi3.d.sd(:,1,1:3,1:t)));


fig=figure('position',[3 300 750 400])
subplot(1,2,1)%alpha for 20, 100, 500 trials
ti=[1 4 7];
t=[100 200 300];
xlimits=[50 max(t)+50];
ylimits=[0 100];
line(xlimits, [45 45],'color','yellow','linewidth',2,'linestyle','-')
hold on;
errorbar(t-10,mean1(2,ti),E1(2,ti),'bo','linewidth',2)
errorbar(t,mean2(2,ti),E2(2,ti),'ro','linewidth',2)
errorbar(t+10,mean3(2,ti),E3(2,ti),'ko','linewidth',2)
set(gca,'XTick',[100 200 300],'XTickLabel',{'20','100','500'})
xlim(xlimits)
ylim(ylimits)
axis square
xlabel('nTrials')
ylabel('mean estimated alpha (degrees) (\pm std)')


subplot(1,2,2)%alpha for 20, 100, 500 trials
ti=[1 4 7];
t=[100 200 300];
line(xlimits, [30 30],'color','yellow','linewidth',2,'linestyle','-')
hold on;
errorbar(t-10,mean11(2,ti),E11(2,ti),'bo','linewidth',2)
errorbar(t,mean22(2,ti),E22(2,ti),'ro','linewidth',2)
errorbar(t+10,mean33(2,ti),E33(2,ti),'ko','linewidth',2)
set(gca,'XTick',[100 200 300],'XTickLabel',{'20','100','500'})
xlim(xlimits)
ylim(ylimits)
axis square

xlabel('nTtrials')
ylabel('mean estimated beta (SD) (\pm std)')

legend('generating value','PSI','PSImarg2AFC','PSImargYN','orientation','horizontal', 'location','northoutside')

s=supertitle('Estimation of alpha and beta by different PSI-methods');
set(s,'FontSize',14)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2 --- SEARCH TRIAL NUMBER WE WANT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\diffSDs\trial_question\PSImargYN_a45_153045_20to120_merged.mat')

fig=figure('position',[3 300 750 400])
truealpha=45;
xlimits=[0 140];
ylimits=[12.5 77.5];
subplot(1,2,1)
%line([min(d.param.ttrials(:))-10 max(d.param.ttrials(:))+10], [truealpha truealpha],'color','yellow','linewidth',2);
line([0 140], [truealpha truealpha],'color','yellow','linewidth',2);
hold on;
errorbar(unique(d.param.ttrials(~isnan(d.param.ttrials)))-3,mean(d.alpha(:,1,1,1:6)),std(d.alpha(:,1,1,1:6)),'.','Color',[0 0 0.1],'linewidth',2,'MarkerSize',20);
errorbar(unique(d.param.ttrials(~isnan(d.param.ttrials))),mean(d.alpha(:,1,2,1:6)),std(d.alpha(:,1,2,1:6)),'.','Color',[0.08 0.17 0.55],'linewidth',2,'MarkerSize',20);
errorbar(unique(d.param.ttrials(~isnan(d.param.ttrials)))+3,mean(d.alpha(:,1,3,1:6)),std(d.alpha(:,1,3,1:6)),'.','Color',[0.05 0.5 0.8],'linewidth',2,'MarkerSize',20);
ylim(ylimits)
xlim(xlimits)
set(gca,'XTick',[20 40 60 80 100 120])
axis square
xlabel('nTrials')
ylabel('mean estimated alpha (degrees) (\pm std)')
legend('generating value','SD=15','SD=30','SD=45','Location','southoutside','orientation','horizontal')


%[0.8 0.8 0] [0.9 0.9 0.2],[1 1 0.4]
subplot(1,2,2)
truebeta=[15 30 45];
ylimits=[0 65];
ylim(ylimits)
xlim(xlimits);
set(gca,'XTick',[20 40 60 80 100 120])
xlabel('nTrials')
ylabel('mean estimated beta (in SD) (\pm std)')
axis square
line(xlimits, [truebeta(1) truebeta(1)],'color','yellow','linewidth',2);hold on;
errorbar(unique(d.param.ttrials(~isnan(d.param.ttrials)))-5,mean(d.sd(:,1,1,1:6)),std(d.sd(:,1,1,1:6)),'.--','Color',[0 0 0.05],'linewidth',2,'MarkerSize',20);
line(xlimits, [truebeta(2) truebeta(2)],'color','yellow','linewidth',2);hold on;
errorbar(unique(d.param.ttrials(~isnan(d.param.ttrials))),mean(d.sd(:,1,2,1:6)),std(d.sd(:,1,2,1:6)),'.--','Color',[0.08 0.17 0.55],'linewidth',2,'MarkerSize',20);
line(xlimits, [truebeta(3) truebeta(3)],'color','yellow','linewidth',2);hold on;
errorbar(unique(d.param.ttrials(~isnan(d.param.ttrials)))+5,mean(d.sd(:,1,3,1:6)),std(d.sd(:,1,3,1:6)),'.--','Color',[0.05 0.5 0.8],'linewidth',2,'MarkerSize',20);

h=supertitle('Estimating alpha and beta by PSImargYN');
set(h,'FontSize',14)
%n_{sim}=1000
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3--- ADD FORCED ZEROS OR NOT?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


a100trials_nozeros=mean(d_nozeros.alpha(:,1,:,5),1);
a100trials_nozeros_std=std(d_nozeros.alpha(:,1,:,5),1);

a100trials_zero_std=std(d_zeros.alpha,1);
a100trials_zero=mean(d_zeros.alpha,1);

fig=figure

subplot(1,2,1)
truealpha=45
line([80 120], [truealpha truealpha],'color','yellow','linewidth',2,'linestyle',':')
hold on;
errorbar([90 100 110],a100trials_nozeros,a100trials_nozeros_std,'ko','linewidth',2);

errorbar([91 101 111],a100trials_zero,a100trials_zero_std,'bo','linewidth',2)
xlim([80 120])
%ylim([0 60])
set(gca,'XTick',[90.5 100.5 110.5],'XTickLabel',{'15' '30' '45'})
xlabel('generating noise (SD)')
ylabel('mean estimated threshold in degrees (\pm std)')
title('Estimation of alpha by PSImargYN')
legend('generating value','no zeros','zeros added','orientation','horizontal','Location','best')

subplot(1,2,2)
truebeta=[15,30,45];
for i=1:3
line([80 120], [truebeta(i) truebeta(i)],'color','yellow','linewidth',2,'linestyle',':')
hold on;
end
errorbar([90 100 110],b100trials_nozeros,b100trials_nozeros_std,'ko','linewidth',2);

errorbar([91 101 111],b100trials_zero,b100trials_zero_std,'bo','linewidth',2)
xlim([80 120])
ylim([0 60])
set(gca,'XTick',[90.5 100.5 110.5],'XTickLabel',{'15' '30' '45'})
xlabel('generating noise (SD)')
ylabel('mean estimated slope (SD) (\pm std)')
title('Estimation of beta by PSImargYN')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%SCATTERPLOT 2x2
subjects=[6:26,28:36];
pmf=isn_getPMF(subjects,[1 5]);

betaSD=10.^-(pmf.beta);

fig=figure('Position',[3 50 700 500]);
subplot(2,2,1)%CS+ alpha
plot(pmf.alpha(:,1,1),pmf.alpha(:,1,2),'ro','MarkerFaceColor','r');
ylabel(sprintf('after'))
axis square
xlim([0 100])
ylim([0 100])
DrawIdentityLine(gca);
title('CS+ alpha')
box off
hold on;
plot(mean(pmf.alpha(:,1,1)),mean(pmf.alpha(:,1,2)),'k+','MarkerSize',10)

subplot(2,2,2)%CS+ beta
plot(betaSD(:,1,1),betaSD(:,1,2),'ro','MarkerFaceColor','r');
title('CS+ beta')
axis square
xlim([0 80])
ylim([0 80])
DrawIdentityLine(gca);
box off
hold on;
plot(mean(betaSD(:,1,1)),mean(betaSD(:,1,2)),'k+','MarkerSize',10)

subplot(2,2,3)%CS- alpha
plot(pmf.alpha(:,2,1),pmf.alpha(:,2,2),'bo','MarkerFaceColor','b');
xlim([0 100])
ylim([0 100])
xlabel('before')
ylabel(sprintf('after'))
axis square
DrawIdentityLine(gca);
title('CS- alpha')
box off
hold on;
plot(mean(pmf.alpha(:,2,1)),mean(pmf.alpha(:,2,2)),'k+','MarkerSize',10)

subplot(2,2,4)%CS- beta
plot(betaSD(:,2,1),betaSD(:,2,2),'bo','MarkerFaceColor','b');
xlabel(sprintf('before'))
axis square
xlim([0 80])
ylim([0 80])
DrawIdentityLine(gca);
title('CS- beta')
box off
hold on;
plot(mean(betaSD(:,2,1)),mean(betaSD(:,2,2)),'k+','MarkerSize',10)

t=supertitle('threshold \alpha before and after aversive learning');
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
subplot(2,2,1)
[h,e] = barwitherr(squeeze(alpha.sem),squeeze(alpha.mean));
set(gca,'XTickLabel',{'CS+','CS-'})
set(e,'LineWidth',1.5)
set(h(1), 'FaceColor','r') 
set(h(2), 'FaceColor',[143/255 0 0])
ylabel('threshold \alpha (degrees)')
axis square
legend('before','after','orientation','horizontal','location','southoutside')

subplot(2,2,2)
[h,e] = barwitherr(beta.errorbars,squeeze(10.^-mean(pmf.beta)));
set(gca,'XTickLabel',{'CS+','CS-'})
set(h(1), 'FaceColor','b') 
set(h(2), 'FaceColor',[0 0.05 0.2])
set(e,'LineWidth',1.5)
legend('before','after','orientation','horizontal','location','southoutside')
ylabel('slope \beta (SD)')
ylim([0 80])
axis square

% % %this adds * to mark significant differences, if they are there
% % annotation(gcf,'textbox',...
% %     [0.193802056555268 0.806539509536784 0.0414164524421595 0.0790190735694823],...
% %     'String',{'*'},...
% %     'FontSize',24,...
% %     'FontName','Arial',...
% %     'FitBoxToText','off',...
% %     'EdgeColor',[1 1 1]);
% % annotation(gcf,'textbox',...
% %     [0.638532133676092 0.637602179836512 0.0298483290488432 0.0817438692098088],...
% %     'String',{'*'},...
% %     'FontSize',24,...
% %     'FontName','Arial',...
% %     'FitBoxToText','off',...
% %     'EdgeColor',[1 1 1]);


%%%%%%%%%%PMFS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,2,3)
x=0:1:150;
%CS+ left, CS- right figure - pre vs post in one figure.
plot(x,...
    PAL_CumulativeNormal([alpha.mean(:,1,1) 10.^beta.mean(:,1,1) gamma.mean(:,1,1) lambda.mean(:,1,1)],x),'r-','linewidth',2)
hold on;
plot(x,...
    PAL_CumulativeNormal([alpha.mean(:,1,2) 10.^beta.mean(:,1,2) gamma.mean(:,1,2) lambda.mean(:,1,2)],x),'r--','linewidth',2)
legend('before','after','location','southeast')
title('CS+')
xlabel('X (deg)')
ylabel('p("different")')
axis square
%%%%%
subplot(2,2,4)
plot(x,...
    PAL_CumulativeNormal([alpha.mean(:,2,1) 10.^beta.mean(:,2,1) gamma.mean(:,2,1) lambda.mean(:,2,1)],x),'b-','linewidth',2)
hold on;
plot(x,...
    PAL_CumulativeNormal([alpha.mean(:,2,2) 10.^beta.mean(:,2,2) gamma.mean(:,2,2) lambda.mean(:,2,2)],x),'b--','linewidth',2)
legend('before','after','location','southeast')
title('CS-')
xlabel('X (deg)')
ylabel('p("different")')
axis square


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%FITGAUSS
subject=6;
r=isn_GetRatings(subject,[3 4],1);
for i=1:2
subplot(1,2,i)
h=bar(r(:,:,i));
hold on;
SetFearGenBarColors(h)
set(gca,'XTickLabel',{'','','','CSP','','','','CSN'})
[o]=fearcloud_fitgauss(subject,2+i);
h=gcf;
close(h)
plot(out.xsup+4,out.fitup,'k','linewidth',3);
ylabel('subjective rating p(shock)')
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% V1  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
r=30;
[X_koord] = cos([0:11.25:355]*pi/180)*r
[Y_koord] = -sin([0:11.25:355]*pi/180)*r
[circle] = [X_koord;Y_koord]';
plot(X_koord,Y_koord,'o','color',[0.4 0.4 0.4],'MarkerSize',8,'MarkerFaceColor','w','LineWidth',2)
xlim([-50 50])
ylim([-50 50])
% axis equal
axis square
axis off
box off
hold on;
[X_koord_2] = cos([0:45:355]*pi/180)*r;
[Y_koord_2] = -sin([0:45:355]*pi/180)*r;
[circle_2] = [X_koord_2;Y_koord_2]';
plot(X_koord_2,Y_koord_2,'s','color',[0.4 0.4 0.4],'MarkerSize',20,'MarkerFaceColor','w','LineWidth',2)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATRIX calibration business  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
face_space=textread('C:\Users\onat\Desktop\FaceSimilarityQuantification\SAVEDDROPBOX\5circles_RGB\circle_calculation_txt.txt');
load('C:\Users\onat\Desktop\FaceSimilarityQuantification\SAVEDDROPBOX\5circles_RGB\smoothed_005_1.4\Normalized\smoothededges_004\V1responses\NewFaceSpaceCoord_r60.mat');%facespace_new
 
ed_v1=load('C:\Users\onat\Desktop\FaceSimilarityQuantification\SAVEDDROPBOX\5circles_RGB\smoothed_005_1.4\Normalized\smoothededges_004\V1responses\EuclidianDistances.mat');ed_v1=ed_v1.ed;
r=60;
circle_coord    = [cos([0:11.25:359]*pi/180)*r'; sin([0:11.25:359]*pi/180)*r']';
 
figure('position',[500 100 600 600])
plot(face_space(:,1),face_space(:,2),'b.-')
hold on;
plot(facespace_new(:,1),facespace_new(:,2),'ro','MarkerFaceColor','r','MarkerSize',10)
axis equal
axis square

figure('position',[500 100 600 600])
plot(v1_space_2d(:,1),v1_space_2d(:,2),'b.-')
hold on;
plot(circle_coord(:,1),circle_coord(:,2),'ro','MarkerFaceColor','r','MarkerSize',10)
axis equal 




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SUBJECTS PMF IN DISCUSSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global project_path;project_path='C:\Users\onat\Google Drive\EthnoMaster\data\'
Log       = isn_GetData(12,5,'stimulation');
p = Log.p;
psi       = Log.p.psi;
x         = 0:1:100;
xstimrange= psi.stimRange;
% collect number of trials per stimulus Level

minn=5;
maxn=25;
%
fig=figure('units','normalized','outerposition',[0 0 0.45 0.6]);
suptitle('Fitting Subject 12, after conditioning, CS+');

chain=1;
    %dotsize gets scaled by number of trials at this x
    dotsize  = Scale(sum(~isnan(p.psi.log.xrounded(:,:,chain)),2))*(maxn-minn)+minn;
    pcorrect = nanmean(p.psi.log.xrounded(:,:,chain),2);
    error    = nanstd(p.psi.log.xrounded(:,:,chain),0,2);
    
    subplot(2,2,1)
    plot(x,...
        PAL_CumulativeNormal([p.psi.log.alpha(chain,end) 10.^(p.psi.log.beta(chain,end)) p.psi.log.gamma(chain,end) p.psi.log.lambda(chain,end)],x),'k','linewidth',3)
    hold on;
    
    %detect the nonnan entries
    %     for i =  find(~isnan(pcorrect(:))')
    %         errorbar(xstimrange(i),pcorrect(i),error(i),'ko','Markersize',dotsize(i));
    %         hold on;
    %     end
    for i =  find(~isnan(pcorrect(:))')
        errorbar(xstimrange(i),pcorrect(i),error(i),'o','Markersize',10,'markerfacecolor',[0.3 0.3 0.3],'color',[0.3 0.3 0.3]);
        hold on;
    end
    ylabel('p(different)')
    xlabel('X (deg)')
    xlim([-10 100])
    ylim([-.4 1.4])
    if chain==1
        title('CS+')
    else
        title('CS-')
    end
    hold off
    box off;
    line([p.psi.log.alpha(chain,end) p.psi.log.alpha(chain,end)],[ylim],'Color','r')
    
    
    subplot(2,2,3)
    for i =  find(~isnan(pcorrect(:))')
        plot(xstimrange(i),1.2,'o','color',[0.3 0.3 0.3],'Markersize',dotsize(i),'MarkerFaceColor',[0.3 0.3 0.3]);
        hold on;
    end
    xlim([-10 100]);
    title('Number of Presentations')
    box off;
    grid on;
    set(gca,'yticklabel',[],'ytick',[],'ycolor',[1 1 1],'xtick',xstimrange,'xtick',xstimrange(1:2:end));
     xlabel('X (deg)')
    text(xstimrange(1),1.9,'20%')
    
    subplot(2,2,2)
    plot(1:length(p.psi.log.alpha(chain,:)),p.psi.log.alpha(chain,:),'r-')
    hold on;
    errorbar([1 length(p.psi.log.alpha(chain,:))],p.psi.log.alpha(chain,[1 end]),p.psi.log.seAlpha(chain,[1 end]),'ro')
    title(sprintf('estimated alpha=%3.3g (%3.3g)',p.psi.log.alpha(chain,end),p.psi.log.seAlpha(chain,end)))
    xlim([-5 length(p.psi.log.beta(chain,:))+5])
    box off;
     xlabel('# trials')
     ylabel('alpha (degrees)');
    
     subplot(2,2,4)
%     plot(1:length(p.psi.log.beta(chain,:)),(10.^-p.psi.log.beta(chain,:)),'b-')
%     hold on;
%     errorbar([1 length(p.psi.log.beta(chain,:))],(10.^-p.psi.log.beta(chain,[1 end])),(10.^-p.psi.log.seBeta(chain,[1 end])),'bo')
    plot(1:length(p.psi.log.beta(chain,:)),(p.psi.log.beta(chain,:)),'b-')
    hold on;
    errorbar([1 length(p.psi.log.beta(chain,:))],(p.psi.log.beta(chain,[1 end])),(p.psi.log.seBeta(chain,[1 end])),'bo')
    %title(sprintf('estimated beta in SD = %3.3g (%3.3g)',(10.^-p.psi.log.beta(chain,end)),(10.^-p.psi.log.seBeta(chain,end))))
    title(sprintf('estimated beta = %3.3g (%3.3g)',(p.psi.log.beta(chain,end)),(p.psi.log.seBeta(chain,end))))
    xlim([-5 length(p.psi.log.beta(chain,:))+5])
    box off;
     xlabel('# trials')
     ylabel('beta');

%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SUBJECTS PMF IN DISCUSSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global project_path;project_path='C:\Users\onat\Google Drive\EthnoMaster\data\'
Log       = isn_GetData(9,5,'stimulation');
p = Log.p;
psi       = Log.p.psi;
x         = 0:1:100;
xstimrange= psi.stimRange;
% collect number of trials per stimulus Level

minn=5;
maxn=25;
%
fig=figure('units','normalized','outerposition',[0 0 0.45 0.6]);
suptitle('Fitting Subject 12, after conditioning, CS+');

chain=2;
    %dotsize gets scaled by number of trials at this x
    dotsize  = Scale(sum(~isnan(p.psi.log.xrounded(:,:,chain)),2))*(maxn-minn)+minn;
    pcorrect = nanmean(p.psi.log.xrounded(:,:,chain),2);
    error    = nanstd(p.psi.log.xrounded(:,:,chain),0,2);
    
    subplot(2,2,1)
    plot(x,...
        PAL_CumulativeNormal([p.psi.log.alpha(chain,end) 10.^(p.psi.log.beta(chain,end)) p.psi.log.gamma(chain,end) p.psi.log.lambda(chain,end)],x),'k','linewidth',3)
    hold on;
    
    %detect the nonnan entries
    %     for i =  find(~isnan(pcorrect(:))')
    %         errorbar(xstimrange(i),pcorrect(i),error(i),'ko','Markersize',dotsize(i));
    %         hold on;
    %     end
    for i =  find(~isnan(pcorrect(:))')
        errorbar(xstimrange(i),pcorrect(i),error(i),'o','Markersize',10,'markerfacecolor',[0.3 0.3 0.3],'color',[0.3 0.3 0.3]);
        hold on;
    end
    ylabel('p(different)')
    xlabel('X (deg)')
    xlim([-10 100])
    ylim([-.4 1.4])
    if chain==1
        title('CS+')
    else
        title('CS-')
    end
    hold off
    box off;
    line([p.psi.log.alpha(chain,end) p.psi.log.alpha(chain,end)],[ylim],'Color','r')
    
    
    subplot(2,2,3)
    for i =  find(~isnan(pcorrect(:))')
        plot(xstimrange(i),1.2,'o','color',[0.3 0.3 0.3],'Markersize',dotsize(i),'MarkerFaceColor',[0.3 0.3 0.3]);
        hold on;
    end
    xlim([-10 100]);
    title('Number of Presentations')
    box off;
    grid on;
    set(gca,'yticklabel',[],'ytick',[],'ycolor',[1 1 1],'xtick',xstimrange,'xtick',xstimrange(1:2:end));
     xlabel('X (deg)')
    text(xstimrange(1),1.9,'20%')
    
    subplot(2,2,2)
    plot(1:length(p.psi.log.alpha(chain,:)),p.psi.log.alpha(chain,:),'r-')
    hold on;
    errorbar([1 length(p.psi.log.alpha(chain,:))],p.psi.log.alpha(chain,[1 end]),p.psi.log.seAlpha(chain,[1 end]),'ro')
    title(sprintf('estimated alpha=%3.3g (%3.3g)',p.psi.log.alpha(chain,end),p.psi.log.seAlpha(chain,end)))
    xlim([-5 length(p.psi.log.beta(chain,:))+5])
    box off;
     xlabel('# trials')
     ylabel('alpha (degrees)');
    
     subplot(2,2,4)
%     plot(1:length(p.psi.log.beta(chain,:)),(10.^-p.psi.log.beta(chain,:)),'b-')
%     hold on;
%     errorbar([1 length(p.psi.log.beta(chain,:))],(10.^-p.psi.log.beta(chain,[1 end])),(10.^-p.psi.log.seBeta(chain,[1 end])),'bo')
    plot(1:length(p.psi.log.beta(chain,:)),(p.psi.log.beta(chain,:)),'b-')
    hold on;
    errorbar([1 length(p.psi.log.beta(chain,:))],(p.psi.log.beta(chain,[1 end])),(p.psi.log.seBeta(chain,[1 end])),'bo')
    %title(sprintf('estimated beta in SD = %3.3g (%3.3g)',(10.^-p.psi.log.beta(chain,end)),(10.^-p.psi.log.seBeta(chain,end))))
    title(sprintf('estimated beta = %3.3g (%3.3g)',(p.psi.log.beta(chain,end)),(p.psi.log.seBeta(chain,end))))
    xlim([-5 length(p.psi.log.beta(chain,:))+5])
    box off;
     xlabel('# trials')
     ylabel('beta');

     
     
     
     
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     %HYPOTHETICAL MEAN BARS
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     alphafake.sem=[5,4.7;5.5,5];
alphafake.mean=[60,48;62,57];

betafake.sem=[4.5,4.3;5.1,4.9];
betafake.mean=[30 20; 32 27];

fig=figure('Position',[3 50 700 500]);
subplot(1,2,1)
[h,e] = barwitherr(squeeze(alphafake.sem),squeeze(alphafake.mean));
set(gca,'XTickLabel',{'CS+','CS-'})
set(e,'LineWidth',1.5)
set(h(1), 'FaceColor','r') 
set(h(2), 'FaceColor',[143/255 0 0])
ylabel('threshold \alpha (degrees)')
ylim([0 100])
axis square
legend('before','after','orientation','horizontal','location','southoutside')

subplot(1,2,2)
[h,e] = barwitherr(betafake.sem,betafake.mean);
set(gca,'XTickLabel',{'CS+','CS-'})
set(h(1), 'FaceColor','b') 
set(h(2), 'FaceColor',[0 0.05 0.2])
set(e,'LineWidth',1.5)
legend('before','after','orientation','horizontal','location','southoutside')
ylabel('slope \beta (SD)')
ylim([0 60])
axis square

t=supertitle('hypothetical changes in threshold \alpha and slope \beta')
set(t,'FontSize',14)