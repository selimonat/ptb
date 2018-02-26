function [p,saveFolder] = exp_StimDiff_pairwise(subID,cspNum,intro,varargin)
%function [p,saveFolder] = exp_StimDiff_pairwise(subID,cspNum,intro[,language])
%Present stimuli in pairs - get estimates of difference 
%Keep in mind that this is a quick-and-dirty approach - it's just not
%really feasible to use more sophisticated methods due to time constraints
%
%Expected input:
%   subID    =  Number of participant - this has to be the same as used
%               later in the experiment because it defines which stimuli 
%               will be used 
%   cspNum   =  8 possible CS+ faces - which do you want?
%   intro    =  wether to present introTrials
%   language =  'english' or 'german' - defines which strings are being used
%               to allow for international participants. Although
%               consindering that the subejcts for the FearGen experiment
%               will be german it's probably not really needed
% 
%Don't forget to set the base folder to the wanted directory
%
%22.02.2018:    adapted to only show the stimuli that are also being used
%               for the following
%23.02.2018:    equivalent update of the use of the sequence list. Should
%               work just fine now

p           = [];
p.intro     = intro;
p.cspNum    = cspNum; 

if size(varargin) == 1
    p.language = varargin{1};
else
    p.language = 'german';
end

debug = 1; %debugging mode with semi-transparant window and disabled timing tests and stuff
reduced = 0; %define how many stimuli are being used. 1 means 8 stimuli, 0 means 20 stimuli

if nargin == 0
    subID = 99;
end

%general preparations
clear mex global functions;
GetSecs;WaitSecs(0.001);


%% 
%%Run functions
%run preparatory functions, defined later in the code
SetParams; %define parameters, establish variables, etc
SetPTB; %set up the psychtoolbox, even for bad setups
LoadStimuli; %read stimuli into workspace and make textures from them
Introduction;
if intro == 1
    ExplainScale;
end
p.timing.begin  = now;
RunTrials;
p.timing.end    = now;
GoodBye;

%% Subfunctions

