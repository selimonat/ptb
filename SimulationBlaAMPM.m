% NP (September 2009)

clear all;  %Clear all existing variables from memory

if exist('OCTAVE_VERSION');
    fprintf('\nUnder Octave, Figure does not render exactly as intended. Visit\n');
    fprintf('www.palamedestoolbox.org/demosfiguregallery.html to see figure\n');
    fprintf('as intended.\n\n');
end

%Set up Psi Method procedure:

%Define prior
priorAlphaRange = linspace(0,120,100); %values of alpha to include in prior
priorBetaRange =linspace(-2,2,100);;  %values of log_10(beta) to include in prior

%Stimulus values to select from (need not be equally spaced)
stimRange = linspace(0,180,100);
                            
%2-D Gaussian prior
prior = repmat(PAL_pdfNormal(priorAlphaRange,60,1000000), ...
    [length(priorBetaRange) 1]).* repmat(PAL_pdfNormal...
    (priorBetaRange',0,1000000),[1 length(priorAlphaRange)]);

prior = prior./sum(sum(prior)); %prior should sum to 1

%Function to be fitted during procedure
PFfit = @PAL_CumulativeNormal;    %Shape to be assumed
gamma = 0.5;            %Guess rate to be assumed
lambda = .01;           %Lapse Rate to be assumed

%set up procedure
PM = PAL_AMPM_setupPM('priorAlphaRange',priorAlphaRange,...
    'priorBetaRange',priorBetaRange, 'numtrials',100, 'PF' , PFfit,...
    'prior',prior,'stimRange',stimRange,'gamma',gamma,'lambda',lambda);

%Show contour plot of posterior
figure('name','Psi Method Adaptive Procedure');
subplot(2,1,1)
contour(PM.pdf,15)  %PM.pdf stores the posterior (which at this point 
                    %is the prior)
h1 = gca;
set(h1,'FontSize',16, 'Xtick',[1:50:201], 'XtickLabel', {'-2','-1','0',...
    '1','2'}, 'Ytick',[1:25:101], 'YtickLabel', {'-1','-.5','0','.5','1'});
xlabel('Alpha');
ylabel('Log(Beta)');
drawnow

%Trial loop

while PM.stop ~= 1
 
TrueThreshold   = 45;
Noise           = 15;
  if PM.xCurrent > (TrueThreshold+randn(1)*Noise);
        response = 1;
  else
        response = 0;
  end
        PM = PAL_AMPM_updatePM(PM, response);

%     hold on
%     plot(PM.priorAlphaRange, PM.pdf,'color',[length(PM.x)/stoprule 0 1-length(PM.x)/stoprule])
%     drawnow;


    %Update plot
contour(priorAlphaRange,priorBetaRange,PM.pdf,10);    
    xlabel('Alpha');
    ylabel('Log(Beta)');
    drawnow
end
%Create simple plot of trial sequence:
subplot(2,1,2)
t = 1:length(PM.x)-1;
plot(t,PM.x(1:length(t)),'k');
hold on;
plot(1:length(t),PM.threshold,'b-','LineWidth',2)
plot(t(PM.response == 1),PM.x(PM.response == 1),'ko', ...
    'MarkerFaceColor','k');
plot(t(PM.response == 0),PM.x(PM.response == 0),'ko', ...
    'MarkerFaceColor','w');
set(gca,'FontSize',16);
maxinplot = max(max(PM.x),max(PM.threshold));
mininplot = min(min(PM.x),min(PM.threshold));
axis([0 max(t)+1 mininplot-(maxinplot-mininplot)/10 ...
    maxinplot+(maxinplot-mininplot)/10]);
line([1 length(PM.x)],TrueThreshold,'linewidth', 2,...
    'linestyle', '--', 'color','k');
xlabel('Trial');
ylabel('Stimulus Intensity');
%print Estimated Parameters on the Screen
fprintf('Estimated Threshold (alpha): %4.2f \n',PM.threshold(length(PM.threshold)))
fprintf('Estimated Slope (beta): %4.2f \n',PM.slope(length(PM.slope)));