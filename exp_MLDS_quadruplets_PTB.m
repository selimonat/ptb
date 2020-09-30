function [p] = exp_MLDS_quadruplets_PTB(subID,varargin)
%[p] = exp_MLDS_quadruplets_PTB(subID[,familiarization][,language])
%
% Psychtoolbox script to present quadruplets consisting of two pairs of 
% visual stimuli. Participants are instructed to indicate which pair is more
% similar.
% 
% Expected input: 
%
%   subID: subject ID. The "running number" of the present subject.
%
%   varargin:
%   familiarization: indicates wether a introduction phase using other
%   stimuli is wanted (flag = 1) or not (flag = 0). Default is 1.
%   language:   char 'english' or 'german'
%
% Output is a structure p that contains all parameters of the experiment as  
% well as the responses of the subject
% and is meant to be processed using MLDS.
%
% Before using this script you'll have to make the following modifications:
%
%   Change the directory in the subfunction 'SetParams' to the one you want
%
%   Depending on your setup, change the screen that is to be used in the
%   subfunction 'SetPTB' - by default it uses the secondary display
%   
%   Adjust the link to the stimulus list if you want to use another one
%
%
% Lukas Neugebauer - 09/22/2017

%Set flag to 1 if you're in debugging mode. This will turn the opened window
%transparent, so you can close the window if needed.
%For real testing, change to 0
debug = 0;


if nargin == 1 % default is 1 for familiarization. 
    familiarization = 1;
elseif nargin ==2  % Use other value if given. Only 0 will have an effect though. 
    familiarization = varargin{1};
    language    = 'german';
elseif nargin < 1 && ~ debug
    error('Please pass a subID as first argument.');
elseif nargin == 3
    familiarization = varargin{1};
    language    = varargin{2};
end

if debug %assume subID and familiarization phase if we are in debug mode
    subID = 99;
    familiarization = 1;
    language    = 'german';
end

%% General preperations
%clear everything before we start. Then call GetSecs to load the mex file
clear mex global functions;
GetSecs;WaitSecs(0.001);
commandwindow; %give control back to commandwindow - this way you can close the ptb window by typing 'sca' and hitting enter

%set up needed variables
p               = []; %structure for parameters of the experiment
p.results       = [];
p.resultsFam    = [];
p.language      = language;

%run preparatory subfunctions. You find these at the end of the script
SetParams; %set parameters for the experiment.
SetPTB; %set up the Psychtoolbox and some additional stuff. 
LoadStimuli; %read pictures into the workspace

%% Run the experiment subfunctions

Introduction; %only welcome window, instructions and waiting for a space key stroke

if familiarization
    TestTrials; %present the introductory trials using stimuli that are not being used in the real trials
end

tic; %initiate stop watch
RunTrials; %Do the actual stuff

save(p.path.resultsName,'p'); %save the data
fprintf('Results were saved under %s\n',p.path.resultsName);

Goodbye; %show last screen
CleanUp; 

