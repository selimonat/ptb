function textures = make_sample_stimuli()
% Adapt psychtoolbox's CalibrateMonitorPhotometer to show two stimuli at
% different locations and to read measurements from a color hug.
[~, hostname] = system('hostname');
hostname = hostname(1:end-1);

cachefile = sprintf('%s_noise_nassar_sample_spec.mat', hostname);
%if ~exist(cachefile, 'file')
    Screen('Preference', 'SkipSyncTests', 1);
    screenid = min(Screen('Screens'));
    psychlasterror('reset');
    luminances = [];
    
    % Open black window:
    white = WhiteIndex(screenid);
    black = BlackIndex(screenid);
    grey = white / 2;
    % Open the screen
    [win, p.ptb.rect] = Screen('OpenWindow', screenid, [grey, grey, grey], [0, 0, 500, 400]);
    stimuli = make_sample_textures(win, cachefile);
    %Screen('Close All');
    sca
%else
%    load(cachefile)
%end

for k = 1:300
    stimuli_small{k} = stimuli{k}(520:603, 890:1030,:);
end

textures = {};
mms = [];
while true
    [h, w] = size(stimuli{1});
    noise = rand(round(h), round(w))>0.5;
    noise_small = noise(520:603, 890:1030);
    crits = nan*ones(300,1);
    for jj = 1:300       
        mask = mean(stimuli_small{jj}, 3);
        mask = mask>mean(mask(:));                
        ms = mean(mask(:));    
        crit = sum(mask(:))/2;        
        m = sum(noise_small(mask));                
        crits(jj) =  abs(m-crit);                   
        %background = mask*0+128;
        %background(mask) = noise(mask)*255;
        %textures{jj} = background;        
    end
    mms = [mms mean(crits)];
    fprintf('Min dev: %d\n', min(mms))
    if min(mms) < 7
       break
    end    
end

for jj = 1:300
    mask = mean(stimuli{jj}, 3);
    mask = mask>mean(mask(:));    
    background = mask*0+128;
    background(mask) = noise(mask)*255;    
    textures{jj} = background(1080/2-200:1080/2+200, 1960/2-200:1960/2+200);
end

cachefile = sprintf('%s_nassar_sample_spec.mat', hostname);
save(cachefile, 'textures', '-v7.3');


    function stimuli= make_sample_textures(win, cachefile)
        [~, hostname] = system('hostname');
        hostname = hostname(1:end-1);
        
        stimuli = {};
        
        
        w = 500;
        h = 400;
        I = cat(3, ones(h, w)*0);
        numbers = {};
        for ii = 0:9
            txt = Screen('MakeTexture', win, I);
            Screen('TextSize', txt,  70);
            Screen('TextFont', txt, 'Courier');
            Screen('TextStyle', txt, 1);
            DrawFormattedText(txt, num2str(ii), 'center', 'center', [255, 255, 255]);                            
            imageArray=Screen('GetImage', txt);                                                            
            numbers{ii+1} = imageArray(400/2 -25: 400/2+25, 500/2-20:500/2+20); %#ok<AGROW>
        end
        save('numbers.mat', 'numbers', '-v7.3');
        
        w = 1960;
        h = 1080;        
        for ii = 1:300
            txt = ones(h, w)*0;
            hpos = 1080/2 + 15;
            xc = 1960/2;            
            xpos = [-75 -25 25];
            d = sprintf('%03i', ii);
            for k = 1:3            
                %size(txt( hpos:hpos+50, xc+xpos(k):xc+xpos(k)+40))
                %size(double(numbers{1+str2num(d(k))}))
                txt( hpos:hpos+50, xc+xpos(k):xc+xpos(k)+40) = double(numbers{1+str2num(d(k))});
            end            
            stimuli{ii} = txt; %#ok<AGROW>
        end
        
        save(cachefile, 'stimuli', '-v7.3');
        
        
    end


end