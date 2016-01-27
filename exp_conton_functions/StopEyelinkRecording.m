function [t]=StopEyelinkRecording
Eyelink('StopRecording');
t = GetSecs;
%this is the end of the trial scope.
WaitSecs(0.01);
Eyelink('Message', 'TRIAL OK');
WaitSecs(0.01);
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.01);
Eyelink('Command', 'clear_screen %d', 0);