%% Additional functions used in the script
              
    function SetParams
    
        %define relevant directories
        [~,hostname]            = system('hostname');
        p.hostname              = deblank(hostname);
        p.path.experiment       = 'C:\Users\neugebauer\Documents\Experiments\FearGen\MLDS\'; 
        p.path.results          = [p.path.experiment,'resultsMLDS',filesep];
        
        if ~exist(p.path.results)
            mkdir(p.path.results);
            fprintf('The directory %d was created.',p.path.results);
        end
        
        p.path.baselocation     = [fileparts(which('exp_MLDS_quadruplets_PTB.m')), filesep, 'bin',filesep];
        p.path.stim             = [p.path.baselocation,'MLDS_Stimuli',filesep];
        p.path.stimFam          = [p.path.stim, 'Familiarization', filesep]; 
        p.path.sequence         = [p.path.baselocation,'stimList_MLDS.mat'];
        p.subID                 = sprintf('S%02d',subID);
        p.famFlag               = familiarization; %define for the output, wether a familiarization phase was used.
        p.path.resultsName      = [p.path.results,sprintf('%s_MLDS_FearGen_results.mat',p.subID)]; 
        
        if exist(p.path.resultsName) %give the opportunity to abort the experiment if the file already exists
            [~,dummyName]   = fileparts(p.path.resultsName); 
            response    = input(sprintf('A file of the name %s already exists.\nAre you sure that you want to overwrite it? [y/n]',dummyName),'s');
            if ~strcmp(response,'y')
                error('The experiment was aborted.');
            end
        end
           
        %locate stimuli
        [p.stim.files, p.stim.label]    = FileMatrix([p.path.stim,'*.bmp']);
        p.stim.nStim                    = numel(p.stim.label);
        fprintf('%2d stimuli found in the directory.\n', p.stim.nStim);
        
        if familiarization
            [p.stim.filesFam, p.stim.labelFam]  = FileMatrix([p.path.stimFam,'*.bmp']);
            p.stim.nStimFam                     = numel(p.stim.labelFam);
            fprintf('%2d familiarization stimuli found.\n', p.stim.nStimFam);
        end
        
        %adjust background luminance to the luminance of the pictures
        bg = zeros(p.stim.nStimFam,1);
        
        for ind = 1:p.stim.nStim
            dummyIm         = imread(p.stim.files(ind,:));
            bg(ind)         = dummyIm(1,1);
        end
        %it is being assumed that the familiarization stimuli are of the
        %same luminance (which should be matched due to preprocessing
        %anyway)
        
        %show warning if images don't have same luminance, otherwise set bg
        if sum(diff(bg)) == 0
            p.stim.bg       = double(unique(bg));
        else
            fprintf('Different backgound luminances were detected. Please check and possibly reprocess your stimuli.\n');
            keyboard;
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
        
        imInfoFam           = imfinfo(p.stim.filesFam(1,:));
        p.stim.widthFam     = imInfoFam.Width;
        p.stim.heightFam    = imInfoFam.Height;
               
        %define stuff for the fixation cross
        p.cross.length  = 15; %length of each of the arms of the cross
        p.cross.col     = 255; %color of the cross
                
        %define keys for the experiment
        KbName('UnifyKeyNames');
        p.keys.enter    = KbName('return');
        p.keys.escape   = KbName('escape');
        p.keys.space    = KbName('space');
        p.keys.y        = KbName('y');
        p.keys.m        = KbName('m');
        p.keys.ansKeys  = [p.keys.y,p.keys.m];
        
        %define the durations of the trials and frequency of breaks
        p.duration.ITI          = 1;
        p.duration.showFaces    = 6;
        p.duration.breakTime    = 90;
        p.stim.breakFreq        = 100; 
        
        %Sequence of quadruples: load the respective file
        s               = load(p.path.sequence);
        p.sequence      = s.stimList;
        p.stim.nTrials  = length(p.sequence);
        clear s;
        p.nBlocks       = ceil(p.stim.nTrials/p.stim.breakFreq);
        
        %variable for timings (how long did particants take)
        p.timings       = zeros(p.nBlocks);
    end   

    function SetPTB  %initialize stuff for the psychtoolbox
        Screen('Preference','SkipSyncTests',1); %skip sync tests, so experiment runs also on shitty set-ups. Timing is not important for this task.
        Screen('Preference','SkipSyncTests', 1);
        Screen('Preference','DefaultFontSize', p.text.fontSize);
        Screen('Preference','DefaultFontName', p.text.fontName);
        Screen('Preference','TextAntiAliasing',2);%enable textantialiasing high quality
        Screen('Preference','VisualDebuglevel', 0);
        Screen('Preference','SkipSyncTests', 1);
        Screen('Preference','SuppressAllWarnings', 1);
        
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
        p.stim.vertDist = 50;
        p.stim.horDist  = 5;
        
        %define wanted size of stimuli
        p.stim.sizeVert = 300;
        p.stim.sizeHor  = p.stim.sizeVert*(p.stim.width/p.stim.height);
        
        %define midpoint of screen and coordinates for stimuli/fixation crss
        p.ptb.midpoint              = [p.ptb.width/2, p.ptb.height/2];
        p.stim.coords               = [p.ptb.midpoint(1)-p.stim.horDist-p.stim.sizeHor,p.ptb.midpoint(2)-p.stim.sizeVert-p.stim.vertDist,p.ptb.midpoint(1)-p.stim.horDist,p.ptb.midpoint(2)-p.stim.vertDist;
                                       p.ptb.midpoint(1)+p.stim.horDist,p.ptb.midpoint(2)-p.stim.vertDist-p.stim.sizeVert,p.ptb.midpoint(1)+p.stim.horDist+p.stim.sizeHor,p.ptb.midpoint(2)-p.stim.vertDist;
                                       p.ptb.midpoint(1)-p.stim.horDist-p.stim.sizeHor,p.ptb.midpoint(2)+p.stim.vertDist,p.ptb.midpoint(1)-p.stim.horDist,p.ptb.midpoint(2)+p.stim.vertDist+p.stim.sizeVert;
                                       p.ptb.midpoint(1)+p.stim.horDist,p.ptb.midpoint(2)+p.stim.vertDist,p.ptb.midpoint(1)+p.stim.horDist+p.stim.sizeHor,p.ptb.midpoint(2)+p.stim.vertDist+p.stim.sizeVert]';
        p.cross.coords              = [0,0,-p.cross.length,p.cross.length;-p.cross.length,p.cross.length,0,0];
       
        %the strings that are used to communicate with the subjects
        if strcmp(p.language,'german')
            p.strings.welcome           = ['Herzlich Willkommen und vielen Dank für die Teilnahme.\n\n'...
                                           'Bitte betätigen Sie die Leertaste, um die Aufgabe zu starten.\n'];
            p.strings.explain1          = ['Im Folgenden sehen Sie jeweils vier verschiedene Gesicher.\n'...
                                           'Dabei bilden je die beiden oberen und die beiden unteren Bilder ein Paar.\n'...
                                           'Ihre Aufgabe ist es zu entscheiden, in welchem Paar sich die Gesichter ähnlicher sind.\n\n'...
                                           'Sind Sie der Meinung, das obere Paar sei sich ähnlicher als das untere,\n drücken Sie bitte die Taste ''Y'' auf der Tastatur\n'...
                                           'Glauben Sie hingegen, das untere Paar sei sich ähnlicher als das obere,\n drücken Sie die Taste ''M''.\n\n'...
                                           'Weiter mit der Leertaste'];
            p.strings.explain2          = ['Die Bilder werden Ihnen je für 6 Sekunden präsentiert und verschwinden anschließend.\n'...
                                           'Sie haben auch danach noch Zeit zu antworten. Antworten Sie bitte dennoch so schnell wie möglich,\n'...
                                           'idealerweise noch während die Bilder zu sehen sind. Bitte antworten Sie intuitiv und\n'...
                                           'machen sich keine großen Gedanken darüber machen, warum Sie antworten, wie Sie es tun.\n\n'...
                                           'Haben Sie alles verstanden? Falls ja, können Sie das Experiment mit der Leertaste starten.'];
            p.strings.fam1              = ['Zunächst werden Sie ein paar Durchläufe zur Übung bearbeiten.\n'...
                                           'Die Anweisung wird währenddessen oben im Bildschirm eingeblendet sein.\n'...
                                           'Bitte beachten Sie, dass dies während der richtigen Durchläufe nicht mehr\n'...
                                           'so sein wird und prägen sich die Anweisung daher gut ein.\n\n'...
                                           'Starten Sie die Probedurchläufe, wenn Sie soweit sind, mit der Leertaste.'];
            p.strings.fam2              = ['Das war''s mit den Probetrials. Haben Sie sich gut gemerkt, wie es funktioniert?\n'...
                                           'Dann können wir jetzt mit den richtigen Durchläufen beginnen.\n\n'...
                                           'Drücken Sie bitte die Leertaste, um zu beginnen.'];
            p.strings.versus            = 'vs.';
            p.strings.pleaseAns         = ['Bitte antworten Sie zügig:\n\n'...
                                           '''Y'' wenn sich die oberen Gesicher mehr ähneln.\n'...
                                           '''M'' wenn sich die unteren Gesichter mehr ähneln.'];
            p.strings.famExplain        = ['Drücken Sie ''Y'', falls sich die oberen Gesichter ähnlicher sind.\n'...
                                           'Drücken Sie ''M'', falls sich die unteren Gesichter ähnlicher sind.\n'];
            p.strings.break             = ['Sie haben sich eine kleine Pause verdient. Dies war Block %d von %d.\n\n'...
                                           'Bitte fahren Sie eigenständig mit der Leertaste fort, sobald Sie soweit sind.'];
            p.strings.goodbye           = 'Vielen Dank, das war''s!\n\nBitte wenden Sie sich an den Testleiter.';
        elseif strcmp(p.language,'english')
            p.strings.welcome           = ['Welcome and thanks a lot for you participation!\n',...
                                           'Please start the task by pressing the space key.'];
            p.strings.explain1          = ['In the following trials you will see four different faces each.\n',...
                                           'The upper two and lower two faces respectively form a pair.\n',...
                                           'Your task is to decide in which pair the faces are more similar to each other.\n',...
                                           'If you perceive the upper pair to be more similar, please press the key ''Y'' on the keyboard.\n',...
                                           'On the other hand, if you think that the lower pair is more similar, plese press the key ''M''.\n\n',...
                                           'Continue with the space key.'];
            p.strings.explain2          = ['The pictures are being presented for 6 seconds each and will disappear afterwards.\n',...
                                           'You still have time to answer after that. However, please answer as quickly as possible -\n',...
                                           'ideally while the pictures are still present on the screen. Please answer intuitively and\n',...
                                           'don''t think too much about it, why you answer the way you do.\n\n',...
                                           'Did you understand everything? If yes, you can start the experiment using the space key.'];
            p.strings.fam1              = ['Initially you will go through some trials for practice purposes.\n',...
                                           'During this, the instructions will be shown in the upper part of the screen.\n',...
                                           'Please note that this will no longer be the case during the actual trials\n',...
                                           'and try to remember them as precisely as possible accordingly.\n',...
                                           'Use the space key to start the practice trials whenever you''re ready.'];
            p.strings.fam2              = ['We''re done with the practive trials. Did you remember the instructions well enough?\n',...
                                           'In this case we can start with the actual trials.\n\n',...
                                           'Please press space to begin.'];
            p.strings.versus            = 'vs.';
            p.strings.pleaseAns         = ['Please answer quickly:\n\n',...
                                           '''Y'' if the upper faces are more similar.\n',...
                                           '''M'' if the lower faces are more similar.\n'];
            p.strings.famExplain        = ['Press ''Y'', if the upper faces are more similar.\n'...
                                           'Press ''M'', if the lower faces are more similar.'];
            p.strings.break             = ['You deserve a little break. This was block %d of %d.\n\n',...
                                           'Please continue with the space key, whenever you''re ready.'];
            p.strings.goodbye           = 'Thanks a lot, we''re done!\n\nPlease contact the experimenter.';
        end
        
        %set priority to max - this will favor computational demands of the
        %PTB before other background processes
        Priority(MaxPriority(p.ptb.win));
        
        %Make sure PsychHID (which is used for communication with devices
        %like mouses and keyboards) is ready when using windows
        if IsWin
            LoadPsychHID;
        end
        
        %settings for device and keyboard queue
        p.ptb.device                = [];
        p.ptb.keysIndex             = [];for ind = fields(p.keys)';p.ptb.keysIndex = [p.ptb.keysIndex,p.keys.(ind{1})];end;
        RestrictKeysForKbCheck(p.ptb.keysIndex);
        p.ptb.keysOfInterest        = zeros(1,256); p.ptb.keysOfInterest(p.ptb.keysIndex) = 1;
        KbQueueCreate(p.ptb.device,p.ptb.keysOfInterest);
        fprintf('Only the following keys will be screened for strokes and releases:\n');
        
        for ind = 1:numel(p.ptb.keysIndex)
            fprintf('KeyCode: %2d\n',p.ptb.keysIndex(ind));
        end
    end

    function LoadStimuli
        %read the images into the workspace for faster processing
        %afterwards.
        p.stim.imArray         = zeros(p.stim.height,p.stim.width,p.stim.nStim);
        for ind = 1:p.stim.nStim
            p.stim.imArray(:,:,ind)    = imread(p.stim.files(ind,:));
        end
        fprintf('%2d stimuli were read into the workspace.\n',p.stim.nStim);
        for ind = 1:size(p.stim.imArray,3) %turn them into texture
            p.stim.textures(ind)  = Screen('MakeTexture',p.ptb.win,p.stim.imArray(:,:,ind));
        end
        if familiarization 
            p.stim.imArrayFam      = zeros(p.stim.heightFam,p.stim.widthFam,p.stim.nStimFam);
            for ind = 1: p.stim.nStimFam
                p.stim.imArrayFam(:,:,ind) = imread(p.stim.filesFam(ind,:));
            end
            fprintf('%2d familiarization stimuli were read into the workspace.\n',p.stim.nStimFam);
            for ind = 1: p.stim.nStimFam
                p.stim.texturesFam(ind)  = Screen('MakeTexture',p.ptb.win,p.stim.imArrayFam(:,:,ind));
            end
            p.famTrialN     = 10; %how many familiarization trials are wanted.
            p.famSequence   = [];
            for ind = 1:p.famTrialN
                p.famSequence(ind,:)    = randsample(1:p.stim.nStimFam,4,0);
            end
        end
    end

    function Introduction
        DrawFormattedText(p.ptb.win,p.strings.welcome,'center','center',p.stim.white,[],[],[],1.5); %Show welcome message
        Screen('Flip',p.ptb.win);
        WaitSpacePress;
        DrawFormattedText(p.ptb.win,p.strings.explain1,'center','center',p.stim.white,[],[],[],1.5); %Show explanatory text
        Screen('Flip',p.ptb.win);
        WaitSpacePress;
        DrawFormattedText(p.ptb.win,p.strings.explain2,'center','center',p.stim.white,[],[],[],1.5); 
        Screen('Flip',p.ptb.win);
        WaitSpacePress;
    end
            
    function TestTrials 
        DrawFormattedText(p.ptb.win,p.strings.fam1,'center','center',p.stim.white,[],[],[],1.5);
        Screen('Flip',p.ptb.win);
        WaitSpacePress;
        for nTrials     = 1:p.stim.nStimFam
            dummySeq    = p.famSequence(nTrials,:);
            dummyTex    = p.stim.texturesFam(dummySeq);
            p.resultsFam(nTrials,:)     = OneTrial(dummySeq,dummyTex,1);
        end
        DrawFormattedText(p.ptb.win,p.strings.fam2,'center','center',p.stim.white,[],[],[],1.5);
        Screen('Flip',p.ptb.win);
        WaitSpacePress;
    end

    function RunTrials
        tic;nBlock = 1;
        for nTrials     = 1:p.stim.nTrials
            dummySeq            = p.sequence(nTrials,:); %faces for the trial
            dummyTex            = p.stim.textures(dummySeq); %textures of these faces
            p.results(nTrials,:)    = OneTrial(dummySeq,dummyTex,0);
            if mod(nTrials,p.stim.breakFreq) == 0 && nTrials ~= p.stim.nTrials
                p.timings(nBlock)   = toc;
                OneBreak(nBlock,p.nBlocks);
                tic;nBlock = nBlock + 1;
            end
            save(p.path.resultsName,'p');%save after every trial for case of unexpected crash
        end
    end

    function Goodbye
        DrawFormattedText(p.ptb.win,p.strings.goodbye,'center','center',p.stim.white,[],[],[],1.5);
        Screen('Flip',p.ptb.win);
        keyCode     = zeros(1,256);
        while ~keyCode(p.keys.escape) %Finish presentation with escape.
            [~,~,keyCode]   = KbCheck;
        end;
    end

    function CleanUp
        sca;
        clear all;
        close all;
        disp('The experiment was sucessfully terminated.')
    end

%% Functions being used by other functions 
%don't worry. We won't go deeper down that rabbit hole ;)

    function dummyOut   = OneTrial(dummySeq,dummyTex,famFlag)
    %run one trial, return used stimuli and answer in a 1x5-vector.
    %famFlag indicates familiarization phase. In this, possible answers are
    %shown to simplify learning
        Screen('DrawLines',p.ptb.win,p.cross.coords,3,p.stim.white,p.ptb.midpoint); %present fixation cross
        vbl     = Screen('Flip',p.ptb.win);
        Screen('DrawTextures',p.ptb.win,dummyTex,[],p.stim.coords); %present faces
        DrawFormattedText(p.ptb.win,p.strings.versus,'center','center',p.stim.white);
        if famFlag %present instructions on top of the screen in familiarization phase
            DrawFormattedText(p.ptb.win,p.strings.famExplain,'center',100,p.stim.white,[],[],[],1.5);
        end
        vbl     = Screen('Flip',p.ptb.win,(vbl + p.duration.ITI));
        maxImageTime    = vbl  + p.duration.showFaces; %until then faces are shown
        timeUntilBreak  = vbl  + p.duration.breakTime; %after this time the code will break.
        keyCode         = zeros(1,256);
        preInd          = 1; %only go into the first if-loop once.
        while ~keyCode([p.keys.ansKeys,p.keys.escape])  
            if keyCode(p.keys.escape)
                WaitSecs(0.5);commandwindow;
                resp = input('Do you really want to abort the experiment? [y/n]','s');
                if strcmp(resp,'y')
                    error('Experiment aborted.');
                else
                    keyCode = zeros(1,256); %reset keycode to keep while loop running
                end
            end
            vbl = GetSecs;
            if vbl > maxImageTime && preInd ==1 %show image only for certain time               
               DrawFormattedText(p.ptb.win,p.strings.pleaseAns,'center','center',p.stim.white,[],[],[],1.5); 
               Screen('Flip',p.ptb.win);
               preInd = 0;
            end
            if vbl > timeUntilBreak
                sca;
                error('Experiment was aborted due to inactivity for more than %d seconds.',p.duration.breakTime);
            end
            [~,~,keyCode]   = KbCheck;
        end
        Screen('Flip',p.ptb.win);
        dummyKey       = find(keyCode);
        if dummyKey    == p.keys.y
            dummyAns = 0;
        elseif dummyKey == p.keys.m
            dummyAns = 1;
        end
        dummyOut    = [dummyAns,dummySeq];
    end
 
    function OneBreak(thisBlock,allBlocks)
        breakMsg    = sprintf(p.strings.break,thisBlock,allBlocks);
        DrawFormattedText(p.ptb.win,breakMsg,'center','center',p.stim.white,[],[],[],1.5);
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

    function WaitSpacePress %outsource function for readability and lazyness
        keyCode = zeros(1,256);
        while ~keyCode(p.keys.space)
            [~,keyCode] = KbStrokeWait(p.ptb.device);
        end
    end

end