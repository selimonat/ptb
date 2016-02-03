function rating = VASscale_mouse(init,mouse_input,keycond)
%Presents sliding scale with a slider that moves along the scale
%according to move_slider input (1 = move right, -1 = move left, 0 = stay)
%Returns slider_position_now, which is to be input as slider_position_old
% the next time sliding_scale is called.

%prepare everything
scale_length_pix     = 1001; %fun requires odd number of intervals
scale_middle         = (scale_length_pix+1)/2;
switch keycond
    case {'1','4'}
        scale_low_label      = 'Sicher Alt';
        scale_hi_label       = 'Sicher Neu';
    case {'2','3'}
        scale_low_label      = 'Sicher Neu';
        scale_hi_label       = 'Sicher Alt';
end
low_label_width      = RectWidth(Screen('TextBounds',init.p3.expWin,scale_low_label));
theSlider            = zeros(30,10);
theScale             = ones(5,scale_length_pix);
theMidpoint          = ones(10,3);
sliderTexture        = Screen('MakeTexture', init.p3.expWin, theSlider);
scaleTexture         = Screen('MakeTexture', init.p3.expWin, theScale);
midpointTexture      = Screen('MakeTexture', init.p3.expWin, theMidpoint);
scaleRect            = CenterRectOnPoint([1 1 size(theScale,2) size(theScale,1)],init.p3.mx,init.p3.my+init.p3.imgsizepix(1)/2+50);
midpointRect         = CenterRectOnPoint([1 1 size(theMidpoint,2) size(theMidpoint,1)],init.p3.mx,init.p3.my+init.p3.imgsizepix(1)/2+50);

%draw scale, question and labels
Screen('DrawText', init.p3.expWin, scale_hi_label,  init.p3.mx + scale_length_pix/2,                   init.p3.my+init.p3.imgsizepix(1)/2+50 + 24,   1);
Screen('DrawText', init.p3.expWin, scale_low_label, init.p3.mx - scale_length_pix/2 - low_label_width, init.p3.my+init.p3.imgsizepix(1)/2+50 + 24,   1);
Screen('DrawTexture',init.p3.expWin,scaleTexture,[],scaleRect);
Screen('DrawTexture',init.p3.expWin,midpointTexture,[],midpointRect);

if mouse_input
    %restrict input to scale
    if mouse_input < init.p3.mx - (scale_middle-1)
        mouse_input = init.p3.mx - (scale_middle-1) ;
    elseif mouse_input > init.p3.mx + (scale_middle-1)
        mouse_input = init.p3.mx + (scale_middle-1);
    end
    
    %get rating
    switch keycond
        case {'1','4'}
            rating = (mouse_input-init.p3.mx)/(scale_middle-1);
        case {'2','3'}
            rating = (init.p3.mx-mouse_input)/(scale_middle-1);
    end
    
    %draw rating slider
    sliderRect = CenterRectOnPoint([1 1 size(theSlider,2) size(theSlider,1)],mouse_input,init.p3.my+init.p3.imgsizepix(1)/2+50);
    Screen('DrawTexture',init.p3.expWin,sliderTexture,[],sliderRect);
    
    %present drawing
    Screen('Flip', init.p3.expWin,[],1);
    
    clearSliderTexture = Screen('MakeTexture', init.p3.expWin, theSlider+0.5);
    Screen('DrawTexture',init.p3.expWin,clearSliderTexture,[],sliderRect);
else
    %present drawing
    Screen('Flip', init.p3.expWin,[],1);
    %invalid rating
    rating = NaN;
end
end