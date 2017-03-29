function [contrast, lums] = grating_test(gTmp)
small_window =0;
commandwindow; %focus on the command window, so that output is not written on the editor
p = struct();
SetParams;%set parameters of the experiment
SetPTB;%set visualization parameters.
lums = [];
ks = 50;
Screen('LoadNormalizedGammaTable', p.ptb.w, gTmp);
for k = 1:10
    vbl = Screen('Flip', p.ptb.w);  %<----- FLIP
end
contrast = [0, 150, 0, 150, 0, 150, 0, 150, 0, 150];
Screen('FillRect',p.ptb.w, 128);
vbl = Screen('Flip', p.ptb.w);  %<----- FLIP

lums = [];
fprintf('Waiting')
waitforbuttonpress

for k = 1:length(contrast)
    Screen('LoadNormalizedGammaTable', p.ptb.w, gTmp);

    Screen('FillRect',p.ptb.w, 128);
    
    draw_stimulus(p, contrast(k))
    vbl = Screen('Flip', p.ptb.w);  %<----- FLIP
    lums = [lums, luminance()];
    lums;
end
%contrast = [-0.1, contrast];
sca

    function draw_stimulus(p, contrast)
        stim_id = 1;
        angle = 90*stim_id;
        df = p.ptb.rect(3) -  p.ptb.rect(4);
        rect = [df/2., 0, p.ptb.rect(4)+df/2, p.ptb.rect(4)];
        Screen('DrawTexture', p.ptb.w, p.ptb.gabortex, [], rect, ...
            angle, [], [], [], [], [], [0, p.stim.sf, contrast, 100, 1, 0, 0, 0]);
        oc = [p.ptb.midpoint(1)-25, p.ptb.midpoint(2)-25, p.ptb.midpoint(1)+25, p.ptb.midpoint(2)+25];
        %Screen('FillOval', p.ptb.w, p.stim.bg, oc);
        %draw also the fixation cross
    end



    function SetParams
        %% %%%%%%%%%%%%%%%%%%%%%%%%%
        p.stim.bg                   = [128, 128, 128];
        p.stim.white                = get_color('white');
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;
        p.text.fixsize                 = 60;
        
        
    end


    function SetPTB
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %%Find the number of the screen to be opened
        screens                     =  Screen('Screens');
        p.ptb.screenNumber          =  min(screens);%the maximum is the second monitor
        
        %set the resolution correctly
        res = Screen('resolution', p.ptb.screenNumber);
        HideCursor(p.ptb.screenNumber);%make sure that the mouse is not shown at the participant's monitor
        
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        if ~small_window
            [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, [0.5, 0.5, 0.5]);
        else
            [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, [128, 128, 128], [0, 0, 1000, 500]);
        end
        
        %Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        
        %find the mid position on the screen.
        x = p.ptb.rect(1) + (p.ptb.rect(3)/2);
        y = p.ptb.rect(2) + (p.ptb.rect(4)/2);
        
        p.ptb.midpoint              = [x, y] % p.ptb.width./2 p.ptb.height./2];
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);
        p.ptb.CrossPosition_y       = p.ptb.midpoint(2);
        %cross position for the eyetracker screen.
        p.ptb.fc_size               = 10;
        
        Priority(MaxPriority(p.ptb.w));
        
        %% Build a procedural gabor texture for a gabor with a support of tw x th
        % pixels, and a RGB color offset of 0.5 -- a 50% gray.
        p.display.ppd = 60;
        p.stim.radius = p.ptb.rect(4)/2;
        p.stim.sf = 2/p.display.ppd;
        fprintf('R and SF: %f %f', p.stim.radius, p.stim.sf)
        %p.ptb.gabortex = CreateProceduralGabor(p.ptb.w, p.ptb.width, p.ptb.height, 0, [0.5 0.5 0.5 0.0]);
        p.ptb.gabortex = CreateProceduralSineGrating(p.ptb.w, 2*p.stim.radius, 2*p.stim.radius,...
            [0.5, 0.5, 0.5, 0.5], p.stim.radius);
    end



end