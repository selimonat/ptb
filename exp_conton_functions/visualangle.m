function [ px ] = visualangle( desang,init )
%UNTITLED Summary of this function goes here
%   resolution should be a vector with [horizontal,vertical]
%   init should be a structure with field p2.hostname specifying the host

resolution = init.p2.rect(1,3:4);
switch init.p2.hostname
    case 'triostim1'
        warning('remeasure ET params!')
        if resolution(1) ~= 1024
            warning('Resolution not as expected. Image size might deviate from requested visual angle')
        end
        vdist = 94.5;
        screen_width = 38;
        
    case 'etpc'
        warning('remeasure ET params!')
        
        vdist = 50;
        screen_width = 40.7;
        
    case 'isnf01faf2bafa4'

        vdist = 55;
        switch init.p2.whichmonitor
            case 's'
            screen_width = 31;
            case 'l'
            screen_width = 51.5;
            case 'e'
                 vdist = 50;
            screen_width = 40.7;
        
        end
    otherwise
        error('add behavioral lab')       
end

cm = tand(desang)*vdist;
px = cm/(screen_width/resolution(1));

end


