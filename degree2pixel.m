function [pixel]=degree2pixel(where,deg)
%[pixel]=degree2pixel(where,deg)
%
%
%   Will return approximate number of pixels that corresponds to a given
%   degree of visual angle in the scanner or eyelab.
%
%   Selim Onat.

if strcmp(where,'scanner')
    
    distance2monitor = 92;%cm
    left2right       = 31.4;%cm    
    angular_span     = atand((left2right/2)./distance2monitor)*2;%pixels per degree    
    pixelperdegree   = left2right/angular_span;    
    pixel            = pixelperdegree*deg;
    
elseif strcmp(where,'eyelab')
    
end