function [d]=feargenET_PFfitting_SimulationPSImargYN(alphas,SDs,total_trials,logname)
%
% This function simulates the PF Fitting Process PAL_AMPM for different
% alphas (i.e. thresholds), betas (in SD units) and trials per fitting process (total_trials).
% Output is the difference of the estimated parameter alpha/beta from the
% 'true' parameter given as input above.
%
% This tries to recover subject parameters using the PSI marginal
% method, and a YesNo Experiment. Thus Guess Rate and Lapse Rate are not
% fixed but marginalized, and vary from one simulation run to the next
% (capital Lambda / Gamma)


tSimulation     = 10;
%% Define prior, these are always the same so defining once is enough.
prioraaRange    = linspace(0,100,50); %values of aa to include in prior
%IS THIS RANGE OF BETA VALUES REASONABLE?
priorBetaRange  = linspace(-2,0,50);  %values of log_10(beta) to include in prior
%Range of lapse rates for the marginalized estimation of lambda
%Prins(2013) uses 0:0.01:0.1;
priorLambdaRange = 0:0.01:0.1;
%Range of guess rates (Prins: 0:0.03:0.3);
priorGammaRange = 0:0.03:0.3;
% Stimulus values to select from (need not be equally spaced)
stimRange       = 0:11.25:100;
% % conversion of parameter: SD to precision
% beta            = 1./SDs;
% % 2-D Gaussian prior
% prior           = repmat(PAL_pdfNormal(prioraaRange,60,1000),[length(priorBetaRange) 1]).* repmat(PAL_pdfNormal(priorBetaRange',0,4),[1 length(prioraaRange)]);
% prior           = prior./sum(prior(:)); %prior should sum to 1
% Function to be fitted during procedure
PFfit           = @PAL_CumulativeNormal;    %Shape to be assumed

%% generator parameters
% Lambdas         = [0 .025 .05 .1];
% Gammas          = [0 .1 .2 .3];
Lambdas =[0.02];
Gammas  =[0.1];
%% init the output variable
talpha        = length(alphas);
tSDs          = length(SDs);
ttotal_trials = length(total_trials);
Init_var;
%%
c = zeros(1,3);%[tt_c aa_c ss_c ];%counters
for tt = total_trials(:)';%how many trials for the "subject"
    c(1) = c(1) + 1;
    c(2) = 0;
    %the same procedure can be used again without recreating it as it only
    %depends on tt. 
    dummy = PAL_AMPM_setupPM('prioraaRange',prioraaRange,...
        'priorBetaRange',priorBetaRange, 'priorLambdaRange',...
        priorLambdaRange,'priorGammaRange',priorGammaRange, 'numtrials',tt,...
        'PF' , PFfit, 'stimRange',stimRange,        'marginalize', [3 4]);
   
    for aa = alphas(:)';%subjects with different alpha and beta values
        c(2) = c(2) +1;
        c(3) = 0;
        for ss = SDs(:)'
            c(3) = c(3) +1;
            c(4) = 0;            
            %verbose            
            fprintf('TotalTrial: %3.3g (%3d/%3d); Alpha: %3.3g (%3d/%3d); SD: %3.3g (%3d/%3d); %s; \n',tt,c(1),ttotal_trials,aa,c(2),talpha,ss,c(3),tSDs,datestr(now,'HH:MM:SS'))
            aaa = NaN(1,tSimulation);
            sss = aaa; 
            xxx = NaN(length(stimRange),tSimulation);
            for simulation_repeat = 1:tSimulation;%how many simulation runs
                fprintf('Simulation Run No %g\n',simulation_repeat);
                %take a different lambda per subject
                Lambda = Lambdas(mod(simulation_repeat-1,length(Lambdas))+1);
                Gamma  = Gammas(mod(simulation_repeat-1,length(Gammas))+1);
                %%
                PM = dummy;%reuse 
                %% simulation proper
                while ~PM.stop            
                    %subject's response
                    response = ObserverResponseFunction(PFfit,aa,1/ss,Gamma,Lambda,PM.xCurrent);
                 
                    % update the PM
                    PM = PAL_AMPM_updatePM(PM,response);
                end
                %% store the differences
                aaa(simulation_repeat) = PM.threshold(end);
                sss(simulation_repeat) = 1./(10^(PM.slope(end)));
                lll(simulation_repeat) = PM.lapse(end);
                ggg(simulation_repeat) = PM.guess(end);
                ll(simulation_repeat)  = Lambda;
                gg(simulation_repeat)  = Gamma;
                xx=NaN(length(stimRange),1);
                for i=1:length(stimRange)
                    xx(i)=length(find(PM.x==stimRange(i)));
                end
                
                    
                xxx(:,simulation_repeat)  = xx;
            end
            d.nxmean=xxx;
            %store the estimated parameters
            d.alpha(:,c(2),c(3),c(1))          = aaa;
            d.sd(:,c(2),c(3),c(1))             = sss;
            d.guess(:,c(2),c(3),c(1))          = ggg;
            d.lapse(:,c(2),c(3),c(1))          = lll;
            d.nxmean(:,c(2),c(3),c(1))         = xx;
            %store the (real) used parameters
            d.param.alpha(:,c(2),c(3),c(1))    = aa;
            d.param.sd(:,c(2),c(3),c(1))       = ss;
            d.param.guess(:,c(2),c(3),c(1))    = gg;
            d.param.lapse(:,c(2),c(3),c(1))    = ll;
            d.param.ttrials(:,c(2),c(3),c(1))  = tt;
            %%save the stuff
            try
                if ispc
                    save_path        ='C:\Users\onat\Dropbox\feargen_lea\EthnoMaster\simdata\';
                elseif ismac
                    save_path        ='/Users/onat/Desktop/';    
                elseif isunix
                    save_path        ='/home/kampermann/Documents/simdata/';                
                end
                save(sprintf('%sd_PSImargYN_%s_%s.mat',save_path,logname,datestr(now,'yyyymmdd_HHMM')),'d');
            catch
                fprintf('Cannot save here...\n');
            end
            
           
        end
    end
end

    function Init_var        
        d.alpha          = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.sd             = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.guess          = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.lapse          = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.param.alpha    = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.param.sd       = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.param.guess    = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.param.lapse    = NaN(tSimulation,talpha,tSDs,length(total_trials));
        d.param.ttrials  = NaN(tSimulation,talpha,tSDs,length(total_trials));
    end
end
