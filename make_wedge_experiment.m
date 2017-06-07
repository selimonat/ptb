function params = make_wedge_experiment()
%% Create a VistaDisp retinotopy experiment 

params = struct();
params.experiment= 'rotating wedge (45deg duty)';
params.fixation= 'double disk';
params.modality= 'fMRI';
params.savestimparams= 1;
params.repetitions= 1;
params.runPriority= 7;
params.skipCycleFrames= 0;
params.prescanDuration= 0;
%params.period= 192;
params.period= 24;
params.numCycles= 1;
params.motionSteps= 8;
params.tempFreq= 2.5;
params.contrast= 1;
params.interleaves= [];
params.tr= 0.8;
%params.loadMatrix= '/Users/nwilming/u/flexible_rule/experiment/retinotopy/forward_retino_stim.mat';
params.loadMatrix=[];
params.saveMatrix= '/Users/nwilming/u/flexible_rule/experiment/retinotopy/forward_retino_stim.mat';
params.calibration= [];
params.stimSize= 'max';
params.countdown= 0;
params.startScan= 0;
params.trigger= 'Scanner triggers computer';
params.triggerKey= '5';
params.calibration = 'NNL_UKE';
params.calibration = 'Larry';

% now set rest of the params
params = setRetinotopyParams(params.experiment, params);

% set response device
params = setRetinotopyDevices(params);
end