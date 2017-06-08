function luminances = measure_sample_luminances()
% Adapt psychtoolbox's CalibrateMonitorPhotometer to show two stimuli at
% different locations and to read measurements from a color hug.
Screen('Preference', 'SkipSyncTests', 1);
screenid = min(Screen('Screens'));
psychlasterror('reset');
luminances = [];

o = load('vpixx_gamma_table');
gt = o.table;

% Open black window:
white = WhiteIndex(screenid);
black = BlackIndex(screenid);
grey = white / 2
% Open the screen
[win, p.ptb.rect] = Screen('OpenWindow', screenid, [grey, grey, grey])%, [0, 0, 1000, 500]);
[old_table] = Screen('LoadNormalizedGammaTable', win, gt);

sample_textures = make_sample_textures(win);

maxLevel = Screen('ColorRange', win);
Screen('Flip',win);
draw_prd_sample(ii);
Screen('Flip', win);
%KbPressWait();
WaitSecs(25);
bgcolors = linspace(0,1,300)*255;
samples = 1:300;
for ii = 1:length(bgcolors)
    Screen('FillRect', win, [bgcolors(ii), bgcolors(ii), bgcolors(ii)]);
    Screen('Flip', win);
    WaitSecs(0.1);
    luminances = [luminances, luminance()]; %#ok<AGROW>
    Screen('FillRect', win, [grey grey grey]);
    draw_prd_sample(samples(ii));
    Screen('Flip', win);
    WaitSecs(0.1);
    luminances = [luminances, luminance()]; %#ok<AGROW>
end


RestoreCluts;
Screen('CloseAll');




    function draw_prd_sample(sample)
        Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('DrawTexture',   win, sample_textures(sample));
        Screen('BlendFunction', win, 'GL_ONE', 'GL_ZERO');
    end

    function textures = make_sample_textures(win)
        [~, hostname] = system('hostname');
        hostname = hostname(1:end-1);
        cachefile = sprintf('%s_nassar_sample_spec.mat', hostname);
        stimuli = {};
        
        stimuli = load(cachefile);
        stimuli = stimuli.textures;
        
        %noise = (noise>mean(noise(:)));
        textures = [];
        for ii = 1:300
            stim = stimuli{ii};
            stim = cat(3, stim, (~(stim==128))*255);
            txt = Screen('MakeTexture', win, stim);
            textures = [textures, txt]; %#ok<AGROW>
        end
        p.stim.sample_textures = textures;
    end


end