%%SetParams

    function SetParams
        
        %define relevant directories
        [~,hostname]        = system('hostname');
        p.hostname          = deblank(hostname);
        p.path.baselocation = 'C:\Users\neugebauer\Documents\Experiments\FearGen'; 
        p.path.experiment   = [p.path.baselocation, filesep];
        p.subID             = sprintf('S%02d',subID);
        p.path.results      = [p.path.experiment,'StimDiff',filesep,'raw',filesep];
        p.path.resultsName  = [p.path.results,sprintf('%s_StimDiff_pairwise',p.subID)];
      
        if ~exist(p.path.results)
            mkdir(p.path.results)
            fprintf('The directory %s was created.',p.path.results);
        end
        
        p.path.ressource    = [fileparts(which('exp_StimDiff_pairwise.m')),filesep,'bin',filesep];
        p.path.stim         = [p.path.ressource,'Stimuli_FearGen_3D',filesep];
        p.path.introStim    = [p.path.stim,'introStimDiff',filesep];
        p.path.sequence     = [p.path.ressource,'sequences_StimDiff.mat'];       
        
        if exist(p.path.resultsName) %give the opportunity to abort the experiment if the file already exists
            [~,dummyName]   = fileparts(p.path.resultsName); 
            response    = input(sprintf('A file of the name %s already exists.\nAre you sure that you want to overwrite it? [y/n]',dummyName),'s');
            if ~strcmp(response,'y')
                error('The experiment was aborted.');
            end
        end
        
        %Sequence of pairs: load the respective file
        s                       = load(p.path.sequence);
        p.presentation          = s.seq(subID,p.cspNum);
        p.presentation.nTrials  = size(p.presentation.sequence,1);  
        clear s;
        
        %locate stimuli and keep only the ones we need.
        [p.stim.files, p.stim.label]    = FileMatrix([p.path.stim,'*.bmp']);
        usedNames   = cell(numel(p.presentation.stimlist),1); %which stimuli are being used for the respective CSP
        for s = 1:numel(p.presentation.stimlist)
            usedNames{s}  = sprintf('%03d.bmp',p.presentation.stimlist(s));
        end
        usedIndex   = ismember(p.stim.label,usedNames);
        [p.stim.files,p.stim.label]   = deal(p.stim.files(usedIndex,:),{p.stim.label{usedIndex}});
        p.stim.nStim                    = size(p.stim.files,1);
        fprintf('%2d stimuli kept.\n', p.stim.nStim);
        if p.intro == 1
            [p.stim.intro.files,p.stim.intro.label] = FileMatrix([p.path.introStim,'*.bmp']);
            p.stim.nStimIntro           = size(p.stim.intro.files,1);
            fprintf('%2d stimuli found in the intro directory',p.stim.nStimIntro);
        end
        
        %adjust background luminance to the luminance of the pictures
        bg = zeros(p.stim.nStim,1);
        for ind = 1:p.stim.nStim
            dummyIm         = imread(p.stim.files(ind,:));
            bg(ind)         = dummyIm(1,1);
        end
        
        if p.intro
            bgIntro = zeros(p.stim.nStimIntro,1);
            for ind     = 1:p.stim.nStimIntro
                dummyIntroIm     = imread(p.stim.intro.files(ind,:));
                bgIntro(ind)     = dummyIntroIm(1,1);
            end
        end
        
        %show warning if images don't have same luminance, otherwise set bg
        if sum(diff(bg)) == 0
            p.stim.bg       = double(unique(bg));
        else
            fprintf('Different backgound luminances were detected. Please check and possibly reprocess your stimuli.\n');
        end
        
        if p.intro
            if sum(diff(bgIntro)) == 0
                p.stim.bgIntro  = double(unique(bgIntro));
            else
                fprintf('Different background luminances for intro stimuli dedected. Check and reprocess them.');
            end
        end
        
        p.stim.white    = 255;
        p.stim.black    = 0;
        
        %set text preferences
        p.text.fontSize     = 20;
        p.text.fontName     = 'Arial';
        
        %get size of images
        imInfo          = imfinfo(p.stim.files(1,:));
        p.stim.width    = imInfo.Width;
        p.stim.height   = imInfo.Height;
              
        %define stuff for the fixation cross
        p.cross.length  = 15; %length of each of the arms of the cross
        p.cross.col     = 255; %color of the cross
        
        %define the durations of the trials and frequency of breaks
        p.duration.ITI          = 1;
        p.nBlocks               = 3;
        p.breakTrials           = [1:p.nBlocks-1] * round(p.presentation.nTrials/p.nBlocks);
        p.blockCount            = 1;
        p.blockDur              = zeros(p.nBlocks,1);
        
        %Define variable for results
        p.results       = zeros( length( p.presentation.sequence ), 1 ); 
    end

