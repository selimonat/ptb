
PFsimul = @PAL_CumulativeNormal;
trueParams = [0 2 0.5 0.01];

alphas = linspace(0,180,4000);
prior  = PAL_pdfNormal(alphas,0,400); %Gaussian
%%
%Termination rule
stopcriterion = 'trials';
stoprule      = 20;

%Function to be fitted during procedure
PFfit    = @PAL_CumulativeNormal;    %Shape to be assumed
beta     = 1.5;               %Slope to be assumed
lambda   = 0.01;         %Lapse rate to be assumed
meanmode = 'mean';      %Use mean of posterior as placement rule

%set up procedure
RF = [];
face_shift  = [0 180 0 180];
circle_shift = [0 0 360 360];


RF = PAL_AMRF_setupRF('priorAlphaRange', alphas, 'prior', prior,...
    'stopcriterion',stopcriterion,'stoprule',stoprule,'beta',beta,...
    'lambda',lambda,'PF',PFfit,'meanmode',meanmode);

%%
figure;clf
while RF.stop ~= 1

    if RF.xCurrent > 45+randn(1)*20;
        response = 1;
    else
        response = 0;
    end
        RF = PAL_AMRF_updateRF(RF, RF.xCurrent, response);

    hold on
    plot(RF.priorAlphaRange, RF.pdf,'color',[length(RF.x)/stoprule 0 1-length(RF.x)/stoprule])
    drawnow;
    
end
hold off
figure
plot(RF.priorAlphaRange,cumsum(RF.pdf))