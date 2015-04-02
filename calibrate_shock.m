%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%calibrate_shock

% (c) September 2011 by Benjamin Meyer

% sends out shock signals to the digitimer as long as 1 is entered.
                                                                                                           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

address     = hex2dec('378');  % address of lpt port ==>17876678
channel     = 8;              % open channels (128 = master)
shock_dur   = 50;               % shock duration
num_shocks  = 3;                % number of shocks within shock train

reply=1;

while reply == 1
    
    for j=1:num_shocks
        outp(address,channel);
        wait(shock_dur);
        outp(address,0);
    end
    
    reply = input('Continue ? (1 = yes, 0 = No) ');
    
end
