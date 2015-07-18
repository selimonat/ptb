function [p]=exp_AmbiPilot(subject)
%[p]=exp_AmbiPilot(subject,csp,PainThreshold,nth)
%
%   Experiment for showing ambigous pictures to people :D.
%

if nargin ~= 1
    fprintf('Wrong number of inputs\n');
    keyboard;
end
%% %init all the variables
%Time Storage
TimeEndStim               = [];
TimeTrackerOff            = [];
TimeCrossOn               = [];
p_var_ExpPhase            = [];
p_var_event_count         = 0;
t                         = [];
nTrial                    = 0;
el                        = [];
p                         = [];
%
%% ListenChar(2);%disable pressed keys to be spitted around
commandwindow;
%clear everything
clear mex global functions
%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);
%
SetParams;
debug = 1;%debug mode
SetPTB;

%%
InitEyeLink;
WaitSecs(2);
%calibrate if necessary
if strcmp(p.hostname,'etpc');
    CalibrateEL;
end
%save again the parameter file
save(p.path.path_param,'p');
%% RUN THE EXPERIMENT PROPER
ShowInstruction(1,1);
ShowInstruction(2,1);
PresentStimuli;
%%
%get the eyelink file back to this computer
StopEyelink(p.path.edf);
%trim the log file and save
p.out.log = p.out.log(sum(isnan(p.out.log),2) ~= size(p.out.log,2),:);
%shift the time so that the first timestamp is equal to zero
p.out.log(:,1) = p.out.log(:,1) - p.out.log(1);
p.out.log      = p.out.log;%copy it to the output variable.
save(p.path.path_param,'p');
%
%move the file to its final location.
movefile(p.path.subject,p.path.finalsubject);
%close everything down
cleanup;


    function PresentStimuli
        %Enter the presentation loop and wait for the first pulse to
        %arrive.

        
        for nTrial  = 1:p.presentation.tTrial;
            %
            %Get the variables that Trial function needs.
            stim_id      = p.presentation.stim_id(nTrial);
            %
            fix          = p.presentation.CrossPosition(nTrial,:);
            ISI          = p.presentation.isi(nTrial);            
            prestimdur   = p.duration.prestim(nTrial);
            %prestimdur   = p_presentation_prestim_dur(nTrial);
            
            
            fprintf('%d of %d, S: %d, ISI: %d.\n',nTrial,p.presentation.tTrial,stim_id,ISI);
            %                                    
            KbQueueStart(p.ptb.device);%monitor keypresses...
            
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            Trial(nTrial, stim_id , fix);
            %
            ShowInstruction(3,1);
            %
            AskStimRating;
            %
            [keypressed, firstPress]=KbQueueCheck(p.ptb.device);
            
            
        end
    end
    function Trial(nTrial, stim_id , fix )
        
        %turn the eye tracker on
        StartEyelinkRecording(nTrial,stim_id,fix);
        %% Fixation Onset
        FixCross = [fix(1)-1,fix(2)-20,fix(1)+1,fix(2)+20;fix(1)-20,fix(2)-1,fix(1)+20,fix(2)+1];
        Screen('FillRect',  p.ptb.w, [255,255,255], FixCross');
        Screen('Flip',p.ptb.w);        
        Eyelink('Message', 'FX Onset at %d %d',fix(1),fix(2));
        WaitSecs(1.25);
        %
        iii = p.presentation.stim_id(nTrial);
        p.ptb.imrect  = [ p.ptb.midpoint(1)-p.stim.size(iii,2)/2 p.ptb.midpoint(2)-p.stim.size(iii,1)/2 p.stim.size(iii,2) p.stim.size(iii,1)];
        
        
        %% Draw the stimulus to the buffer
        if ~stim_id==0
            Screen('DrawTexture', p.ptb.w, p.ptb.stim_sprites(stim_id));
        end        
        Screen('DrawingFinished',p.ptb.w,0);
        
        %% STIMULUS ONSET
        %Here we wait only for the next pulse.
        %The proper amount is obtained with the second call of WaitPulse
        %below, before the onset of the fixation cross.
        %fprintf('Will Wait for the pulse to Stim Onset\n');
        Screen('Flip',p.ptb.w);%asap and dont clear
        %send eyelink and ced a marker asap
        Eyelink('Message', 'Stim Onset');
        Eyelink('Message', 'SYNCTIME');
        
        %wait for the key press
        [p.out.PressingTime(nTrial),~,p.out.deltaSecs(nTrial)]=KbWait([],2);
        
        %% STIM OFF immediately after key press
        Screen('Flip',p.ptb.w);
        WaitSecs(.5);
        %send eyelink a marker
        Eyelink('Message', 'Stim Offset');
        Eyelink('Message', 'BLANK_SCREEN');        
        %
        %% record some more eye data after stimulus offset.        
        StopEyelinkRecording;
        
    end
    function SetParams
        
        %
        p.var.timings                 = zeros(1,10);
        p_var_event_count             = 0;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\onat\Experiments\';
        elseif strcmp(p.hostname,'etpc')
            p.path.baselocation       = 'C:\Users\onat\Documents\Experiments\';
        else
            p.path.baselocation       = '~/Documents/BehavioralExperiments/2015_Ambipilote/';
        end
        
        p.path.experiment             = [p.path.baselocation 'AmbiPilot' filesep];
        p.path.stim                   = '~/Dropbox/SelimTimTim/AmbiPain/app_stimulus_set/';
        %
        p.subID                       = sprintf('sub%02d',subject);
        p.path.edf                    = sprintf(p.subID);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data' filesep 'tmp' filesep p.subID '_' timestamp filesep];
        p.path.finalsubject           = [p.path.experiment 'data' filesep p.subID '_' timestamp filesep ];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);
        mkdir([p.path.subject 'eye']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);
        p.path.path_param             = sprintf([p.path.subject, 'stimulation/param']);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.png']);
        p.stim.tFile                  = size(p.stim.files,1);%number of different files (including the UCS symbol)        
        %
        display([mat2str(p.stim.tFile) ' found in the destination.']);
        %is all the captured bg values the same?
        
        p.stim.bg                   = 0;
        %
        %font size and background gray level
        p.text.fontname                = 'Times New Roman';
        p.text.fontsize                = 18;%30;
        p.text.fixsize                 = 60;
        %
        p.stim.white                   = [255 255 255];
        %get the actual stim size (assumes all the same)
        info                           = imfinfo(p.stim.files(1,:));
        
        
        if strcmp(p.hostname,'triostim1')
            p.keys.confirm                 = KbName('7');
            p.keys.increase                = KbName('8');
            p.keys.decrease                = KbName('6');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
        else
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('UpArrow');
            p.keys.increase                = KbName('RightArrow');
            p.keys.decrease                = KbName('LeftArrow');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('ESCAPE');
        end
        
        
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.stim                = 5;%2;%s
        p.duration.keep_recording      = 0.25;%this is the time we will keep recording (eye data) after stim offset.
        p.duration.prestim_ori         = .95;
        %p.duration.prestim             = 2-p.duration.prestim_ori;%that is 0.95 seconds        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence                        
        p.presentation.CrossPosition           = repmat([720   450],p.stim.tFile,1);
        p.presentation.stim_id                 = Shuffle(1:p.stim.tFile);
        p.presentation.isi                     = repmat(3,1,p.stim.tFile);
        p.duration.prestim                     = repmat(1.5,1,p.stim.tFile);
        p.presentation.tTrial                  = 10;%p.stim.tFile;
        
        p.rating.division                      = 5;
        %Save the stuff
        save(p.path.path_param,'p');
        %
        function [FM labels] = FileMatrix(path)
            %Takes a path with file extension associated to regexp (e.g.
            %C:\blabl\bla\*.bmp) returns the file matrix
            dummy = dir(path);
            FM    = [repmat([fileparts(path) filesep],length(dummy),1) vertcat(dummy(:).name)];
            labels = {dummy(:).name};
        end
    end
    function ShowInstruction(nInstruct,waitforkeypress)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, then subject has to press a button to
        %make the instruction text dissappear. Otherwise you have to take
        %care of it later
        
        [text]= GetText(nInstruct);
        ShowText(text);
        %let subject read it and ask confirmation to proceed. But we don't
        %need that in the case of INSTRUCT = 5;
        if waitforkeypress
            if nInstruct ~= 10%this is for the Reiz kommnt
                KbStrokeWait;
            else
                WaitSecs(2.5+rand(1));
            end
            Screen('FillRect',p.ptb.w,p.stim.bg);
            t = Screen('Flip',p.ptb.w);
            Log(t,-5,nInstruct);
        else
            if nInstruct ~= 10%this is for the Reiz kommnt
                KbStrokeWait;
            else
                WaitSecs(1+rand(1));
            end
        end
        
        
        function ShowText(text)
            
            Screen('FillRect',p.ptb.w,p.stim.bg);
            %DrawFormattedText(p.ptb.w, text, p.text.start_x, 'center',p.stim.white,[],[],[],2,[]);
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            Log(t,5,nInstruct);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');
            fprintf('=========================================================\n');
            fprintf(text);
            fprintf('=========================================================\n');
            
        end
    end
    function [text]=GetText(nInstruct)
        if nInstruct == 0%Eyetracking calibration
            
            text = ['Um Ihre Augenbewegungen zu messen, \n' ...
                'müssen wir jetzt den Eye-Tracker kalibrieren.\n' ...
                'Dazu zeigen wir Ihnen einige Punkte auf dem Bildschirm, \n' ...
                'bei denen Sie sich wie folgt verhalten:\n' ...
                'Bitte fixieren Sie den kleinen weißen Kreis und \n' ...
                'bleiben so lange darauf, wie es zu sehen ist.\n' ...
                'Bitte drücken Sie jetzt den oberen Knopf, \n' ...
                'um mit der Kalibrierung weiterzumachen.\n' ...
                ];
            
        elseif nInstruct == 1%first Instr. of the training phase.
            text = ['Herzlich Willkommen bei unserer Studie.\n' ...
                    'Bevor wir mit dem Experiment beginnen, einige Hinweise zum weiteren Ablauf.\n'...
                    'Die Steuerung des Experiments erfolgt mit 3 Tasten;\n'...
                    'Die ''Pfeiltaste oben'' entspricht weiter, links=ja und rechts=nein.\n'...
                    'Bitte drueck nun "Pfeiltaste oben" um zum naechsten Bildschirm zu kommen.\n'];
        
        
        elseif nInstruct == 2%second Instr. of the training phase.
            text = ['Du wirst gleich eine Reihe von Bildern gezeigt bekommen.\n'...
            'Bitte druecke die ''Pfeiltaste oben'' (weiter), sobald du etwas in dem Bild erkennst,\n'...
            'oder wenn du etwas Neues in dem Bild siehst.\n'...
            '\n'...
            'Nach dem Knopfdruck bleibt das Bild fuer einige Sekunden auf dem Bildschirm. Bitte sag uns im Anschluss daran, was du\n'...
            'gesehen hast, ob du das Bild kanntest und wie klar das Dargestellte erkennbar war.\n'...
            'Fuer die letzten beiden Fragen, benutze bitte die Tasten "rechts", "links" und die Ziffern "1-5".\n'...
            '\n'...
            'Bevor es jedoch mit dem Experiment losgeht, werden wir zuerst ein paar Probedurchlaeufe machen.\n'...
            '\n'...
            '(weiter mit der Pfeiltaste oben)\n'];
                
        elseif nInstruct == 3%third Instr. of the training phase.
            text = ['Bitte sag uns was du gesehen hast! (danach weiter mit der ''Pfeiltaste oben'')'];
            
        elseif nInstruct == 4%third Instr. of the training phase.
            text = ['Vielen Dank. Das waren die Probedurchgaenge.\n'...
                'Jetzt kommen wir zum Experiment. Der Ablauf ist genau wie in den Probedurchgaengen.\n'...
                '\n'...
                'Hast du noch Fragen, bevor wir mit dem Experiment beginnen?\n'...
                '\n'...
                '\n'...
                '(''Pfeiltaste oben'' zum Start des Experiments)\n'];                   
                        
        elseif nInstruct == 11;%rating
            text = ['Wie sicher bist Du dir auf einer Skala von 1-5?'];
                    
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
            text = {'sehr unsicher'};
        elseif nInstruct == 13
            text = {'sehr sicher'};
        elseif nInstruct == 14
            text = ['Bitte machen Sie eine kurze Pause.\n' ...
                'Sie können hierbei gern die Augen einen Moment schließen.\n'...
                'Drücken Sie anschließend die obere Taste um fortzufahren.\n'...
                'Wir werden dann den Eyetracker noch einmal kalibrieren.\n'...
                ];
        else
            text = {''};
        end
    end
    function SetPTB
        %Sets the parameters related to the PTB toolbox. Including
        %fontsizes, font names.
        %Find the number of the screen to be opened
        screens                     =  Screen('Screens');
        p.ptb.screenNumber          =  0;%the maximum is the second monitor
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'SuppressAllWarnings', 1);
        %set the resolution correctly
        if strcmp(p.hostname,'triostim1')
            p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,1280,960);
            %hide the cursor
            HideCursor(p.ptb.screenNumber);
        elseif strcmp(p.hostname,'etpc')
            p.ptb.oldres = Screen('resolution',p.ptb.screenNumber,1600,1200);
            %hide the cursor
            HideCursor(p.ptb.screenNumber);
        end
        
        %Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        if sum([p.ptb.width p.ptb.height] - [1280 960]) ~= 0
            fprintf('SET THE CORRECT SCREEN RESOLUTION\n');
        end
        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%bb(1);%always the same        
        [nx, ny bb]                 = DrawFormattedText(p.ptb.w,'+','center','center');
        
        %%
        %priorityLevel=MaxPriority(['GetSecs'],['KbCheck'],['KbWait'],['GetClicks']);
        Priority(MaxPriority(p.ptb.w));
        %this is necessary for the Eyelink calibration
        InitializePsychSound(0)
        %sound('Open')
        Beeper(5000)                
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.
        p.ptb.device        = -1;
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %load the pictures to the memory.
        p.ptb.stim_sprites = CreateStimSprites(p.stim.files);%
        
        function [out]=CreateStimSprites(files)
            %loads all the stims to video memory
            for nStim = 1:p.stim.tFile
                filename       = files(nStim,:);
                [im , ~, ~]    = imread(filename);
                im             = double(im);
                if size(im,3) == 1
                    im = repmat(im,[1 1 3]);
                end
                out(nStim)     = Screen('MakeTexture', p.ptb.w, im );
                p.stim.size(nStim,:) = size(im);
            end
        end
    end
    function [t]=StopEyelinkRecording
        Eyelink('StopRecording');
        t = GetSecs;
        %this is the end of the trial scope.
        WaitSecs(0.01);
        Eyelink('Message', 'TRIAL_RESULT 0');
        %
        WaitSecs(0.01);
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('Command', 'clear_screen %d', 0);
        Screen('Textsize', p.ptb.w,p.text.fontsize);
        Log(t,-8,NaN);
    end
    function [t]=StartEyelinkRecording(nTrial,nStim,fix)
        t = [];
        
        nStim = double(nStim);
        Eyelink('Message', 'TRIALID: %04d, FILE: %04d, FIXX: %04d, FIXY %04d', nTrial, nStim,fix(1),fix(2));
        % an integration message so that an image can be loaded as
        % overlay background when performing Data Viewer analysis.
        WaitSecs(0.01);
        %return
        if nStim~=0
            Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', p.stim.files(nStim,:), p.ptb.midpoint(1), p.ptb.midpoint(2));
        end
        % This supplies the title at the bottom of the eyetracker display
        Eyelink('Command', 'record_status_message "Stim: %02d"', nStim);
        %
        %Put the tracker offline and draw the stimuli.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        % clear tracker display and draw box at center
        Eyelink('Command', 'clear_screen %d', 0);
        %draw the image on the screen but also the two crosses
