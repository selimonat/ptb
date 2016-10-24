function [p]=exp_treatgen_calib16(subject,run,threshold)
%[p]=FearGen_eyelab(subject,run,csp,PainThreshold)
%
%Used for fearamy project, based on the FearGen_eyelab code. It increments
%it by adding scanner pulse communications.
%
%

debug = 0;%debug mode;
commandwindow;
%clear everything
clear mex global functions
cgshut;
global cogent;

%%%%%%%%%%%load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);
%
p         = [];
s         = [];

SetParams;
SetArduino;
SetPTB;
%
%init all the variables
t                         = [];
nTrial                    = 0;
%%
%Time Storage
TimeCrossOn               = [];
p.var.event_count         = 0;
%%
KbQueueStop(p.ptb.device);
KbQueueRelease(p.ptb.device);
%save again the parameter file
save(p.path.path_param,'p');


p.var.ExpPhase = run;
Screen('TextSize', p.ptb.w, 30);
[nx, ny, textbounds]=DrawFormattedText(p.ptb.w, GetText(0), 'center', 'center');
Screen('TextSize', p.ptb.w, p.text.fontsize);
%Instructions
if run == 1
    ShowInstruction(0,0,3);
    ShowInstruction(1,1); % explains all
elseif run ==2
    ShowInstruction(2,1); % a bit shorter
end

PresentStimuli;



%trim the log file and save
p.out.log = p.out.log(sum(isnan(p.out.log),2) ~= size(p.out.log,2),:);
%shift the time so that the first timestamp is equal to zero
p.out.log(:,1) = p.out.log(:,1) - p.out.log(1);
save(p.path.path_param,'p');
%
%move the file to its final location.
movefile(p.path.subject,p.path.finalsubject);
%close everything down
try
    addpath('/USER/onat/Code/globalfunctions/ssh2_v2_m1_r6/ssh2_v2_m1_r6/')
    p.path.tarname = [p.path.finalsubject(1:end-1) '.tar'];
    tar(p.path.tarname,p.path.finalsubject);
    [a b c] = fileparts( p.path.tarname);
    cd(a)
    scp_simple_put('sanportal','onat','',[b c]);
    fprintf('Copying to neuronass succesfull...\n');
catch
    fprintf('Copying to neuronass failed...\n');
