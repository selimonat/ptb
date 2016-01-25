function [secs]=WaitPulse(n,device)
%[secs]=WaitPulse(keycode,n)
%
%   This function waits for the Nth upcoming pulse. If N=1, it will wait for
%   the very next pulse to arrive. 1 MEANS NEXT PULSE. So if you wish to wait
%   for 6 full dummy scans, you should use N = 7 to be sure that at least 6
%   full acquisitions are finished.
%
%   The function avoids KbCheck, KbWait functions, but relies on the OS
%   level event queues, which are much less likely to skip short events. A
%   nice discussion on the topic can be found here: 
%   http://ftp.tuebingen.mpg.de/pub/pub_dahl/stmdev10_D/Matlab6/Toolboxes/Psychtoolbox/PsychDocumentation/KbQueue.html

try %to relase running queue
    KbQueueCheck;
    queuerunning = 1;
    KbQueueRelease(device);
catch %notice no queue was running
    queuerunning = 0;
end

KbQueueCreate(device,KbName('5%'));
KbQueueStart(device);

secs  = nan(1,n);
pulse = 0;
while pulse < n
    KbQueueFlush(device,3);
    secs(pulse+1) = KbQueueWait(device);
    pulse         = pulse + 1;
end

KbQueueRelease(device);

if queuerunning == 1
    KbQueueCreate(device);
end
