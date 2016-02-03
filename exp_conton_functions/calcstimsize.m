function [pixelyx] = calcstimsize(init, thephase, phasei)

desang = 16;
resolution = init.(thephase{phasei}).rect(1,3:4);

switch init.(thephase{phasei}).hostname
    case 'triostim1'
        warning('remeasure ET params!')
        
    case 'etpc'
        warning('remeasure ET params!')
        
        vdist = 50;
        screen_width = 40.7;
        
    case 'isnf01faf2bafa4'

        vdist = 55;
        switch init.(thephase{phasei}).whichmonitor
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

stim_cm = tand(desang) * vdist;
pixelx  = stim_cm /(screen_width/resolution(1));
pixely  = 300/500 * pixelx;%300/500 is the original size of the images in pixels
pixelyx = [pixely,pixelx];
        
