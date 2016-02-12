function [ sequenceComp,targetMatX,targetMatY  ] = calibratePupil(areaSize,sampGrid,win,nrep,initel,mx,my,inst,imgpath,device)
%UNTITLED Summary of this function goes here
%   areaSize should give the size of the area that should be covered as
%   [x,y]
%   sampGrid should be a matrix of ones(size(x,y)) with x*y = nsamples
%   acquired
%   init should be a structure with fields mx and my giving the midpoint of
%   the screen in pixels


% Display the instruction
insttexture = Screen('MakeTexture',win,uint8(imread(inst)));
Screen('DrawTexture',win,insttexture);
Screen('Flip', win);
Screen('Close');

% Wait for a button press
KbWait(device,2);

% Start recording
Eyelink('Message', 'TRIALID: %04d, NEWOLD: %d, ENCRET: %d, FIXX: %04d, FIXY %04d', 0, 0, 0, mx,my);
% an integration message so that an image can be loaded as
% overlay background when performing Data Viewer analysis.
WaitSecs(0.01);
Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', imgpath,mx, my);

% This supplies the title at the bottom of the eyetracker display
Eyelink('Command', 'record_status_message "Stim: %02d"', 0);

%Put the tracker offline and draw the stimuli.
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.01);

%clear tracker display and draw box at center
Eyelink('Command', 'clear_screen %d', 0);

%start recording following mode transition and a short pause.
Eyelink('Command', 'set_idle_mode');
WaitSecs(0.01);

Eyelink('StartRecording');
WaitSecs(0.1);

resolution = Screen('Resolution', win);
% Create a matrix with x and y coordinates of targets to be displayed
targetMatX = repmat(round(linspace(mx-areaSize(2)/2,mx+areaSize(2)/2,size(sampGrid,2))),size(sampGrid,1),1);
targetMatY = repmat(round(linspace(my-areaSize(1)/2,my+areaSize(1)/2,size(sampGrid,1))),size(sampGrid,2),1)';

targetImg = ones(resolution.height,resolution.width)/2;
for repi = 1:nrep
    % Randomise targets
    sequence = (1:size(targetMatX,1)*size(targetMatX,2))';
    sequence(:,2) = rand(1,size(sequence,1));
    sequence = sortrows(sequence,2);
    sequenceComp(:,repi) = sequence(:,1);
    for targeti = sequence(:,1)'
        % Save an image with all targets for overlaying
        rect(targeti,:) = EyelinkDrawCalTarget(initel, targetMatX(targeti), targetMatY(targeti));
        Eyelink('Message', 'Stim Onset');
        Eyelink('Message', 'SYNCTIME');
        circ = Ellipse((rect(targeti,3)-rect(targeti,1)+1)/2);
        targetImg(rect(targeti,2):rect(targeti,4),rect(targeti,1):rect(targeti,3)) = circ;
        WaitSecs(2);
    end
end

imwrite(targetImg,imgpath);

StopEyelinkRecording;

DrawFormattedText(win, 'Kalibrierung beendet. Gleich startet das Experiment','center','center');
Screen('Flip',win);
display('Press space to continue');

RestrictKeysForKbCheck(KbName('space'));
KbWait(device, 2);
RestrictKeysForKbCheck([]);
Screen('Flip',win);

end

