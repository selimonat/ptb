function [t_pulse,value]=WaitPulseStrictlyAfterNow(port,n)
%[t_pulse,value]=WaitPulseStrictlyAfterNow(port,n)
%
%   OBSOLETE (see WaitPulse.m)
%
%This function waits for the Nth upcoming pulse. If N=1, it will wait for
%the very next pulse to arrive. 1 MEANS NEXT PULSE. So if you want to wait
%for 6 full dummy scans, you should use N = 7 to be sure that at least 6
%full scans are finished. T_PULSE is the timestamp of the last
%pulse in case N is >1.
%
%If there are however pulses that were already waiting in the
%buffer before you called this function additional measures has to
%be taken. Therefore this function do not considers all the pulses
%that were received right after the call of this function. This
%costs us an additional IF loop..
%
%It expects that the serial port handle is a global variable.
%
%Selim Onat, 24-Jan-2013 10:55:53




value   = [];
t_now   = GetSecs;%this is the time this function is called, we require that the pulse
%which is detected to arrive later than this time.
pulse   = 0;%pulse counter
t_pulse = t_now;%if n=0, that is no wait for pulse, than pulse arrival is now...

while pulse < n
    ok =1;
    while ok
        %read data with a granularity of 2 in a blocking way...
        [value, t_pulse] = IOPort('Read', port,1,2);
        if t_pulse > t_now%only consider pulses that arrives strictly after the call of this function.
            ok = 0;
            %Log(t_pulse,0,NaN);%log the scan onset, this is done
            %outside
        end
    end
    fprintf('Pulse Detected at %g\nValue is [%d %d]\n',t_pulse,value(1),value(2));
    pulse = pulse + 1;
end