end
cleanup;


    function PresentStimuli
        %Enter the presentation loop and wait for the first pulse to
        %arrive.
        %wait for the dummy scans
        %         [secs] = WaitPulse(p.keys.pulse,p.mrt.dummy_scan);%will log it
        KbQueueStop(p.ptb.device);
        WaitSecs(.05);
        KbQueueCreate(p.ptb.device);
        KbQueueStart(p.ptb.device);%this means that from now on we are going to log pulses.
        %If the scanner by mistake had been started prior to this point
        %those pulses would have been not logged.
        %         %log the pulse timings.
        %         TimeEndStim     = secs(end)- p.ptb.slack;%take the first valid pulse as the end of the last stimulus.
        for nTrial  = 1:p.presentation.tTrial;
            
            %Get the variables that Trial function needs.
            tempC         = p.presentation.stimlist(nTrial);
            prestimdur   = randi([p.duration.prestim],1,1) + rand(1)*.25;
            rampdur      = abs((tempC - p.presentation.basetemp)/p.presentation.ror); % this is the time the thermode needs to ramp up/down.
            %
            FixOnset     = GetSecs  + p.duration.ISI;       % white Fixcross
            FixColor     = FixOnset + prestimdur;               % red Fixcross
            Ramp1Onset   = FixColor + p.duration.anticip + rand(1)*.7; % actual ramp to trial's temp
            PlateauOnset = Ramp1Onset + rampdur;                % reached plateau, then wait
            Ramp2Onset   = PlateauOnset + p.duration.painstim;      % ramp back to baseline
            RateOnset    = Ramp2Onset + rampdur + p.duration.poststim;  %
            RateOffset   = RateOnset + p.duration.rate;
            
            fprintf('Starting Trial %02d of %02d, Destination Temp is %5.2f C, White fix on for %5.2f s. \n',nTrial,p.presentation.tTrial,tempC,prestimdur);
            %Start with the trial, here is time-wise sensitive must be
            %optimal
            PainTrial(nTrial,FixOnset,FixColor,Ramp1Onset,PlateauOnset,Ramp2Onset,RateOnset,RateOffset, tempC,rampdur);
        end
        Screen('Flip',p.ptb.w);
        WaitSecs(1);
        ShowInstruction(14,0,4);
        WaitSecs(3);
    end
    function PainTrial(numTrial,FixOnset,FixColor,Ramp1Onset,PlateauOnset,Ramp2Onset, RateOnset,RateOffset, tempC,rampdur)
        
        %% Fixation (white) Onset
        if numTrial ==1 % needed for first trial
            Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
            Screen('FillRect', p.ptb.w,  p.stim.white, p.ptb.FixCross');%draw the prestimus cross atop
            Screen('DrawingFinished',p.ptb.w,0);
            TimeCrossOn  = Screen('Flip',p.ptb.w,FixOnset,0);
            Log(TimeCrossOn, 2, p.ptb.FixCross');%white cross onset.
            MarkCED(p.com.lpt.address, p.com.lpt.Fix1)
        end
        %% Fixation (red) Onset
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.ptb.fc_color, p.ptb.FixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w,FixColor,0);
        Log(TimeCrossOn, 3, p.ptb.FixCross');%red cross onset.
        MarkCED(p.com.lpt.address, p.com.lpt.Fix2)
        %% Ramp to destination, wait there, ramp down.
        serialcom(s,'START',[],'verbose');
        Log(Ramp1Onset, 4, p.presentation.ror) % ramp up
        MarkCED(p.com.lpt.address, p.com.lpt.RampUp)
        fprintf('Ramping to %5.2f C in %.02f s.\n',tempC,rampdur)
        serialcom(s,'SET',tempC);
        while GetSecs < PlateauOnset
        end
        Log(PlateauOnset, 5, tempC); % begin of stim plateau
        MarkCED(p.com.lpt.address, p.com.lpt.Plateau)
        fprintf('\nPlateau is on. \n')
        countedDown = 1;
        while GetSecs < Ramp2Onset
            [countedDown]=CountDown(GetSecs-PlateauOnset,countedDown,'.');
        end
        fprintf('\nRamping back to baseline %5.2f C in %.02f s. \n',p.presentation.basetemp,rampdur)
        serialcom(s,'SET',p.presentation.basetemp)
        WaitSecs(rampdur);
        Log(Ramp2Onset, 6, p.presentation.ror) % ramp down
        MarkCED(p.com.lpt.address, p.com.lpt.RampDown)
        
        %% Rating
        Screen('Flip', p.ptb.w);
        while GetSecs < RateOnset
        end
        Log(RateOnset,9,NaN);   % log the rating onset
        MarkCED(p.com.lpt.address, p.com.lpt.RateOn)
        rateinit = randi(p.rating.initrange);
        [currentRating.finalRating,currentRating.RT,currentRating.response] = vasScale(p.ptb.w,p.ptb.rect,p.duration.rate,rateinit,...
            p.stim.bg,p.ptb.startY,p.keys);
        Log(GetSecs,10,NaN); % log the rating offset
        MarkCED(p.com.lpt.address, p.com.lpt.RateOff)
        PutRatingLog(numTrial,currentRating,tempC,rateinit)
        %% put fixation cross if rating ended before time ran out
        Screen('FillRect', p.ptb.w , p.stim.bg, p.ptb.rect); %always create a gray background
        Screen('FillRect',  p.ptb.w, p.stim.white, p.ptb.FixCross');%draw the prestimus cross atop
        Screen('DrawingFinished',p.ptb.w,0);
        TimeCrossOn  = Screen('Flip',p.ptb.w);
        Log(TimeCrossOn, 2, p.ptb.FixCross');%white cross onset.
        MarkCED(p.com.lpt.address, p.com.lpt.Fix1)
        while GetSecs < RateOffset
        end
    end

    function SetParams
        %relative path to stim and experiments
        %Path Business.
        [~, hostname] = system('hostname');
        p.hostname                    = deblank(hostname);
        if strcmp(p.hostname,'triostim1')
            p.path.baselocation       = 'C:\USER\kampermann\Experiments\';
        elseif strcmp(p.hostname,'isn3464a9d59588') % Lea's HP
            p.path.baselocation       = 'C:\Users\Lea\Documents\Experiments\';
        else
            error('Unknown PC found, please define it for folder structure.')
        end
        
        p.path.experiment             = [p.path.baselocation 'Treatgen\'];
        p.path.stim                   = [p.path.experiment 'Stimuli\'];
        %
        p.subID                       = sprintf('sub%02d',subject);
        p.path.edf                    = sprintf([p.subID 'p%02d' ],run);
        timestamp                     = datestr(now,30);
        p.path.subject                = [p.path.experiment 'data\tmp\' p.subID '_' timestamp '\'];
        p.path.finalsubject           = [p.path.experiment 'data\calibration\' p.subID '_Session' num2str(run) '_' timestamp '\' ];
        %create folder hierarchy
        mkdir(p.path.subject);
        mkdir([p.path.subject 'scr']);
        % mkdir([p.path.subject 'eye']);
        % mkdir([p.path.subject 'quadruplet']);
        mkdir([p.path.subject 'stimulation']);
        mkdir([p.path.subject 'midlevel']);
        p.path.path_param             = sprintf([regexprep(p.path.subject,'\\','\\\') 'stimulation\\param_phase_%02d'],run);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %get stim files to anticipate bg color
        [p.stim.files p.stim.label]   = FileMatrix([p.path.stim '*.bmp']);
        im                            = imread(p.stim.files(1,:));
        p.stim.bg                     = im(1,1,1); %151
        %
        %font size and background gray level
        p.text.fontname                = 'Arial';
        p.text.fontsize                = 18;%30;
        p.text.linespace               = 10;
        p.text.lineheight              = p.text.fontsize + p.text.linespace;
        %rating business
        p.rating.division              = 101; %number of divisions for the rating slider
        p.rating.initrange             = [35,65];
        %
        p.stim.white                   = [255 255 255];
        if strcmp(p.hostname,'triostim1')
            p.keys.space                   = KbName('space');
            p.keys.confirm                 = KbName('7');
            p.keys.increase                = KbName('8');
            p.keys.decrease                = KbName('6');
            p.keys.esc                     = KbName('esc');
        else
            %All settings for laptop computer.
            p.keys.confirm                 = KbName('up');
            p.keys.increase                = KbName('right');
            p.keys.decrease                = KbName('left');
            p.keys.space                   = KbName('space');
            p.keys.esc                     = KbName('esc');
            p.keys.null                    = KbName('0)');
            p.keys.one                     = KbName('1!');
        end
        
        %get all the required keys in a vector
        p.ptb.keysOfInterest = [];for i = fields(p.keys)';p.ptb.keysOfInterest = [p.ptb.keysOfInterest p.keys.(i{1})];end
        fprintf('Key listening will be restricted to %d\n',p.ptb.keysOfInterest)
        RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Communication business
        %parallel port
        p.com.lpt.address              = 888;
        %codes for different events
        p.com.lpt.Fix1              = 1;
        p.com.lpt.Fix2              = 2;
        %2 is empty because
        p.com.lpt.RampUp            = 4;
        p.com.lpt.Plateau           = 8;
        p.com.lpt.RampDown          = 16;
        p.com.lpt.RateOn            = 32;
        p.com.lpt.RateOff           = 64;
        %p.com.lpt.CS_neg               = 128;
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %timing business
        %these are the intervals of importance
        %time2fixationcross->cross2onset->onset2shock->shock2offset
        %these (duration.BLA) are average duration values:
        p.duration.painstim                  = 5;%
        p.duration.prestim                   = [2 4];
        p.duration.anticip                   = 1;
        p.duration.poststim                  = 1;
        p.duration.ISI                       = 1;
        p.duration.rate                      = 5;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %stimulus sequence
        s = load([p.path.stim 'stimlist\caliblist.mat']);
        steps = s.steps;
        
        p.presentation.basetemp        = threshold;
        p.presentation.ror             = 5;
        p.presentation.run             = run;
        
        %this will deal all the presentation sequence related information
%         p.presentation.Tmax            = threshold + 3;
        p.presentation.stimlist        = p.presentation.basetemp + steps;%Threshold + 3 is maximum temperature
        p.presentation.tTrial          = length(p.presentation.stimlist);
        %
        
        p.log.ratingEventCount         = 0;
        p.log.ratings                  = [];
        p.out.log                     = zeros(1000000,4).*NaN;
        p.out.response                = zeros(p.presentation.tTrial,1);
        p.out.threshold               = threshold;
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
    function SetArduino
        s = serial('COM5','BaudRate',19200);
        fopen(s);
        WaitSecs(1);
        serialcom(s,'T',p.presentation.basetemp);
        serialcom(s,'ROR',p.presentation.ror);
        WaitSecs(.5);
        serialcom(s,'DIAG');
        WaitSecs(1);
    end
    function [finalRating,reactionTime,response] = vasScale(window,windowRect,durRating,defaultRating,backgroundColor,StartY,keys)
        
        %% key settings
        KbName('UnifyKeyNames');
        lessKey =  keys.decrease; % yellow button
        moreKey =  keys.increase; % red button
        confirmKey =  keys.confirm;  % green button
        escapeKey = keys.esc;
        
        if isempty(window); error('Please provide window pointer for likertScale!'); end
        if isempty(windowRect); error('Please provide window rect for likertScale!'); end
        if isempty(durRating); error('Duration length of rating has to be specified!'); end
        
        %% Default values
        nRatingSteps = p.rating.division;
        scaleWidth = 700;
        textSize = 20;
        lineWidth = 6;
        scaleColor = [255 255 255];
        activeColor = [255 0 0];
        if isempty(defaultRating); defaultRating = round(nRatingSteps/2); end
        if isempty(backgroundColor); backgroundColor = 0; end
        
        
        
        % if length(ratingLabels) ~= nRatingSteps
        %     error('Rating steps and label numbers do not match')
        % end
        
        %% Calculate rects
        activeAddon_width = 1.5;
        activeAddon_height = 20;
        [xCenter, yCenter] = RectCenter(windowRect);
        yCenter = StartY;
        axesRect = [xCenter - scaleWidth/2; yCenter - lineWidth/2; xCenter + scaleWidth/2; yCenter + lineWidth/2];
        lowLabelRect = [axesRect(1),yCenter-20,axesRect(1)+6,yCenter+20];
        highLabelRect = [axesRect(3)-6,yCenter-20,axesRect(3),yCenter+20];
        ticPositions = linspace(xCenter - scaleWidth/2,xCenter + scaleWidth/2-lineWidth,nRatingSteps);
        % ticRects = [ticPositions;ones(1,nRatingSteps)*yCenter;ticPositions + lineWidth;ones(1,nRatingSteps)*yCenter+tickHeight];
        activeTicRects = [ticPositions-activeAddon_width;ones(1,nRatingSteps)*yCenter-activeAddon_height;ticPositions + lineWidth+activeAddon_width;ones(1,nRatingSteps)*yCenter+activeAddon_height];
        % keyboard
        
        
        Screen('TextSize',window,textSize);
        Screen('TextColor',window,[255 255 255]);
        Screen('TextFont', window, 'Arial');
        currentRating = defaultRating;
        finalRating = currentRating;
        reactionTime = 0;
        response = 0;
        first_flip  = 1;
        startTime = GetSecs;
        numberOfSecondsRemaining = durRating;
        nrbuttonpresses = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%% loop while there is time %%%%%%%%%%%%%%%%%%%%%
        % tic; % control if timing is as long as durRating
        while numberOfSecondsRemaining  > 0
            Screen('FillRect',window,backgroundColor);
            Screen('FillRect',window,scaleColor,axesRect);
            Screen('FillRect',window,scaleColor,lowLabelRect);
            Screen('FillRect',window,scaleColor,highLabelRect);
            Screen('FillRect',window,activeColor,activeTicRects(:,currentRating));
            
            DrawFormattedText(window, 'Bitte bewerten Sie die Schmerzhaftigkeit', 'center',yCenter-100, scaleColor);
            DrawFormattedText(window, 'des Hitzereizes', 'center',yCenter-70, scaleColor);
            
            Screen('DrawText',window,'kein',axesRect(1)-17,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(1)-40,yCenter+45,scaleColor);
            
            Screen('DrawText',window,'unerträglicher',axesRect(3)-55,yCenter+25,scaleColor);
            Screen('DrawText',window,'Schmerz',axesRect(3)-40,yCenter+45,scaleColor);
            
            
            
            % Remove this line if a continuous key press should result in a continuous change of the scale
            %     while KbCheck; end
            
            if response == 0
                
                % set time 0 (for reaction time)
                if first_flip   == 1
                    secs0       = Screen('Flip', window); % output Flip -> starttime rating
                    first_flip  = 0;
                    % after 1st flip -> just flips without setting secs0 to null
                else
                    Screen('Flip', window);
                end
                
                [ keyIsDown, secs, keyCode ] = KbCheck; % this checks the keyboard very, very briefly.
                if keyIsDown % only if a key was pressed we check which key it was
                    response = 0; % predefine variable for confirmation button 'space'
                    nrbuttonpresses = nrbuttonpresses + 1;
                    if keyCode(moreKey) % if it was the key we named key1 at the top then...
                        currentRating = currentRating + 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating > nRatingSteps
                            currentRating = nRatingSteps;
                        end
                    elseif keyCode(lessKey)
                        currentRating = currentRating - 1;
                        finalRating = currentRating;
                        response = 0;
                        if currentRating < 1
                            currentRating = 1;
                        end
                    elseif keyCode(confirmKey)
                        finalRating = currentRating-1;
                        disp(['VAS Rating: ' num2str(finalRating)]);
                        response = 1;
                        reactionTime = secs - secs0;
                        break;
                    end
                end
            end
            
            numberOfSecondsElapsed   = (GetSecs - startTime);
            numberOfSecondsRemaining = durRating - numberOfSecondsElapsed;
        end
        if  nrbuttonpresses ~= 0 && response == 0
            finalRating = currentRating - 1;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\nNo Confirmation!\n***********\n'));
        end
        if  nrbuttonpresses == 0
            finalRating = NaN;
            reactionTime = durRating;
            disp(['VAS Rating: ' num2str(finalRating)]);
            warning(sprintf('\n***********\nNo Response!\nPlease check participant!\n***********\n'));
        end
        % toc
    end



    function ShowInstruction(nInstruct,waitforkeypress,varargin)
        %ShowInstruction(nInstruct,waitforkeypress)
        %if waitforkeypress is 1, ==> subject presses a button to proceed
        %if waitforkeypress is 0, ==> text is shown for VARARGIN seconds.
        
        
        [text]= GetText(nInstruct);
        ShowText(text);
        if waitforkeypress %and blank the screen as soon as the key is pressed
            KbStrokeWait(p.ptb.device);
        else
            WaitSecs(varargin{1});
        end
        Screen('FillRect',p.ptb.w,p.stim.bg);
        t = Screen('Flip',p.ptb.w);
        
        function ShowText(text)
            
            Screen('FillRect',p.ptb.w,p.stim.bg);
            DrawFormattedText(p.ptb.w, text, 'center', 'center',p.stim.white,[],[],[],2,[]);
            t=Screen('Flip',p.ptb.w);
            Log(t,-1,nInstruct);
            %show the messages at the experimenter screen
            fprintf('=========================================================\n');
            fprintf('Text shown to the subject:\n');
            fprintf(text);
            fprintf('=========================================================\n');
            
        end
    end
    function [text]=GetText(nInstruct)
        if nInstruct == 0%
            
            text = ['Bewertung der Schmerzintensität'];
            
        elseif nInstruct == 1 %Instruction
            text = ['Im Folgenden möchten wir Ihre spezifische Schmerzempfindung bestimmen.\n' ...
                'Dazu senden wir Ihnen mehrere Hitzereize, die Sie anschließend mittels\n' ...
                'einer Schmerz-Skala bewerten sollen. Falsche Antworten gibt es bei dieser\n' ...
                'Aufgabe nicht, da individuelle Empfindungen sehr unterschiedlich sein können.\n' ...
                'Nutzen Sie die Pfeiltasten zum Bewerten & bestätigen Sie Ihre Eingabe immer\n' ...
                'mit der oberen Pfeiltaste. Bitte versuchen Sie sich auch auf kleinste Reizänderungen\n' ...
                'zu konzentrieren & bewerten Sie diese so präzise wie möglich. Falls Sie noch\n'...
                'Fragen haben, wenden Sie sich bitte noch einmal an die Versuchsleiterin. Falls\n' ...
                'Sie keine Fragen mehr haben, drücken Sie bitte die obere Taste, um zu starten.\n'];
        elseif nInstruct == 2%short instruction for second run
            text = ['Wiederholung der Schwellenkalibrierung.\n'...
                '\n'...
                'Nutzen Sie die Tasten von Zeigefinger (links) & Ringfinger (rechts) zum Bewerten.\n'...
                'Bestätigen Sie Ihre Eingabe immer mit der mittleren Taste (oben). Falls Sie noch \n'...
                'Fragen haben, teilen Sie dies gleich noch einmal der Versuchsleiterin mit. \n'...
                ];
        elseif nInstruct == 11 %end
            text = ['Bitte bewerten Sie, wie schmerzhaft der soeben erhaltene Reiz für Sie war.'];
        elseif nInstruct == 12 %These two below are the possible responses to the question in 11
            text = {'unerträglich\nschmerzhaft'};
        elseif nInstruct == 13
            text = {'Überhaupt\nnicht\nschmerzhaft'};
        elseif nInstruct == 14
            text = ['Diesen Teil des Experiments haben Sie geschafft. \n'...
                'Vielen Dank!\n'...
                'Es geht gleich weiter. \n'];
        else
            text = {''};
        end
    end
    function SetPTB
        %KbName('UnifyKeyNames');
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
        p.ptb.screenNumber          =  max(screens);%the maximum is the second monitor
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        %set the resolution correctly
        res = Screen('resolution',p.ptb.screenNumber);
        HideCursor(p.ptb.screenNumber);
        %spit out the resolution
        fprintf('Resolution of the screen is %dx%d...\n',res.width,res.height);
        
        %Open a graphics window using PTB
        [p.ptb.w p.ptb.rect]        = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        %Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);%make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        p.ptb.startY = p.ptb.height./2; %should be px(yaxis)./4;
        %find the mid position on the screen.
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];
        %NOTE about RECT:
        %RectLeft=1, RectTop=2, RectRight=3, RectBottom=4.
        %         p.ptb.CrossPosition_x       = p.ptb.midpoint(1);%bb(1);%always the same
        %         p.ptb.CrossPosition_y       = p.ptb.midpoint(2)./2;
        
        p.ptb.fc_size               = 20;
        p.ptb.fc_width              = 4;
        p.ptb.fc_color              = [255 0 0];
        %         p.ptb.screenFix1 = [p.ptb.midpoint(1)-p.ptb.fc_size p.ptb.startY-p.ptb.fc_width p.ptb.midpoint(1)+p.ptb.fc_size p.ptb.startY+p.ptb.fc_width]; %I guess this is X
        %         p.ptb.screenFix2 = [p.ptb.midpoint(1)-p.ptb.fc_width p.ptb.startY-p.ptb.fc_size p.ptb.midpoint(1)+p.ptb.fc_width p.ptb.startY+p.ptb.fc_size]; %I guess this is Y
        fix          = [p.ptb.midpoint(1) p.ptb.startY]; % yaxis is 1/4 of total yaxis
        p.ptb.FixCross     = [fix(1)-p.ptb.fc_width,fix(2)-p.ptb.fc_size,fix(1)+p.ptb.fc_width,fix(2)+p.ptb.fc_size;fix(1)-p.ptb.fc_size,fix(2)-p.ptb.fc_width,fix(1)+p.ptb.fc_size,fix(2)+p.ptb.fc_width];
        
        %
        %%
        %priorityLevel=MaxPriority(['GetSecs'],['KbCheck'],['KbWait'],['GetClicks']);
        Priority(MaxPriority(p.ptb.w));
        %this is necessary for the Eyelink calibration
        %InitializePsychSound(0)
        %sound('Open')
        %         Beeper(1000)
        LoadPsychHID
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Prepare the keypress queue listening.
        p.ptb.device        = [];
        %get all the required keys in a vector
        p.ptb.keysOfInterest = [];for i = fields(p.keys)';p.ptb.keysOfInterest = [p.ptb.keysOfInterest p.keys.(i{1})];end
        fprintf('Key listening will be restricted to %d\n',p.ptb.keysOfInterest)
        RestrictKeysForKbCheck(p.ptb.keysOfInterest);
        
        p.ptb.keysOfInterest=zeros(1,256);
        p.ptb.keysOfInterest(p.keys.confirm) = 1;
        %create a queue sensitive to only relevant keys.
        % KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);%default device.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %prepare parallel port communication. This relies on cogent i
        %think. We could do it with PTB as well.
        if ~ismac
            config_io;
            outp(p.com.lpt.address,0);
            if( cogent.io.status ~= 0 )
                error('inp/outp installation failed');
            end
        end
        
        %CORRECT
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %test whether CED receives the triggers correctly...
        %         k = 0;
        %         while ~(k == 25 | k == 86 );
        %             pause(0.1);
        %             outp(p.com.lpt.address,244);%244 means all but the UCS channel (so that we dont shock the subject during initialization).
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('1/ Red cable has to be connected to the Cogent BOX\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('2/ D2 Connection not to forget on the LPT panel\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('3/ Switch the SCR cable\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('4/ Button box has to be on\n');
        %             fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        %             fprintf('5/ Did the trigger test work?\n!!!!!!You MUST observe 5 pulses on the PHYSIOCOMPUTER!!!!!\n\n\nPress c to send it again, v to continue...\n')
        %             [~, k] = KbStrokeWait(p.ptb.device);
        %             k = find(k);
        %         end
        %         fprintf('Continuing...\n');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
    function [shuffled idx] = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample
        if nargin < 2;N = length(vector);end
        [~, idx]        = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end

    function [countedDown]=CountDown(secs, countedDown, countString)
        if secs>countedDown
            fprintf('%s', countString);
            countedDown=ceil(secs);
        end
    end

    function MarkCED(socket,port)
        %send pulse to SCR#
        outp(socket,port);
        WaitSecs(0.01);
        outp(socket,0);
    end

    function cleanup
        % Close window:
        sca;
        %set back the old resolution
        if strcmp(p.hostname,'triostim1')
            %            Screen('Resolution',p.ptb.screenNumber, p.ptb.oldres.width, p.ptb.oldres.height );
            %show the cursor
            ShowCursor(p.ptb.screenNumber);
        end
        %
        commandwindow;
        KbQueueStop(p.ptb.device);
        KbQueueRelease(p.ptb.device);
    end
    function Log(ptb_time, event_type, event_info)
        %Phases:
        %Instruction          :     0
        %Test                 :     1
        %Rating               :     5
        %Calibration          :     0
        %
        %event types are as follows:
        %
        % % %         %Pulse Detection      :     0    info: NaN;
        % % %         %Tracker Onset        :     1
        % % %         %Cross Onset          :     2    info: position
        % % %         %Stimulus Onset       :     3    info: dist_id
        % % %         %Cross Movement       :     4    info: NaN;
        % % %         %UCS Delivery         :     5    info: NaN;
        % % %         %Stimulus Offset      :     6    info: NaN;
        % % %         %Key Presses          :     7    info: NaN;
        % % %         %Tracker Offset       :     8    info: NaN;
        % % %         %MicroBlock			  :     9    info:rank
        %%%%%%%%%%%%%%%%%
        %         %Pulse Detection      :     0    info: NaN;
        %         %Tracker Onset        :     1
        %         %Cross (white) Onset  :     2    info: position
        %         %Cross (red) Onset    :     3    info: position
        %         %Ramp Up Onset        :     4    info: ror
        %         %Pain Plateau         :     5    info: temp
        %         %Ramp Down Onset      :     6    info: ror;
        %         %Key Presses          :     7    info: NaN;
        %         %Tracker Offset       :     8    info: NaN;
        %         %Rate Onset			:     9    info: NaN;
        %         %Rate Offset          :     10   info: NaN;
        %         %dummy fixflip        :     22   info: NaN;
        %Text on the screen   :     -1    info: Which Text?
        for iii = 1:length(ptb_time)
            p.var.event_count                = p.var.event_count + 1;
            p.out.log(p.var.event_count,:)   = [ptb_time(iii) event_type event_info(iii) p.var.ExpPhase];
        end
        %                 plot(p.out.log(1:p.var.event_count,1) - p.out.log(1,1),p.out.log(1:p.var.event_count,2),'o','markersize',10);
        %                 ylim([-2 8]);
        %                 set(gca,'ytick',[-2:8],'yticklabel',{'Rating On','Text','Pulse','Tracker+','Cross+','Stim+','CrossMov','UCS','Stim-','Key+','Tracker-'});
        %                 grid on
        %                 drawnow;
        
    end
    function PutRatingLog(Trialnum,currentRating,tempC,rateinit)
        
        p.log.ratingEventCount                     = p.log.ratingEventCount + 1;
        p.log.ratings(p.log.ratingEventCount,1)    = tempC;
        p.log.ratings(p.log.ratingEventCount,2)    = Trialnum;
        p.log.ratings(p.log.ratingEventCount,3)    = currentRating.finalRating;
        p.log.ratings(p.log.ratingEventCount,4)    = currentRating.response;
        p.log.ratings(p.log.ratingEventCount,5)    = currentRating.RT;
        p.log.ratings(p.log.ratingEventCount,6)    = rateinit;
    end

    function [keycode, secs] = KbQueueDump;
        %[keycode, secs] = KbQueueDump
        %   Will dump all the events accumulated in the queue.
        
        keycode = [];
        secs    = [];
        pressed = [];
        %fprintf('there are %03d events\n',KbEventAvail(p.ptb.device));
        while KbEventAvail(p.ptb.device)
            [evt, n]   = KbEventGet(p.ptb.device);
            n          = n + 1;
            keycode(n) = evt.Keycode;
            pressed(n) = evt.Pressed;
            secs(n)    = evt.Time;
            %   fprintf('Event is: %d\n',keycode(n));
        end
        i           = pressed == 1;
        keycode(~i) = [];
        secs(~i)    = [];
        %fprintf('there are %03d events found...\n',length(keycode));
    end
end
