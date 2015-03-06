function [d]=feargenET_PFfitting_Simulation(alphas,SDs,total_trials)
%% explain here what is happening.
% This function simulates the PF Fitting Process PAL_AMPM for different
% slphas (i.e. thresholds), betas (in SD units) and trials per fitting process (total_trials).
% Output is the difference of the estimated parameter alpha/beta from the
% 'true' parameter given as input above.


run = 0;
for simulation_repeat = 1:100;%how many simulation runs
    run = run + 1;
    fprintf('Simulation run: %g \n',run)
    tt_c = 0;
    for tt = total_trials(:)';%how many trials for the "subject"
        tt_c = tt_c +1;
        aa_c = 0;
        for aa = alphas(:)';%subjects with different alpha and beta values
            aa_c = aa_c +1;
            ss_c = 0;
            for ss = SDs(:)'
                ss_c = ss_c + 1;
                %% run the simulation
                [difference]=feargenET_PFfitting_SimulationCore(tt, aa, ss);
                %% store the differences
                d.alpha(run,aa_c,ss_c,tt_c) = difference(1);
                d.sd(run,aa_c,ss_c,tt_c)    = difference(2);
            end
        end
    end
    save_path='C:\Users\onat\Documents\GitHub\ExperimentalCode\simdata\';
    save(sprintf('%sd%s.mat',savepath,datestr(now,'yyyymmdd_HHMM')),'d');
end
%%
    function [difference]=feargenET_PFfitting_SimulationCore(tt, aa, ss)
        %% This function estimates alpha and beta for the given parameters.
        %tt is number of trials run to estimate, aa and ss the 'true'
        %threshold/sd.
%         
        
        %% conversion of parameter
%         beta = log10(1./ss);
        beta = (1./ss);
        %% Define prior
        prioraaRange    = linspace(0,180,100); %values of aa to include in prior
        priorBetaRange  = linspace(-5,5,100);  %values of log_10(beta) to include in prior
        
        %Stimulus values to select from (need not be equally spaced)
        stimRange = [0:11.25:180];
        
        %2-D Gaussian prior
        prior = repmat(PAL_pdfNormal(prioraaRange,60,60),[length(priorBetaRange) 1]).* repmat(PAL_pdfNormal(priorBetaRange',0,4),[1 length(prioraaRange)]);
        prior = prior./sum(sum(prior)); %prior should sum to 1
        
        
        %Function to be fitted during procedure
        PFfit = @PAL_CumulativeNormal;    %Shape to be assumed
        gamma  = 0.5;            %Guess rate to be assumed
        lambda = 0;           %Lapse Rate to be assumed
        
        %set up procedure
        PM = PAL_AMPM_setupPM('prioraaRange',prioraaRange,...
            'priorBetaRange',priorBetaRange, 'numtrials',tt, 'PF' , PFfit,...
            'prior',prior,'stimRange',stimRange,'gamma',gamma,'lambda',lambda);
        
        %%
        while ~PM.stop
            
            if PAL_CumulativeNormal([aa beta gamma lambda],PM.xCurrent) >= rand(1)
                response = 1;
            else
                response = 0;
            end
            %updating PM
            PM = PAL_AMPM_updatePM(PM,response);
        end
        
        %% compute the difference
        difference = [PM.threshold(end) - aa 1./(10^(PM.slope(end))) - ss];%in SD units
        
    end
end
