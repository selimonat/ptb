%input for simulation ending march03, called d.mat
alphas  = [11.25 33.75 56.25 78.75]
sd      = [8 16 24 32]
ntrials = [20 40 80 100 160 500]

for i=1:length(alphas)
bias(i,:,:)    = squeeze(mean(log10(alphas(i)/abs(d.alpha(:,i,:,:))),1))*20
end
%plots d.alpha in two subplots (one increasing alpha, one increasing
%SD)

figure
subplot(1,2,1);plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,1,2,:))),'bo-')
subplot(1,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,2,:))),'go-')
subplot(1,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,3,2,:))),'ro-')
subplot(1,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,4,2,:))),'yo-')
gca;title('mean \Delta\alpha for increasing \alpha');legend('\alpha=11.25','\alpha=33.75','\alpha=56.25','\alpha=78.75')
subplot(1,2,2);plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,1,:))),'bo-')
subplot(1,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,2,:))),'go-')
subplot(1,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,3,:))),'ro-')
subplot(1,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,4,:))),'yo-')
gca;title('mean \Delta\alpha for increasing SD');legend('SD=8','SD=16','SD=24','SD=32')
%plots d.sd in two subplots (one increasing alpha, one increasing
%SD)
figure
subplot(1,2,1);plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,1,2,:))),'bo-')
subplot(1,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,2,:))),'go-')
subplot(1,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,3,2,:))),'ro-')
subplot(1,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,4,2,:))),'yo-')
gca;title('mean \Delta SD for increasing \alpha');legend('\alpha=11.25','\alpha=33.75','\alpha=56.25','\alpha=78.75')
subplot(1,2,2);plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,1,:))),'bo-')
subplot(1,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,2,:))),'go-')
subplot(1,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,3,:))),'ro-')
subplot(1,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,4,:))),'yo-')
gca;title('mean \Delta SD for increasing SD');legend('SD=8','SD=16','SD=24','SD=32')
%plots d.alpha and d.sd in 4 subplots in one figure
figure
subplot(2,2,1);plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,1,2,:))),'bo-')
subplot(2,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,2,:))),'go-')
subplot(2,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,3,2,:))),'ro-')
subplot(2,2,1);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,4,2,:))),'yo-')
gca;title('mean \Delta\alpha for increasing \alpha');legend('\alpha=11.25','\alpha=33.75','\alpha=56.25','\alpha=78.75')
subplot(2,2,2);plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,1,:))),'bo-')
subplot(2,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,2,:))),'go-')
subplot(2,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,3,:))),'ro-')
subplot(2,2,2);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,4,:))),'yo-')
gca;title('mean \Delta\alpha for increasing SD');legend('SD=8','SD=16','SD=24','SD=32')
subplot(2,2,3);plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,1,2,:))),'bo-')
subplot(2,2,3);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,2,:))),'go-')
subplot(2,2,3);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,3,2,:))),'ro-')
subplot(2,2,3);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,4,2,:))),'yo-')
gca;title('mean \Delta SD for increasing \alpha');legend('\alpha=11.25','\alpha=33.75','\alpha=56.25','\alpha=78.75')
subplot(2,2,4);plot([20 40 80 100 160 500],mean(squeeze(d.alpha(:,2,1,:))),'bo-')
subplot(2,2,4);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,2,:))),'go-')
subplot(2,2,4);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,3,:))),'ro-')
subplot(2,2,4);hold on;plot([20 40 80 100 160 500],mean(squeeze(d.sd(:,2,4,:))),'yo-')
gca;title('mean \Delta SD for increasing SD');legend('SD=8','SD=16','SD=24','SD=32')

%plots the different d.alphas as dots for increasing ntrials
figure
subplot(1,2,1);
hold on;plot(d.alpha(:,1,2,1),'bo')
hold on;plot(d.alpha(:,1,2,2),'go')
hold on;plot(d.alpha(:,1,2,3),'ro')
hold on;plot(d.alpha(:,1,2,4),'yo')
title('d.alpha for increasing nTrials')
%same for SDs
subplot(1,2,2);
hold on;plot(d.sd(:,1,2,1),'bo')
hold on;plot(d.sd(:,1,2,2),'go')
hold on;plot(d.sd(:,1,2,3),'ro')
hold on;plot(d.sd(:,1,2,4),'yo')
title('d.SD for increasing nTrials')



