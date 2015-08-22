%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Goodness of Fit?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fitting functions again, using PAL_FIT
subject = 32;
run     = 1;
chain   = 1;

StimLevels = 0:11.25:180;
x          = linspace(0,180,1000);

%get responses, and resulting PMF from PAL algorithm
responses = fearcloud_GetPMFresponses(subject,run,chain,'yes');
pmf       = isn_getPMF(subject,run);


NumPos   = responses.yes; % number of "different" responses
OutOfNum = responses.num; % number of presentations at that level
PropCorrectData = NumPos./OutOfNum;
% take the priors as search grid (gamma extended to .5, resolution very low
%% for little Laptop of Lea's)
searchGrid.alpha = 49
searchGrid.beta = 10.^-1.07
searchGrid.gamma = 0.36;
searchGrid.lambda = 0.07;
%ooor use the params that PAL gave as results
%searchGrid = [pmf.alpha(chain) 10.^pmf.beta(chain) pmf.gamma(chain) pmf.lambda(chain)];
paramsFree = [1 1 1 1];
PF         = @PAL_CumulativeNormal;
plot(StimLevels,PropCorrectData,'k.','Markersize',40);;hold on
plot(x,PF([searchGrid.alpha searchGrid.beta searchGrid.gamma searchGrid.lambda],x),'r-','Linewidth',3);
hold off;
%% run the Fit!
options             = PAL_minimize('options');
options.MaxIter     = 10.^6;
options.MaxFunEvals = 10.^6;
options.Display     = 'On';
options.ToX         = -10.^6;
options.TolFun      = -10.^6;

[paramsValues LL exitflag output] = PAL_PFML_Fit(StimLevels, NumPos, OutOfNum, searchGrid, paramsFree, PF,'lapseLimits',[0 1],'guessLimits',[0 1],'searchoptions',options);

%% plot the Fit
figure(1)
clf
Fit = PF(paramsValues,x);
plot(StimLevels,PropCorrectData,'k.','Markersize',40);
set(gca,'Fontsize',12);
hold on;
%the following line doesn't work for me coz pmf.gamma doesnt exist:
% plot(x,PF([pmf.alpha(chain) 10.^(pmf.beta(chain)) pmf.gamma(chain) pmf.lambda(chain)],x),'k','linewidth',3)
    hold on;
plot(x,Fit,'g-','Linewidth',3);
plot(x,PF([searchGrid.alpha searchGrid.beta searchGrid.gamma searchGrid.lambda],x),'r-','Linewidth',3);
legend('data point','PAL Fit','InitialValues')
hold off;

    
    