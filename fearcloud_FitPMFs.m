%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Goodness of Fit?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fitting functions again, using PAL_FIT
subject = 11;
run     = 1;
chain   = 1;

StimLevels = 0:11.25:180;

%get responses, and resulting PMF from PAL algorithm
responses = fearcloud_GetPMFresponses(subject,run,chain,'yes');
pmf       = isn_GetPMF(subject,run);


NumPos   = responses.yes; % number of "different" responses
OutOfNum = responses.num; % number of presentations at that level
% take the priors as search grid (gamma extended to .5, resolution very low
% for little Laptop of Lea's)
searchGrid.alpha = linspace(0,100,10);    %structure defining grid to
searchGrid.beta = 10.^[-2:0.1:0];       %search for initial values
searchGrid.gamma = linspace(0,0.5,10);
searchGrid.lambda = linspace(0,0.1,10);

%ooor use the params that PAL gave as results
%searchGrid = [pmf.alpha(chain) 10.^pmf.beta(chain) pmf.gamma(chain) pmf.lambda(chain)];
paramsFree = [1 1 1 1];
PF         = @PAL_CumulativeNormal;

%run the Fit!

[paramsValues LL exitflag output] = PAL_PFML_Fit(StimLevels, ...
    NumPos, OutOfNum, searchGrid, paramsFree, PF);

%plot the Fit
figure
PropCorrectData = NumPos./OutOfNum;
StimLevelsFine = [min(StimLevels):(max(StimLevels)- ...
                min(StimLevels))./1000:max(StimLevels)];
Fit = PF(paramsValues,StimLevelsFine);
plot(StimLevels,PropCorrectData,'k.','Markersize',40);
set(gca,'Fontsize',12);
hold on;
plot(x,...
        PF([pmf.alpha(chain) 10.^(pmf.beta(chain)) pmf.gamma(chain) pmf.lambda(chain)],x),'k','linewidth',3)
    hold on;
plot(StimLevelsFine,Fit,'g-','Linewidth',3);
legend('data point','PAL output','Fit')


    
    