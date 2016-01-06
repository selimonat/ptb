   function [t] = WaitForDummyScans(n,init)
   % Waits for pulses (signaled via the button box) from n dummy scans plus the pulse from the first scan S1 going into your analysis.
   % Returns time t of Scan S1.
   
   pulse=0;
   while pulse <=n
       [keyIsDown, t, keyCode] = KbCheck(init.device);
       if keyIsDown
           if find(keyCode) == KbName('5%');
               WaitSecs(0.1);
               keyIsDown   = [];
               keyCode     = [];
               pulse       = pulse+1;
               fprintf('This was scanner pulse number: %d \n', pulse);
           end
       end
   end
   
   end