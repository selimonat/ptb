# ExperimentalCode

This repo contains Matlab code for conducting experiments (fMRI, behavioral) using psychophysics toolbox.

The idea is that different experiments in our lab are typically very similar to each other, especially for collecting button presses, collecting scanner pulses, dealing with eye-tracker, physio-computer. Therefore, starting from already running experiment is a big time saver. For this reason, this repo contains different experiments, you should choose the one that is most similar to yours (for this contact contributors) and start adapting that code to your purpose.

Please consider that,
1/ do not put helper functions in the repository as separate files, but rather create a single self-containing code to run your experiment. This code must contain definitions of helper functions.

2/ stimuli can be placed in the bin folder. It is typically not nice to track binary files, therefore please keep it minimal the number of stimulus files you want to track.