%         if (nStim <= 16 && nStim>0)
%             Eyelink('ImageTransfer',p.stim.files(nStim,:),p.ptb.imrect(1),p.ptb.imrect(2),p.ptb.imrect(3),p.ptb.imrect(4),p.ptb.imrect(1),p.ptb.imrect(2));            
%         end
        %         Eyelink('Command', 'draw_cross %d %d 15',p_ptb_CrossPositionET_x(1),p_ptb_CrossPositionET_y(1) );
        %         Eyelink('Command', 'draw_cross %d %d 15',p_ptb_CrossPositionET_x(2),p_ptb_CrossPositionET_y(2) );
        Eyelink('Command', 'draw_cross %d %d 15',fix(1),fix(2));
        
        %
        %drift correction
        %EyelinkDoDriftCorrection(el,crosspositionx,crosspositiony,0,0);
        %start recording following mode transition and a short pause.
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.01);
        Eyelink('StartRecording');
        t = GetSecs;
        Log(t,8,NaN);
    end
    function shuffled = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [~, idx]        = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end
    function InitEyeLink
        %
        if EyelinkInit(0)%use 0 to init normaly
            fprintf('=================\nEyelink initialized correctly...\n')
        else
            fprintf('=================\nThere is problem in Eyelink initialization\n')
            keyboard;
        end
        %
        WaitSecs(0.5);
        [~, vs] = Eyelink('GetTrackerVersion');
        fprintf('=================\nRunning experiment on a ''%s'' tracker.\n', vs );
        
        %
        el                          = EyelinkInitDefaults(p.ptb.w);
        %update the defaults of the eyelink tracker
        el.backgroundcolour         = p.stim.bg;
        el.msgfontcolour            = WhiteIndex(el.window);
        el.imgtitlecolour           = WhiteIndex(el.window);
        el.targetbeep               = 0;
        el.calibrationtargetcolour  = WhiteIndex(el.window);
        el.calibrationtargetsize    = 1.5;
        el.calibrationtargetwidth   = 0.5;
        el.displayCalResults        = 1;
        el.eyeimgsize               = 50;
        el.waitformodereadytime     = 25;%ms
        el.msgfont                  = 'Times New Roman';
        el.cal_target_beep          =  [0 0 0];%[1250 0.6 0.05];
        %shut all sounds off
        el.drift_correction_target_beep = [0 0 0];
        el.calibration_failed_beep      = [0 0 0];
        el.calibration_success_beep     = [0 0 0];
        el.drift_correction_failed_beep = [0 0 0];
        el.drift_correction_success_beep= [0 0 0];
        EyelinkUpdateDefaults(el);
        %PsychEyelinkDispatchCallback(el)
        
        % open file.
        res = Eyelink('Openfile', p.path.edf);
        %
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox FearCloud Experiment''');
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, p.ptb.width-1, p.ptb.height-1);
        % set calibration type.
        Eyelink('command','auto_calibration_messages = YES');
        Eyelink('command', 'calibration_type = HV13');
        Eyelink('command', 'select_parser_configuration = 1');
        %what do we want to record
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'use_ellipse_fitter = no');
        % set sample rate in camera setup screen
        Eyelink('command', 'sample_rate = %d',1000);
    end
    function StopEyelink(filename)
        try
            fprintf('Trying to stop the Eyelink system with StopEyelink\n');
            Eyelink('StopRecording');
            WaitSecs(0.5);
            Eyelink('Closefile');
            display('receiving the EDF file...');
            Eyelink('ReceiveFile',filename,[p.path.subject '\eye\'],1);
            display('...finished!')
            % Shutdown Eyelink:
            Eyelink('Shutdown');
        catch
            display('StopEyeLink routine didn''t really run well');
        end
    end
    function cleanup
        
        % Close window:
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'triostim1')
            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %        
        commandwindow;
        ListenChar(0);
        KbQueueRelease(p.ptb.device);
    end
    function CalibrateEL
        fprintf('=================\n=================\nEntering Eyelink Calibration\n')
        p_var_ExpPhase  = 0;
        ShowInstruction(0,1);
        EyelinkDoTrackerSetup(el);
        %Returns 'messageString' text associated with result of last calibration
        [~, messageString] = Eyelink('CalMessage');
        Eyelink('Message','%s',messageString);%
        WaitSecs(0.05);
        fprintf('=================\n=================\nNow we are done with the calibration\n')
    end
    function Log(ptb_time, event_type, event_info)
        %Phases:
        %Instruction          :     1
        %Baseline             :     2
        %Conditioning         :     3
        %Test                 :     4
        %Rating               :     5
        %Calibration          :     0
        %
        %event types are as follows:
        %
        %Scan Detection       :     0    info: NaN;
        %Cross Onset          :     1    info: position
        %Stimulus Onset/Offset:     2/-2 info: stim_id
        %Cross Movement       :     3    info: NaN;
        %Stimulus Offset      :     -2   info: NaN;
        %UCS Delivery         :     4    info: NaN;
        %Key Presses          :     7    info: NaN;
        %Tracker Onset/Offset :     8    info: NaN;
        %
        %Text on the screen   :     5    info: Which Text?
        %RatingScreen Onset   :     6    info: NaN;
        
        p_var_event_count                = p_var_event_count + 1;
        %%
        %
        %   for x = 1:10
        %       disp(x)
        %   end
        %
        p.out.log(p_var_event_count,:)   = [ptb_time event_type event_info p_var_ExpPhase];
        % %         p.out.log(p.out.event_counter,:)
        %logstring([ 'Logged: ' mat2str(p.out.log(p.out.event_counter,:)) ' - Type: ' p.verbose.eventtype{abs(event_type)} ' - Phase: ' p.verbose.eventphase{CurrentExperimentalPhase}])
        %for i = 1:3;subplot(3,1,i);plot(p.out.log(1:p.out.event_counter ,i),'o-');drawnow;end
        %
        
    end

    function AskStimRating
        % Get the text to be show during rating                       
        message     = GetText(11);
        SliderTextL = GetText(12);
        SliderTextR = GetText(13);
        % Gray everything
        Screen('FillRect', p.ptb.w , p.stim.bg);
        Screen('Flip',p.ptb.w);
        WaitSecs(.6);
        % Show the instruction
%         ShowInstruction(11,1);
        rect        = [p.ptb.width*0.2  p.ptb.midpoint(2) p.ptb.width*0.6 100];        
        %save the rating sequence just for security
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        rate(nTrial)  = RatingSlider(rect, p.rating.division, Shuffle(1:p.rating.division,1), p.keys.increase, p.keys.decrease, p.keys.confirm, {SliderTextL{1} SliderTextR{1}},message,1);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Verbose the rating of the subject
    end
    function [rating] = RatingSlider(rect,tSection,position,up,down,confirm,labels,message,numbersOn)
        %
        %Detect the bounding boxes of the labels.
        for nlab = 1:2
            [~ , ~, bb(nlab,:)]=DrawFormattedText(p.ptb.w,labels{nlab}, 'center', 'center',  p.stim.white,[],[],[],2);
            Screen('FillRect',p.ptb.w,p.stim.bg);
        end
        bb = max(bb);
        bb_size = bb(3)-bb(1);%vertical size of the bb.
        %
        DrawSkala;
        ok = 1;
        while ok == 1
            [secs, keyCode, ~] = KbStrokeWait;
            keyCode = find(keyCode);
            Log(secs,7,keyCode);
            if length(keyCode) == 1%this loop avoids crashes to accidential presses of meta keys
                if (keyCode == up) || (keyCode == down)
                    next = position + increment(keyCode);
                    if next < (tSection+1) && next > 0
                        position = position + increment(keyCode);
                        %rating   = tSection - position + 1;
                    end
                    DrawSkala;
                elseif keyCode == confirm
                    WaitSecs(0.1);
                    ok = 0;
                    Screen('FillRect',p.ptb.w,p.stim.bg);
                    t=Screen('Flip',p.ptb.w);
                end
            end
        end
        
        function DrawSkala
            %rating               = tSection - position + 1;
            rating               = position ;
            increment([up down]) = [1 -1];%delta
            tick_x               = linspace(rect(1),rect(1)+rect(3),tSection+1);%tick positions
            tick_size            = rect(3)./tSection;
            ss                   = tick_size/5*0.9;%slider size.
            %
            for tick = 1:length(tick_x)%draw ticks
                Screen('DrawLine', p.ptb.w, [255 0 0], tick_x(tick), rect(2), tick_x(tick), rect(2)+rect(4) , 3);
                if tick <= tSection && numbersOn
                    Screen('TextSize', p.ptb.w,p.text.fontsize./2);
                    DrawFormattedText(p.ptb.w, mat2str(tick) , tick_x(tick)+ss/2, rect(2)+rect(4),  p.stim.white);
                    Screen('TextSize', p.ptb.w,p.text.fontsize);
                end
                if tick == 1
                    DrawFormattedText(p.ptb.w, labels{1},tick_x(tick)-bb_size*1.4,rect(2), p.stim.white);
                elseif tick == tSection+1
                    DrawFormattedText(p.ptb.w, labels{2},tick_x(tick)+bb_size*0.4,rect(2), p.stim.white);
                end
            end
            %slider coordinates
            slider = [ tick_x(position)+tick_size*0.1 rect(2) tick_x(position)+tick_size*0.9 rect(2)+rect(4)];
            %draw the slider
            Screen('FillRect',p.ptb.w, p.stim.white, round(slider));
            Screen('TextSize', p.ptb.w,p.text.fontsize*2);
            DrawFormattedText(p.ptb.w,message, 'center', p.ptb.midpoint(2)*0.2,  p.stim.white,[],[],[],2);
            Screen('TextSize', p.ptb.w,p.text.fontsize);
            t = Screen('Flip',p.ptb.w);
            Log(t,6,NaN);
        end
    end
end
