function [keycode, secs] = KbQueueDump(deviceIndex)
%[keycode, secs] = KbQueueDump(deviceIndex)
%
%
%   Will dump all the events accumulated in the queue.


fprintf('there are %03d events\n',KbEventAvail(deviceIndex));

while KbEventAvail(deviceIndex)    
    [evt, n]   = KbEventGet(deviceIndex);    
    n = n + 1;
    keycode(n) = evt.Keycode;
    pressed(n) = evt.Pressed;
    secs(n)    = evt.Time;
    fprintf('Event is: %d\n',keycode(n));
end
i           = pressed == 1;
keycode(~i) = []
secs(~i)    = [];
fprintf('there are %03d events found...\n',length(keycode));
