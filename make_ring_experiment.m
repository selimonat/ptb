function params = make_ring_experiment()
%% Create a VistaDisp retinotopy experiment
params = struct()
params.experiment= 'expanding ring (45% duty)';
params.fixation= 'double disk';
params.modality= 'fMRI';
params.savestimparams= 1;
params.repetitions= 1;
params.runPriority= 7;
params.skipCycleFrames= 0;
params.prescanDuration= 0;
params.period= 24;
params.numCycles= 1;
params.motionSteps= 8;
params.tempFreq= 2.5000;
params.contrast= 1;
params.interleaves= [];
params.tr= 0.8000;
params.loadMatrix= [];
params.saveMatrix= [];
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