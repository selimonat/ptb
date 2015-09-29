function fearcloud_FitPMFs(subjects)
for subject=subjects
  
%
fig=figure('units','normalized','position',[0 1 0.7 0.9]);
suptitle(sprintf('Fitting Subject %g',subject));

cr=0;
for run = [1 5];
    for chain   = [1 2];
        
        StimLevels = 0:11.25:180;
        x          = linspace(0,180,1000);
        
        %get responses, and resulting PMF from PAL algorithm
        responses = fearcloud_GetPMFresponses(subject,run,chain,'yes');
        pmf       = isn_getPMF(subject,run);
        p         = isn_GetData(subject,run,'stimulation');p = p.p;
        
        i = ~isnan(responses.yes);
        
        NumPos   = responses.yes(i); % number of "different" responses
        OutOfNum = responses.num(i); % number of presentations at that level
        PropCorrectData = NumPos./OutOfNum;
        StimLevels = StimLevels(i);
        
        minn = 5;
        maxn = 25;
        
        dotsize  = Scale(sum(~isnan(p.psi.log.xrounded(:,:,chain)),2))*(maxn-minn)+minn;
        dotsize = dotsize(i);
        error    = nanstd(p.psi.log.xrounded(:,:,chain),0,2);
        error = error(i);
        % take the priors as search grid (gamma extended to .5, resolution very low
        % for little Laptop of Lea's)
        searchGrid.alpha = pmf.alpha(chain);
        searchGrid.beta   = 4;
        searchGrid.gamma = PropCorrectData(1);
        searchGrid.lambda = 1-PropCorrectData(end);
        params0 = [ searchGrid.alpha  searchGrid.beta searchGrid.gamma searchGrid.lambda];
        % %ooor use the params that PAL gave as results
        % searchGrid.alpha = pmf.alpha(chain);
        % searchGrid.beta  = 10.^pmf.beta(chain);
        % searchGrid.gamma = pmf.gamma(chain);
        % searchGrid.lambda = pmf.lambda(chain);
        
        paramsFree = [1 1 1 1];
        PF         = @PAL_Weibull;
        
        %% run the Fit!
        options             = PAL_minimize('options');
        options.MaxIter     = 10.^6;
        options.MaxFunEvals = 10.^6;
        options.Display     = 'On';
        options.TolX        = 10.^-4;
        options.TolFun      = 10.^-4;
        
        % [paramsValues LL exitflag output] = PAL_PFML_Fit(StimLevels, NumPos, OutOfNum, searchGrid, paramsFree, PF,'lapseLimits',[0 1],'guessLimits',[0 1],'searchoptions',options);
        X = abs(p.psi.log.x(chain,:));
        Y = abs(p.psi.log.response(chain,:));
        % funny  = @(params) sum( (Y - PF(params,X)).^2);
        
        funny = @(params) sum(-log (binopdf(NumPos,OutOfNum,PF(params,StimLevels))));
        %params(end)
        
        
        options         = optimset('Display','iter','maxfunevals',10000,'tolX',10^-12,'tolfun',10^-12,'MaxIter',10000,'Algorithm','interior-point');
        
        [params1, o.Likelihood, o.ExitFlag]  = fmincon(funny, params0, [],[],[],[],[-Inf -Inf 0 0],[Inf Inf 1 1],[],options);
        
        
        %% plot the Fit
        Fit = PF(params1,x);
        
        subplot(2,2,chain+cr)
        hold on;
        plot(x,PAL_CumulativeNormal([pmf.alpha(chain) 10.^(pmf.beta(chain)) pmf.gamma(chain) pmf.lambda(chain)],x),'k','linewidth',3);
        plot(x,PF([searchGrid.alpha searchGrid.beta searchGrid.gamma searchGrid.lambda],x),'r-','Linewidth',3);
        plot(x,Fit,'g-','Linewidth',3);
        xlim([-5 180]);
        legend('PALs PMF','InitialValues','New Fit','location','southeast')
        title(sprintf('Run %g, Chain %g',run,chain))
        for i = 1:length(StimLevels)
            errorbar(StimLevels(i),PropCorrectData(i),error(i),'o','Markersize',dotsize(i),'markerfacecolor',[0.3 0.3 0.3],'color',[0.3 0.3 0.3]);
        end
        hold off;
        
    end
cr=cr+2;
end

%%%%
save_path = sprintf('%sfigures/%s.eps',isn_GetPath(subject,run),mfilename);
hgexport(fig,save_path);
saveas(fig,sprintf('%sfigures/%s_png.png',isn_GetPath(subject,run),mfilename))

end
end
