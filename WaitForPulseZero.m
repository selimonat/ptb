function [t_pulse,value]=WaitForPulseZero(port)
%[t_pulse,value]=WaitForPulseZero(port,n)
%
% OBSOLETE. Since the arrival of the Current Design system, pulses are
% treated as key presses. 



value   = [];
t_now   = GetSecs;%this is the time this function is called, we require that the pulse
%which is detected to arrive later than this time.

t_pulse = t_now;%if n=0, that is no wait for pulse, than pulse arrival is now...

ok =1;
while ok
    %read data with a granularity of 2 in a blocking way...
    [value, t_pulse] = IOPort('Read', port,1,2);
    if (t_pulse > t_now) && sum(value) == 0%only consider pulses that arrives strictly after the call of this function.
        ok = 0;
        %Log(t_pulse,0,NaN);%log the scan onset, this is done
        %outside
    end
end
fprintf('Pulse Detected at %g\nValue is [%d %d]\n',t_pulse,value(1),value(2));