%% SetPTB

    function SetPTB  %initialize stuff for the psychtoolbox
        
        Screen('Preference','SkipSyncTests',1); %skip sync tests, so experiment runs also on shitty set-ups. Timing is not important for this task.
        Screen('Preference', 'DefaultFontSize', p.text.fontSize);
        Screen('Preference', 'DefaultFontName', p.text.fontName);
        Screen('Preference', 'TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        Screen('Preference', 'SuppressAllWarnings', 1);
        
        %%Find the number of the screen to be opened
        screens                     =  Screen('Screens');
        p.ptb.screenNum             =  max(screens);%this should find the secondary display;        
        
        %Make everything transparent for debugging purposes.
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;
        end
        
        %find and report resolution of the screen being used
        res     = Screen('Resolution',p.ptb.screenNum);
        fprintf('The resolution is %dx%d...\n',res.width,res.height);
        p.ptb.width                 = res.width;
        p.ptb.height                = res.height;
               
        %Open a window and set the background colour already;
        [p.ptb.win, p.ptb.rect]     = Screen('OpenWindow',p.ptb.screenNum,p.stim.bg);
        p.ptb.flipInt               = Screen('GetFlipInterval',p.ptb.win);
        Screen('BlendFunction', p.ptb.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        %define positions of the inner corners of stimuli
        p.stim.vertDist = 0; %distance between the both pictures
        p.stim.horDist  = 0; % how far both are shifted upwards or downwards; 0 means vertically centered, positive values shift upwards, negative downwards
        
        %define wanted size of stimuli
        p.stim.sizeVert = 400;
        p.stim.sizeHor  = p.stim.sizeVert*(p.stim.width/p.stim.height);
        
        %define midpoint of screen and coordinates for stimuli/fixation crss
        p.ptb.midpoint              = [p.ptb.width/2, p.ptb.height/2];
        p.stim.coords               = [p.ptb.midpoint(1)-p.stim.horDist-p.stim.sizeHor,p.ptb.midpoint(2)-p.stim.sizeVert/2-p.stim.vertDist,p.ptb.midpoint(1)-p.stim.horDist,p.ptb.midpoint(2)+p.stim.sizeVert/2-p.stim.vertDist;
                                       p.ptb.midpoint(1)+p.stim.horDist,p.ptb.midpoint(2)-p.stim.vertDist-p.stim.sizeVert/2,p.ptb.midpoint(1)+p.stim.horDist+p.stim.sizeHor,p.ptb.midpoint(2)+p.stim.sizeVert/2-p.stim.vertDist]';
        p.stim.coordsIntro1         = [p.ptb.midpoint(1)-p.stim.horDist-p.stim.sizeHor,p.ptb.midpoint(2)-p.stim.sizeVert/2+100,p.ptb.midpoint(1)-p.stim.horDist,p.ptb.midpoint(2)+p.stim.sizeVert/2+100;
                                       p.ptb.midpoint(1)+p.stim.horDist,p.ptb.midpoint(2)-p.stim.sizeVert/2+100,p.ptb.midpoint(1)+p.stim.horDist+p.stim.sizeHor,p.ptb.midpoint(2)+p.stim.sizeVert/2+100]';
        p.cross.coords              = [0,0,-p.cross.length,p.cross.length;-p.cross.length,p.cross.length,0,0];
       
        %duration stuff
        p.stim.maxDuration          = 90;
        p.cross.duration            = 1; %duration of fixation cross
        
        %the strings that are used to communicate with the subjects
        if strcmp(p.language, 'german')
            p.strings.extendedIntro     = {['Um ein Gefühl für die Gesichter und die Verwendung der Skala zu bekommen, zeigen wir Ihnen\n',... 
                                            'zunächst einige Paare von Gesichtern, die sich verschiedenen stark voneinander unterscheiden.\n',...
                                            'Kleiner Reminder: ''1'' steht für überhaupt keine Ähnlichkeit, ''5'' steht für extreme Ähnlichkeit,\n',...
                                            'also nicht oder kaum unterscheidbare Gesichter.\n',...
                                            'Weiter - hier und auf den folgenden Seiten - mit der Leertaste!\n'],...
                                            'Diese beiden Gesichter sind identisch. Dies entspricht einer ''5'' auf der Skala.',...
                                           ['Diese Gesichter weisen deutliche Unterschiede auf, sind aber immer noch relativ ähnlich.\n',...
                                            'Sie könnten entsprechend eine mittlere Auswahl, also z.B. eine ''3'' wählen.\n'],...
                                           ['Bei diesen Gesichtern überwiegen die Unterschiede. Sie sind sich nicht sehr ähnlich.\n',...
                                            'Entsprechen würde dies einer ''1'' oder ''2'' auf der Skala'],...
                                           ['Halten Sie bitte im Hinterkopf, dass dies nur grobe Richtlinien sind, und Sie völlig frei\n',...
                                            'in Ihrer Einschätzung sind. Schließlich sind wir an Ihrer Wahrnehmung der Gesichter interessiert.\n'],...
                                           ['Haben Sie die Verwendung der Skala verstanden? Falls ja, fahren Sie bitte mit der Leertaste fort.\n',...
                                            'Falls nein, wenden Sie sich bitte an den Testleiter.']};
            p.strings.welcome           = ['Herzlich Willkommen und vielen Dank für die Teilnahme.\n\n'...
                                           'Bitte betätigen Sie die Leertaste, um die Aufgabe zu starten.\n'];
            p.strings.explain1          = ['Im Folgenden sehen Sie jeweils zwei Gesicher wie unten zu sehen.\n'...
                                           'Ihre Aufgabe ist es zu entscheiden, wie ähnlich sich die Gesichter sind.\n\n'...
                                           'Weiter mit der Leertaste'];
            p.strings.explain2          = ['Geben Sie Ihre Einschätzung bitte auf einer Skala von 1 bis 5 an.\n'...
                                           '1 steht hierbei für überhaupt keine Ähnlichkeit, 5 steht für extreme Ähnlichkeit.\n\n'...
                                           'Benutzen Sie für Ihre Einschätzung bitte die Reihe mit Ziffern auf ihrer Tastatur.\n'...
                                           'Benutzen Sie bitte NICHT den Zahlenblock.\n'];
            p.strings.ready             = ['Haben Sie alles verstanden?\n\nFalls ja, können Sie nun mit der Leertaste das Experiment beginnen.\n'...
                                           'Falls nicht, wenden Sie sich bitte an den Testleiter.'];
            p.strings.versus            = 'vs.';
            p.strings.break             = ['Sie haben sich eine kleine Pause verdient. Dies war Block %d von %d.\n\n'...
                                           'Bitte fahren Sie eigenständig mit der Leertaste fort, sobald Sie soweit sind.'];
            p.strings.goodbye           = 'Vielen Dank, das war''s!\n\nBitte wenden Sie sich an den Testleiter.';
            p.strings.rating            = 'Gar nicht ähnlich   1   2   3   4   5    Extrem ähnlich';
        elseif strcmp(p.language, 'english')
            p.strings.extendedIntro     = {['To allow for you to get a feeling for the faces and how to use the scale, we''ll start by\n',... 
                                            'showing you some pairs of faces that differ in respect to how similar they are to each other.\n',...
                                            'Just a small reminder: ''1'' stands for no similarity at all, ''5'' stands for extreme similarity,\n',...
                                            'thus faces that are indistinguishable \n',...
                                            'Continue - here and on the following pages - with the space key!\n'],...
                                            'These faces are identical. This is equivalent to a ''5'' on the similarity scale.',...
                                           ['These faces are clearly distinguishable but still relatively similar to each other.\n',...
                                            'Accordingly you would probably use the mid-range of the scale, e.g. a ''3''.\n'],...
                                           ['In these faces, the differences dominate the similarities. They are not very similar.\n',...
                                            'This maps onto a ''1'' or ''2'' on the scale IF - and only if - this is in line with your perception.'],...
                                           ['Please keep in mind that these are only rough guidelines and you are absolutely unconstrained\n',...
                                            'in your estimation of similarities. After all we''re interested in your perception of these faces.\n'],...
                                            ['Did you understand how to use the scale? If yes, please continue using the space key.\n',...
                                             'If not, please approach the experimenter.\n']};
            p.strings.welcome           = ['Welcome and thanks for your participation!\n\n'...
                                           'Please press space to start the task.\n'];
            p.strings.explain1          = ['In the following trials you''ll see two faces as depicted below.\n'...
                                           'Your task is to decide how similar these faces are.\n\n'...
                                           'Continue with the space key.'];
            p.strings.explain2          = ['Please make your assessment of similarity using a scale from 1 to 5.\n'...
                                           '1 stands for no similarity at all, 5 stands for extreme similarity.\n\n'...
                                           'Please use the number keys in the top rows of your keyboard for this assessment.\n'...
                                           'Please do NOT use the number pad on the right of your keyboard.\n'];
            p.strings.explain3          = ['There are going to be 420 trials in total, which you''ll handle in 4 blocks.\n.',...
                                           'After each block you can have a small break if you like.\n'];
            p.strings.ready             = ['Did you understand everything?\n\nIf yes, you can start the experiment using the space key.\n'...
                                           'If not, please approach the experimenter.'];
            p.strings.versus            = 'vs.';
            p.strings.break             = ['You deserved a small break since you just finished block %d of %d.\n\n'...
                                           'Please continue in your own pace with the space key when you''re ready.'];
            p.strings.goodbye           = 'We''re done, thanks a lot!\n\nPlease approach the experimenter.';
            p.strings.rating            = 'Not at all similar   1   2   3   4   5    Extremely similar';
            
        else
            error(['Please speficy ''english'' or ''german'' as language argument.',...
                   'Or just leave it out in which case german is the default.']);
        end
        %define keys
        KbName('UnifyKeyNames');
        p.keys.leftArrow    = KbName('LeftArrow');
        p.keys.rightArrow   = KbName('RightArrow');
        p.keys.escape       = KbName('Escape');
        p.keys.enter        = KbName('Return');
        p.keys.space        = KbName('Space');
        p.keys.one          = 49;
        p.keys.two          = 50;
        p.keys.three        = 51;
        p.keys.four         = 52;
        p.keys.five         = 53;
%        p.keys.six          = 54;
%        p.keys.seven        = 55;
%        p.keys.eight        = 56;
%        p.keys.nine         = 57;
        p.keys.numbers      = 49:53;
        
        %settings for device and keyboard queue
        p.ptb.device                = [];
        p.ptb.keysIndex             = [];for ind = fields(p.keys)';p.ptb.keysIndex = [p.ptb.keysIndex,p.keys.(ind{1})];end;
        RestrictKeysForKbCheck(p.ptb.keysIndex);
        p.ptb.keysOfInterest        = zeros(1,256); p.ptb.keysOfInterest(p.ptb.keysIndex) = 1;
        KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);
        fprintf('Only the following keys will be screened for strokes and releases:\n');
        
        for ind = 1:numel(p.ptb.keysIndex)
            fprintf('KeyCode: %2s\n',KbName(p.ptb.keysIndex(ind)));
        end
        
        %set priority to max - this will favor computational demands of the
        %PTB before other background processes
        Priority(MaxPriority(p.ptb.win));
        
        %Make sure PsychHID (which is used for communication with devices
        %like mouses and keyboards) is ready when using windows
        if IsWin
            LoadPsychHID;
        end
        
    end

%% Load Stimuli
    function LoadStimuli
        %read the images into the workspace for faster processing
        %afterwards.
        p.stim.imArray         = zeros(p.stim.height,p.stim.width,p.stim.nStim);
        for ind = 1:p.stim.nStim
            p.stim.imArray(:,:,ind) = imread(p.stim.files(ind,:));
            p.stim.textures(ind)    = Screen('MakeTexture',p.ptb.win,p.stim.imArray(:,:,ind));
        end
        fprintf('%2d stimuli were read into the workspace.\n',p.stim.nStim);
        if intro == 1
            p.stim.intro.imArray                = zeros(p.stim.height,p.stim.width,p.stim.nStim);
            for ind = 1:p.stim.nStimIntro
                p.stim.intro.imArray(:,:,ind)   = imread(p.stim.intro.files(ind,:));
                p.stim.intro.textures(ind)      = Screen('MakeTexture',p.ptb.win,p.stim.intro.imArray(:,:,ind));
            end    
        end
    end
     
%% Introduction

    function Introduction
        DrawFormattedText(p.ptb.win,p.strings.welcome,'center','center',p.stim.white,[],[],[],1.5);
        Screen('Flip', p.ptb.win);
        WaitSpacePress;
        dummyTex    = p.stim.textures(randi(p.stim.nStim,1,2));
        DrawFormattedText(p.ptb.win,p.strings.explain1,'center',200,p.stim.white,[],[],[],1.5);
        DrawStimuli(dummyTex,1,0);
        Screen('Flip', p.ptb.win);
        WaitSpacePress;
        DrawFormattedText(p.ptb.win,p.strings.explain2,'center','center',p.stim.white,[],[],[],1.5);
        Screen('Flip', p.ptb.win);
        WaitSpacePress;
        DrawFormattedText(p.ptb.win, p.strings.ready,'center','center',p.stim.white, [], [], [], 1.5);
        Screen('Flip', p.ptb.win);
        WaitSpacePress;
    end %end of function introduction

%% ExplainScale
    function ExplainScale
        %there are supposed to be 6 pictures in the intro folder, which
        %have to be used in a certain order to make sense (bc they are
        %either similar or dissimilar
        %the following is the order of presentation:
        p.stim.intro.order  = [1,2;3,4;5,6];
        p.rowInd            = 1;
        for ind = 1: numel(p.strings.extendedIntro)
            Screen('FillRect',p.ptb.win,p.stim.bgIntro);
            DrawFormattedText(p.ptb.win,p.strings.extendedIntro{ind},'center',200,p.stim.white,[],[],[],1.5);
            if ismember(ind,2:4)
                DrawStimuli(p.stim.intro.textures(p.stim.intro.order(p.rowInd,:)),1,0);
                p.rowInd = p.rowInd +1; %update counter
            end
            Screen('Flip',p.ptb.win);
            WaitSpacePress;
        end
    end

%% RunTrials

    function RunTrials
        tic;
        blockNum    = 1;
          for nTrial  = 1: length(p.presentation.sequence)
            Screen('DrawLines',p.ptb.win,p.cross.coords,3,p.stim.white,p.ptb.midpoint); %present fixation cross
            vbl     = Screen('Flip',p.ptb.win);
            dummyTex    = p.stim.textures(ismember(p.presentation.stimlist,p.presentation.sequence(nTrial,:)));
            DrawStimuli(dummyTex, 0, 1);
            Screen('Flip', p.ptb.win, vbl + p.cross.duration );
            keyCode = zeros(1,256);
            while ~keyCode([p.keys.numbers,p.keys.escape])
                [~,~,keyCode] = KbCheck;
                if keyCode(p.keys.escape)
                    resp = input('Do you really want to abort the experiment? y/n','s');
                    WaitSecs(1);
                    commandwindow;
                    if strcmp(resp,'y')
                        sca;
                        error('Experiment aborted since you wanted it that way...');
                    end
                end
            end
            p.results(nTrial)   = find(keyCode)-48;
            if ismember(nTrial,p.breakTrials)
                p.blockDur(blockNum)    = toc;
                blockNum                = blockNum +1;
                OneBreak(p.blockCount,p.nBlocks);
                p.blockCount            = p.blockCount + 1;
                tic;
            end
            save( p.path.resultsName, 'p' );
         end
    end

    function GoodBye
        DrawFormattedText(p.ptb.win, p.strings.goodbye, 'center', 'center', p.stim.white,[], [], [], 1.5);
        Screen('Flip',p.ptb.win);
        keyCode     = zeros(1,256);
        while ~keyCode(p.keys.escape) %Finish presentation with escape.
            [~,~,keyCode]   = KbCheck;
        end;
        sca;
        save(p.path.resultsName, 'p' );
        fprintf('Data saved to %s.\n', p.path.resultsName );
        fprintf('Experiment sucessfully finished.\n');
    end
%%
%%functions being used by other functions

    function WaitSpacePress
        keyCode = zeros(1,256);
        while ~keyCode(p.keys.space)
            [~,keyCode] = KbStrokeWait(p.ptb.device);
        end
    end

    function OneBreak(blockNum,nBlocks)
        if strcmp(p.language,'german')
            p.breakMsg    = sprintf(['Das war Block %d von %d.\n\n',...
                                   'Sie können eine kurze Pause machen, wenn sie wollen.\n',...
                                   'Fahren Sie mit der Leertaste fort, sobald Sie soweit sind.'],blockNum,nBlocks);
        elseif strcmp(p.language,'english')
            p.breakMsg    = sprintf(['That was block %d of %d.\n\n',...
                                   'You can take a quick break, if you want to.\n',...
                                   'Continue with the space key, when you''re ready.'],blockNum,nBlocks);
        end
        DrawFormattedText(p.ptb.win,p.breakMsg,'center','center',p.stim.white,[],[],[],1.5);
        Screen('Flip',p.ptb.win);
        WaitSpacePress;
    end  

    function [FM, labels] = FileMatrix(path)
        %Takes a path with file extension associated to regexp (e.g.
        %C:\blabl\bla\*.bmp) returns the file matrix
        dummy = dir(path);
        FM    = [repmat([fileparts(path) filesep],length(dummy),1) vertcat(dummy(:).name)];
        labels = {dummy(:).name};
    end
    
    function DrawStimuli(textures, intro, rating) %draw, NOT flip faces
        if intro
            coords      = p.stim.coordsIntro1;
        else
            coords      = p.stim.coords;
        end
        Screen( 'DrawTextures', p.ptb.win,textures, [], coords );
        if rating
            DrawFormattedText(p.ptb.win,p.strings.rating,'center',p.ptb.midpoint(2)+300,p.stim.white);
        end
    end
 end