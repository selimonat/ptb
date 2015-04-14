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
        PAL_CumulativeNormal([Log.alpha(chain,end) 10^(Log.beta(chain,end)) Log.gamma(chain,end) Log.lambda(chain,end)],x),'r')
    hold on;
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



