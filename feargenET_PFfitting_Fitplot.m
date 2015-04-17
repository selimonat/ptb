function feargenET_PFfitting_Fitplot(subject,Log)
 x=0:1:100;
 xstimrange=0:11.25:100;
% collect number of trials per stimulus Level



minn=5;
maxn=25;

fig=figure('units','normalized','outerposition',[0 0 0.8 1]);
for chain=1:size(Log.x,1)
    
    dotsize  = Scale(sum(~isnan(Log.xrounded(:,:,chain)),2))*(maxn-minn)+minn;
    pcorrect = nanmean(Log.xrounded(:,:,chain),2);
    error    = nanstd(Log.xrounded(:,:,chain),0,2);
   
    subplot(2,2,chain)
    plot(x,...
        PAL_CumulativeNormal([Log.alpha(chain,end) 10.^(Log.beta(chain,end)) Log.gamma(chain,end) Log.lambda(chain,end)],x),'b')
    hold on;
    line([Log.alpha(end) Log.alpha(end)],[ -.2 1.2],'Color','y')
    %detect the nonnan entries
    for i =  find(~isnan(pcorrect(:))')
        errorbar(xstimrange(i),pcorrect(i),error(i),'ko','Markersize',dotsize(i));
        hold on;
    end
    ylabel('Percentage of "Different" Response')
    xlabel('X (deg)')
    xlim([-10 100])
    ylim([-.2 1.2])
    title(sprintf('chain %d',chain))
    hold off
end

suptitle(sprintf('Fitting Subject %02s',subject))
folder='C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\DiscriminationTask\pilotedata\';
saveas(fig,sprintf('%sFit_Subj%02s.png',folder,subject))

% to plot the presented x-values
nx=mean(d.nxmean,2)
a
% 
 x=0:1:100;
 xstimrange=0:11.25:100;
 a0=45;
 b0=10;
 g0=0.1;
 l0=0.02;
% collect number of trials per stimulus Level
minn=5;
maxn=25;
figure
plot(x,PAL_CumulativeNormal([a 1/b g l],x),'b')
hold on;
plot(x,PAL_CumulativeNormal([a0 1/b0 g0 l0],x),'r')
 for i =  1:length(xstimrange)
        plot(xstimrange(i),1.2,'ko','Markersize',dotsize(i),'MarkerFaceColor',[0.3 0.3 0.3]);
        hold on;
 end
 xlim([-5 100])
 ylim([-.1 1.8])
 legend('estimated PF','generating PF','stimulus placement','Location','southeast')
 
bar(mean(d.nxmean,2))
set(gca,'XTick',[1 2 3 4 5 6 7 8 9],'XTickLabel',{'0','11.25','22.5','33.75','45','56.25','67.5','78.75','90'})


