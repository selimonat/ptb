# About

This repo contains Matlab code for conducting experiments (fMRI, behavioral) using the (Psychophysics Toolbox)[http://psychtoolbox.org/].

The idea is that different experiments in the Institute for Systems Neuroscience at the UKE are generally very similar to each other. 
Most of the time they deal with similar problems such as collecting button presses with high precision, collecting scanner pulses, dealing with the eye-tracker device or the physio-computer for recordings of skin-conductance measurements. 

Therefore, relying on a previously used experimental code, to prepare one's own experiment is a big time saver. It helps avoiding mistakes whereas increases the code's performance overall.

This repo contains different experiments, you should choose the one that is most similar to yours (if necessary please contact sonat@uke.de) and start adapting that code to your purpose.

# Warning
For the maintanance of the repository please consider the following points.

1/ Do not put helper functions in the repository as separate files, but rather create a single self-containing code to run your experiment. This code must contain definitions of helper functions if wanted.

2/ Stimuli can be placed in the ```/bin``` folder. It is typically not nice to track binary files, therefore please keep  the number of stimulus files you want to track as minimal as possible.



