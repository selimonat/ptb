function SendPulses(N,TR)
%function SendPulses(N)
%
%Sends N pulses to COM2 serial port. TR is the interpulse TR (that is
%the "TR").
%
%Selim Onat, 24-Jan-2013 10:55:53

IOPort('CloseAll')
box.port = IOPort('OpenSerialPort', 'COM2');
counter  = 0;
%
t        = GetSecs;%now
t        = (t+TR):TR:(t+TR*N);%time of the future pulses
for n = 0:N-1
    counter = counter +1;
    tobesent = [floor(n./255) rem(n,255)];%two byte to be sent   
    WaitSecs('untiltime',t(counter));%wait and fire.
    [~,t_]=IOPort( 'Write' , box.port , [char(tobesent(1)+1), char(tobesent(2)+1)]);
    
    fprintf('Pulse No: %3d sent at %0.10g was due to at %0.10g\n',n,t_,t(counter));
    drawnow%give some time for Control-C
end