function [t_pulse]=WaitPulse(n,port)
%[t_pulse]=WaitPulse(n,port)
%
%This function waits for the Nth upcoming pulse. If N=1, it will wait for
%the very next pulse to arrive. 1 MEANS NEXT PULSE. So if you want to wait
%for 6 full dummy scans, you should use N = 7 to be sure that at least 6
%full scans are finished.
%

t_now   = GetSecs;%this is the time this function is called, we require that the pulse
%which is detected to arrive later than this time.
pulse   = 1;%pulse counter
t_pulse = t_now;%if n=0, that is no wait for pulse, than pulse arrival is now...
while pulse <= n
    inpkt = [];
    while isempty(inpkt)
        %read data with a granularity of 2
        [inpkt, t_pulse] = IOPort('Read', port,0);
        if t_pulse < t_now%if the pulse arrived before t_now ignore it
            inpkt=[];
        end
    end
%     fprintf('Pulse Detected at %g\n',t_pulse)
    pulse = pulse + 1;
end
%fprintf('now was %g\n',t_now);
