%Contextual Modulation of old/new effects%
%3-Nov-2015, n.herweg@uke.de

%% Initialization
%Timestamp
fileX.(thephase{phasei}).(thepart{parti}).timestamp = datestr(now,30);

%Preallocation
thescene{n.(thephase{phasei}).(thepart{parti}).trials} = 0;
fileX.(thephase{phasei}).(thepart{parti})(n.(thephase{phasei}).(thepart{parti}).trials,19)=0;

%Counterbalance keys
error('add eye link lab here and in other script')
error('add keys from button box')
switch init.hostname
    case 'triostim1'
        
    case 'isnf01faf2bafa4'
        
        switch fileX.keycond
            case '1'
                key.in    = KbName('LeftArrow');
                key.out   = KbName('DownArrow');
                key.old   = KbName('LeftArrow');
                key.new   = KbName('DownArrow');
            case '2'
                key.in    = KbName('LeftArrow');
                key.out   = KbName('DownArrow');
                key.old   = KbName('DownArrow');
                key.new   = KbName('LeftArrow');
            case '3'
                key.in    = KbName('DownArrow');
                key.out   = KbName('LeftArrow');
                key.old   = KbName('DownArrow');
                key.new   = KbName('LeftArrow');
            case '4'
                key.in    = KbName('DownArrow');
                key.out   = KbName('LeftArrow');
                key.old   = KbName('LeftArrow');
                key.new   = KbName('DownArrow');
        end
        key.space = KbName('Space');
        key.enter = KbName('Return');
end

