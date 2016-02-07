function [out]=degree2pixel(where,in,direction)
%[out]=degree2pixel(where,in,direction)
%
%
%   Will return approximate number of pixels/degrees that corresponds to a given
%   degree/pixels on the monitors used in the scanner or eyelab.
%
%   If DIRECTION is deg2pix, degrees are transformed to pixels, for the
%   inverse transformation use pix2deg.
%
%	IN/OUT depending on the direction are in units of cm or pixels.
%
%   Example:
%   degree2pixel('scanner',6,1) will return the number of pixels
%   corresponding to 6 degrees in the scanner monitor.
%
%   Selim Onat.

if strcmp(where,'scanner')    
    distance2monitor  = 94.5;%cm
    left2right.metric = 38.2;%cm
    left2right.pixel  = 1024;%native PLCXP200L resolution
    angular_span      = atand((left2right.metric/2)./distance2monitor)*2;%pixels per degree
    pixelperdegree    = left2right.pixel/angular_span;    
elseif strcmp(where,'eyelab')    
    distance2monitor  = 50;%cm
    left2right.metric = 40.7;%cm
    left2right.pixel  = 1600;%native PLCXP200L resolution
    angular_span      = atand((left2right.metric/2)./distance2monitor)*2;%pixels per degree
    pixelperdegree    = left2right.pixel/angular_span;
end

if strcmp(direction,'deg2pix'); %degree 2 pixels
    out           = pixelperdegree*in;
else strcmp(direction,'pix2deg'); %degree 2 pixels
    out           = 1./pixelperdegree*in;
end