%Load images for first block
for pici = 1:n.(thephase{phasei}).(thepart{parti}).t2b
    if fileX.(thephase{phasei}).(thepart{parti})(pici,6)<10
        thescene{pici} = uint8(imread(fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),['00',num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp'])));
    elseif fileX.(thephase{phasei}).(thepart{parti})(pici,6)>9 && fileX.(thephase{phasei}).(thepart{parti})(pici,6)<100
        thescene{pici} = uint8(imread(fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),['0',num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp'])));
    elseif fileX.(thephase{phasei}).(thepart{parti})(pici,6)>99
        thescene{pici} = uint8(imread(fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),[num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp'])));
    end
end

%Get text length to center text position
texttodraw{1,1} = 'Kurze Pause!';
texttodraw{2,1} = 'Achtung!';

for k = 1:size(texttodraw,1)
    [newx, ~]       = Screen('DrawText', init.expWin,texttodraw{k,1},init.mx, init.my, [0.5 0.5 0.5]);
    texttodraw{k,2} = init.mx-(newx-init.mx)/2;
    texttodraw{k,3} = init.my-60;
end
Screen('Close')

clear Inst insttexture trial newx newy k

%Create cover (needed due to incremental drawing of stimuli)
thecover = zeros(size(thescene{1}))+0.5;

%% Instruction
for k = inst2load.(thephase{phasei}).(thepart{parti})
    insttexture = Screen('MakeTexture',init.expWin,uint8(imread(fullfile(init.thepath.inst,['keycond',fileX.keycond],['Folie', num2str(k), '.png']))));
    Screen('DrawTexture',init.expWin,insttexture);
    Screen('Flip', init.expWin);
    Screen('Close')
    KbWait([], 2);
    clear insttexture
end

%Display the target
if strcmp(thephase{phasei},'p1')
    targstim  = unique(fileX.(thephase{phasei}).(thepart{parti})(fileX.(thephase{phasei}).(thepart{parti})(:,3)==1,[2,6]),'rows');
    targtrial{1} = fileX.(thephase{phasei}).(thepart{parti})(fileX.(thephase{phasei}).(thepart{parti})(:,2) == targstim(1,1) & fileX.(thephase{phasei}).(thepart{parti})(:,6) == targstim(1,2),1);
    targtrial{2} = fileX.(thephase{phasei}).(thepart{parti})(fileX.(thephase{phasei}).(thepart{parti})(:,2) == targstim(2,1) & fileX.(thephase{phasei}).(thepart{parti})(:,6) == targstim(2,2),1);
    targtexture = Screen('MakeTexture',init.expWin,[thescene{targtrial{1}(1)},uint8(ones(300,20,3).*255/2),thescene{targtrial{2}(1)}]);
    Screen('DrawTexture',init.expWin,targtexture);
    DrawFormattedText(init.expWin,'Dies sind deine Zielbilder. Drücke die Leertaste, sobald du eines dieser Bilder siehst!','center',init.my+200,[1 1 1]);
    t_targ = Screen('Flip', init.expWin);
    Screen('Close')
else
    t_targ = GetSecs-12;
end

%Show fix cross
fixcross = Screen('MakeTexture',init.expWin,FixCr);
Screen('DrawTexture',init.expWin,fixcross);
t_fix = Screen('Flip', init.expWin,t_targ+12);
Screen('Close')

clear targstim targtrial targettexture t_targ

%% Start trial loop
for trial=1:n.(thephase{phasei}).(thepart{parti}).trials
    
    %Break
    if rem(trial,n.(thephase{phasei}).test.t2b)==1 && trial>1%short break after every nth trial
        
        coverTexture = Screen('MakeTexture',init.expWin,thecover);%cover the fixation cross
        Screen('DrawTexture',init.expWin,coverTexture);
        Screen('DrawText', init.expWin, texttodraw{1,1},texttodraw{1,2},texttodraw{1,3}, [1 1 1]);
        fileX.(thephase{phasei}).(thepart{parti})(trial,11) = Screen('Flip', init.expWin, t_fix+time.(thephase{phasei}).fix-init.slack);%t_pause
        Screen('Close')
        
        clear t_fix
        
        %Load images for next block (timing & memory issue)
        for pici = trial:trial-1+n.(thephase{phasei}).(thepart{parti}).t2b
            if fileX.(thephase{phasei}).(thepart{parti})(pici,6)<10
                thescene{pici} = uint8(imread(fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),['00',num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp'])));
            elseif fileX.(thephase{phasei}).(thepart{parti})(pici,6)>9 && fileX.(thephase{phasei}).(thepart{parti})(pici,6)<100
                thescene{pici} = uint8(imread(fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),['0',num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp'])));
            elseif fileX.(thephase{phasei}).(thepart{parti})(pici,6)>99
                thescene{pici} = uint8(imread(fullfile(init.thepath.(['pics_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)}]),[num2str(fileX.(thephase{phasei}).(thepart{parti})(pici,6)),'_',thecat{fileX.(thephase{phasei}).(thepart{parti})(pici,2)},'.bmp'])));
            end
        end
        
        Screen('DrawText', init.expWin, texttodraw{2,1},texttodraw{2,2},texttodraw{2,3}, [1 1 1]);
        save(fullfile(init.thepath.results,fileX.fileName),'fileX');
        Screen('Flip', init.expWin,fileX.(thephase{phasei}).(thepart{parti})(trial,11)+37-init.slack);
        Screen('Close')
        
        fixcross = Screen('MakeTexture',init.expWin,FixCr);
        Screen('DrawTexture',init.expWin,fixcross);
        t_fix = Screen('Flip', init.expWin,fileX.(thephase{phasei}).(thepart{parti})(trial,11)+40-init.slack);
        Screen('Close')
    end
    
    %Instruction
    if phasei == 2 && rem(trial,n.(thephase{phasei}).(thepart{parti}).tpb)==1 %if this is the first trial of a block in phase 2 show instruction for the next block
        
        insttexture = Screen('MakeTexture',init.expWin,uint8(imread(fullfile(init.thepath.inst,['keycond',fileX.keycond],['Folie',num2str((9+fileX.(thephase{phasei}).(thepart{parti})(trial,4))),'.png']))));%4 encret 1 = enc; 2 = ret
        Screen('DrawTexture',init.expWin,insttexture);
        fileX.(thephase{phasei}).(thepart{parti})(trial,12) = Screen('Flip', init.expWin, t_fix+time.(thephase{phasei}).fix-init.slack);%t_instr
        Screen('Close')
        
        clear t_fix
                  
        fixcross = Screen('MakeTexture',init.expWin,FixCr);
        Screen('DrawTexture',init.expWin,fixcross);
        t_fix = Screen('Flip', init.expWin,fileX.(thephase{phasei}).(thepart{parti})(trial,12)+3-init.slack);
        Screen('Close')
    end
    
    %Scene presentation
    scenetexture = Screen('MakeTexture',init.expWin,thescene{trial});
    Screen('DrawTexture',init.expWin,scenetexture);
    [t_scene,sceneOnset] = Screen('Flip', init.expWin,t_fix+time.(thephase{phasei}).fix-init.slack,1);%show scene and keep it in the back buffer for presentation with analogue scale
    Screen('Close')
    clear scenetexture t_fix
    
    %Collect input
    if phasei ~= 3
        while GetSecs<sceneOnset+time.(thephase{phasei}).pic
            [keyIsDown, tKeyDown, keyCode]=KbCheck(init.device);
            if keyIsDown
                break
            end
        end
    else
        SetMouse(init.mx,init.my+250,init.screenNumber);
        ShowCursor('Hand');
        
        VASscale_mouse(init,0,fileX.keycond);
        
        while GetSecs<sceneOnset+time.(thephase{phasei}).pic
            [Xmouse,Ymouse,Bmouse]=GetMouse(init.expWin);
            if Bmouse(1) && ~exist('rating','var')%rating does not exist only at first call because no rating output is queried above (l.139)
                while Bmouse(1) && GetSecs<sceneOnset+time.(thephase{phasei}).pic %check position until mouse button is released again and keep that final position
                    [Xmouse,Ymouse,Bmouse]=GetMouse(init.expWin);
                    rating = VASscale_mouse(init,Xmouse,fileX.keycond);
                end
                if exist('rating','var') && ~Bmouse(1)
                    fin = GetSecs; %rating is finished
                end
            end
        end
    end
    
    %Scene offset
    coverTexture = Screen('MakeTexture',init.expWin,thecover);%cover image in the backbufer to display just the fix cross (and rating scale) with next flip
    fixcross = Screen('MakeTexture',init.expWin,FixCr);
    Screen('DrawTextures',init.expWin,[coverTexture,fixcross]);
    t_fix = Screen('Flip', init.expWin,t_scene+time.(thephase{phasei}).pic-init.slack, 1);
    Screen('Close')
    
    %If necessary go on collecting input
    if phasei ~= 3 && keyIsDown == 0  && time.(thephase{phasei}).pic<time.(thephase{phasei}).resp %if no key has been pressed within pic presentation and response period is longer than pic presentation
        while GetSecs<sceneOnset+time.(thephase{phasei}).resp
            [keyIsDown, tKeyDown, keyCode]=KbCheck(init.device);
            if keyIsDown
                break
            end
        end
    elseif phasei == 3 && exist('rating','var') && ~exist('fin','var') % if rating has been started but not finished
        while Bmouse(1) && GetSecs<sceneOnset+time.(thephase{phasei}).resp %check position until mouse button is released again and keep that final position
            [Xmouse,Ymouse,Bmouse]=GetMouse(init.expWin, Xmouse);
            rating = VASscale_mouse(init,Xmouse,fileX.keycond);
        end
        if exist('rating','var') && ~Bmouse(1)
            fin = GetSecs; %rating is finished
        end
    elseif phasei == 3 && ~exist('rating','var') % if rating has not been started
        
        VASscale_mouse(init,0,fileX.keycond);
        
        while GetSecs<sceneOnset+time.(thephase{phasei}).resp
            [Xmouse,Ymouse,Bmouse]=GetMouse(init.expWin);
            if Bmouse(1) && ~exist('rating','var')
                while Bmouse(1) && GetSecs<sceneOnset+time.(thephase{phasei}).resp %check position until mouse button is released again and keep that final position
                    [Xmouse,Ymouse,Bmouse]=GetMouse(init.expWin);
                    rating = VASscale_mouse(init,Xmouse,fileX.keycond);
                end
                if exist('rating','var') && ~Bmouse(1)
                    fin = GetSecs; %rating is finished
                    break
                end
            end
        end
    end
    
    %Save everything
    fileX.(thephase{phasei}).(thepart{parti})(trial,13) = t_fix;
    fileX.(thephase{phasei}).(thepart{parti})(trial,14) = t_scene;
    
    if (phasei == 3 && ~exist('fin','var')) || (phasei ~= 3 && keyIsDown == 0) %if still no button has been pressed
        fileX.(thephase{phasei}).(thepart{parti})(trial,8) = NaN;%no response
    elseif phasei ~=3 && size(find(keyCode),2) == 1
        fileX.(thephase{phasei}).(thepart{parti})(trial,8) = find(keyCode);
        fileX.(thephase{phasei}).(thepart{parti})(trial,9) = tKeyDown;
        fileX.(thephase{phasei}).(thepart{parti})(trial,10) = tKeyDown-sceneOnset;%reaction time
    elseif phasei == 1 && size(find(keyCode),2) ==1
        fileX.(thephase{phasei}).(thepart{parti})(trial,8) = find(keyCode);
        fileX.(thephase{phasei}).(thepart{parti})(trial,9) = tKeyDown;
        fileX.(thephase{phasei}).(thepart{parti})(trial,10) = tKeyDown-sceneOnset;%reaction time
    elseif phasei == 3 && exist('fin','var')
        fileX.(thephase{phasei}).(thepart{parti})(trial,8) = rating;% -1 certainly old, 1 certainly new
        fileX.(thephase{phasei}).(thepart{parti})(trial,9) = fin;
        fileX.(thephase{phasei}).(thepart{parti})(trial,10) = fin-sceneOnset;%reaction time
    elseif phasei ~= 3
        fileX.(thephase{phasei}).(thepart{parti})(trial,8)=888;%two buttons
    end
    
    clearvars -except fileX FixCr init inst2load key n parti phasei relnew t_fix thecat thecond thepart thescene time trial thephase texttodraw thecover
    thescene{trial}=[];
end

%% Finish this phase
save(fullfile(init.thepath.results,fileX.fileName),'fileX');

Screen('Flip', init.expWin);
if parti == 1;
    RestrictKeysForKbCheck(KbName('c'));
    insttexture = Screen('MakeTexture',init.expWin,uint8(imread(fullfile(init.thepath.inst,['keycond',fileX.keycond],'Folie12.png'))));
else
    RestrictKeysForKbCheck(KbName('m'));
    insttexture = Screen('MakeTexture',init.expWin,uint8(imread(fullfile(init.thepath.inst,['keycond',fileX.keycond],'Folie13.png'))));
end
Screen('DrawTexture',init.expWin,insttexture);
Screen('Flip', init.expWin);
Screen('Close')

KbWait([], 2);
RestrictKeysForKbCheck([]);

clearvars -except fileX FixCr init inst2load key n parti phasei relnew thecat thecond thepart time thephase