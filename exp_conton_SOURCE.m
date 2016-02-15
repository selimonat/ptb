
%Contextual Modulation of old/new effects%
%14-Feb-2016, n.herweg@uke.de

%% CLEAN UP
clear all;close all;clc;
PsychDefaultSetup(2);
sca;

warning('replace images 45 and 129 outdoor')
%seed random nurmber generator based on the current time
rng('shuffle');

%% DEFINE VARIABLES
%Phase 1: initial encoding
time.p1.pic         = 1;
time.p1.fix         = 1.5;
time.p1.resp        = 2;

n.p1.test.pics.targ  = 2;
n.p1.test.pics.new   = 160;
n.p1.test.shows.reg  = 3;%times each regular image will be shown
n.p1.test.shows.targ = n.p1.test.shows.reg*(n.p1.test.pics.new/10);
n.p1.test.trials     = n.p1.test.pics.new*n.p1.test.shows.reg + n.p1.test.pics.targ*n.p1.test.shows.targ;
n.p1.test.t2b        = 96; %N trials until next break

n.p1.train.pics.targ  = n.p1.test.pics.targ;
n.p1.train.pics.new   = 4;
n.p1.train.shows.reg  = 3;
n.p1.train.shows.targ = n.p1.train.shows.reg*2;
n.p1.train.trials   = n.p1.train.pics.new*n.p1.train.shows.reg + n.p1.train.pics.targ*n.p1.train.shows.targ;
n.p1.train.t2b      = n.p1.train.trials;

%Phase 2: Interleaved encoding/retrieval
time.p2.pic         = time.p1.pic;
time.p2.fix         = 2.3;%TBD 300ms to save everything & turn on tracker again, distribute trials across TR
time.p2.resp        = 2.8;%TBD
time.trackerOff     = 1.8;%200 ms to turn off tracker before button presses are recorded

relnew.p2           = 1;%amount of new pictures relative to old ones

n.p2.test.pics.old  = n.p1.test.pics.new;
n.p2.test.pics.new  = n.p2.test.pics.old*relnew.p2;
n.p2.test.tpb       = 8;      %number of trials per block TBD, Alternativ 16, 20 blocks, dann 5 runs
n.p2.test.trials    = n.p2.test.pics.old + n.p2.test.pics.new;
n.p2.test.blocks    = n.p2.test.trials/n.p2.test.tpb;
n.p2.test.runs      = 5;%TBD Alternativ 10 a 4 Blöcke
n.p2.test.bpr       = n.p2.test.blocks/n.p2.test.runs;%blocks per run
n.p2.test.tpr       = n.p2.test.trials/n.p2.test.runs;%trials per run
n.p2.test.t2b       = n.p2.test.tpr; %make a break after every run

n.p2.train.pics.old = n.p1.train.pics.new;
n.p2.train.pics.new = n.p2.train.pics.old*relnew.p2;
n.p2.train.trials   = n.p2.train.pics.old + n.p2.train.pics.new;
n.p2.train.tpb      = 4;
n.p2.train.blocks   = n.p2.train.trials/n.p2.train.tpb;
n.p2.train.runs     = 1;
n.p2.train.bpr      = n.p2.train.blocks/n.p2.train.runs;%blocks per run
n.p2.train.tpr      = n.p2.train.trials/n.p2.train.runs;%trials per run
n.p2.train.t2b      = n.p2.train.trials;

%Phase 3: Final retrieval
time.p3.pic         = time.p1.pic;
time.p3.fix         = 3;%TBD
time.p3.resp        = 4;%TBD

relnew.p3           = 0.5;%amount of new pictures relative to old ones

n.p3.test.pics.old  = n.p2.test.pics.old + n.p2.test.pics.new;
n.p3.test.pics.new  = n.p3.test.pics.old*relnew.p3;
n.p3.test.trials    = n.p3.test.pics.old + n.p3.test.pics.new;
n.p3.test.t2b       = 60;

n.p3.train.pics.old = n.p2.train.pics.old + n.p2.train.pics.new;%
n.p3.train.pics.new = n.p3.train.pics.old*relnew.p3;
n.p3.train.trials   = n.p3.train.pics.old + n.p3.train.pics.new;
n.p3.train.t2b      = n.p3.train.trials;

%General
n.pics.total = n.p1.test.pics.new + n.p1.test.pics.targ + n.p2.test.pics.new + n.p3.test.pics.new + n.p1.train.pics.new + n.p2.train.pics.new + n.p3.train.pics.new;

inst2load.p1.train = [1,2];
inst2load.p1.test = 3;
inst2load.p2.train = [4,5];
inst2load.p2.test = 6;
inst2load.p3.train = [7,8];
inst2load.p3.test = 9;

thepart{1} = 'train';
thepart{2} = 'test';

thecat{1}  = 'inn';
thecat{2}  = 'out';

thecond{1} = 'enc';
thecond{2} = 'ret';

thephase{1} = 'p1';
thephase{2} = 'p2';
thephase{3} = 'p3';

%% LOAD/CREATE FILEX
%enter subject ID
subID    = input('Enter subject ID: ','s');
if size(subID,2)>7
    error('ID is too long!')
end
fileName = ['CONTON_' num2str(subID) '.mat'];

%Enter session number
phasei  = input('Enter experimental phase (1, 2, or 3): ');
parti = input('Enter subpart (1 for training, 2 for testing): ');

%specify project path
init            = [];
[~, hostname] = system('hostname');
init.(thephase{phasei}).hostname                  = deblank(hostname);

switch init.(thephase{phasei}).hostname
    case 'triostim1'
        init.(thephase{phasei}).thepath.project       = 'C:\USER\herweg\07_conton\MR';
        init.(thephase{phasei}).thepath.inst     = [init.(thephase{phasei}).thepath.project '\experiment\instructions\buttonbox'];
        addpath('C:\USER\herweg\ptb\exp_conton_functions');
    case 'isnf01faf2bafa4'
        init.(thephase{phasei}).thepath.project       = 'C:\Users\herweg\Documents\_Projekte\07_conton\MR';
        init.(thephase{phasei}).thepath.inst     = [init.(thephase{phasei}).thepath.project '\experiment\instructions\keyboard'];
        init.(thephase{phasei}).whichmonitor = input('Which monitor? Type s for small, l for large, e for eyetracking and lab 218.','s');
        addpath('C:\Users\herweg\Documents\GitHub\ptb\exp_conton_functions');
    case 'etpc'
        init.(thephase{phasei}).thepath.project       = 'C:\USER\herweg\07_conton\MR';
        init.(thephase{phasei}).thepath.inst     = [init.(thephase{phasei}).thepath.project '\experiment\instructions\keyboard'];
        addpath('C:\USER\herweg\ptb\exp_conton_functions');
end
init.(thephase{phasei}).thepath.pics_inn = [init.(thephase{phasei}).thepath.project '\pics\inn_color\mean127RGB'];
init.(thephase{phasei}).thepath.pics_out = [init.(thephase{phasei}).thepath.project '\pics\out_color\mean127RGB'];
init.(thephase{phasei}).thepath.results  = [init.(thephase{phasei}).thepath.project '\data'];

init.(thephase{phasei}).debug      = 0; %debug mode = 1, testing = 0

%init.thepath.scripts  = [init.thepath.project '\experiment'];
%addpath(fullfile(init.thepath.project,'experiment\functions'));


%check if fileX already exists and warn, if overwriting is confirmed load
if exist(fullfile(init.(thephase{phasei}).thepath.results,fileName),'file')
    
    resp=input(['The file ' fileName ' already exists. Do you want to overwrite it? [Type ok to overwrite]'], 's');
    
    if ~strcmp(resp,'ok') %abort experiment if overwriting was not confirmed
        disp('experiment aborted')
        return
    end
    newinit = init;
    clear init
    
    load(fullfile(newinit.(thephase{phasei}).thepath.results,fileName)); %Loads the .m-file containing the subject's data.
    load(fullfile(newinit.(thephase{phasei}).thepath.results,[fileName(1:end-4),'_init.mat'])); %Loads the .m-file containing the subject's data.
    
    init.(thephase{phasei}) = []; %this clears former initialization values (e.g. from training)
    init.(thephase{phasei}) = newinit.(thephase{phasei});
    clear newinit
else
    
    init.continuous = 0; %all phases = 1, only current phase = 0
    %specify MR parameters
    init.mr.ndummy  = 6;
    
    fileX.subID    = subID;
    fileX.fileName = fileName;
    fileX.keycond  = input('Enter number for key mapping (1-4): ','s');
    
    %assign category, condition, targetness and oldnew to trials
    for partj = 1:size(thepart,2)
        fileX.p1.(thepart{partj})(:,2) = repmat([1;2],n.p1.(thepart{partj}).trials/size(thecat,2),1);% 2 category
        fileX.p1.(thepart{partj})(:,3) = [ones(n.p1.(thepart{partj}).pics.targ*n.p1.(thepart{partj}).shows.targ,1);ones(n.p1.(thepart{partj}).pics.new*n.p1.(thepart{partj}).shows.reg,1)*0];%3 targetness 1 = target, 0 = no target
        fileX.p1.(thepart{partj})(:,1) = rand(size(fileX.p1.(thepart{partj}),1),1);
        fileX.p1.(thepart{partj})      = sortrows(fileX.p1.(thepart{partj}),1);
        fileX.p1.(thepart{partj})(:,1) = (1:n.p1.(thepart{partj}).trials);%1 trialnumber
        fileX.p1.(thepart{partj})(fileX.p1.(thepart{partj})(:,3)==0,4) = 1; %all trials that are not targets are encoding trials
        
        fileX.p2.(thepart{partj})(:,1) = (1:n.p2.(thepart{partj}).trials);%1 trialnumber
        
        for blocki = 1:n.p2.(thepart{partj}).blocks %equal number of in/out and old/new per block
            catrand(:,1) = repmat([1;2],n.p2.(thepart{partj}).tpb/size(thecat,2),1);% 2 category
            catrand(:,2) = repmat([1;2;2;1],(n.p2.(thepart{partj}).tpb/size(thecat,2))/2,1);% 3 oldnew 1 = new; 2 = old
            catrand(:,3) = rand(size(catrand,1),1);
            catrand      = sortrows(catrand,3);
            
            fileX.p2.(thepart{partj})(1+((blocki-1)*n.p2.(thepart{partj}).tpb):n.p2.(thepart{partj}).tpb+((blocki-1)*n.p2.(thepart{partj}).tpb),2:3) = catrand(:,1:2);
            clear catrand
        end
        for runi = 1: n.p2.(thepart{partj}).runs
            condrand      = repmat([1;2],n.p2.(thepart{partj}).bpr/size(thecond,2),1);
            condrand(:,2) = rand(size(condrand,1),1);
            condrand      = sortrows(condrand,2);
            
            fileX.p2.(thepart{partj})(1+((runi-1)*n.p2.(thepart{partj}).tpr):n.p2.(thepart{partj}).tpr+((runi-1)*n.p2.(thepart{partj}).tpr),4) = kron(condrand(:,1),ones(n.p2.(thepart{partj}).tpb,1));%4 encret 1 = enc; 2 = ret
            clear condrand
        end
    end
    
    fileX.p3.test(:,2) = repmat([1;2],n.p3.test.trials/size(thecat,2),1);% 2 category
    fileX.p3.test(:,3) = repmat([ones(16,1);ones(32,1)*2],10,1);%3 oldnew 1 = new; 2 = old
    fileX.p3.test(:,4) = repmat([1;1;2;2],(n.p3.test.trials/size(thecat,2))/2,1);% 4 encret 1 = enc; 2 = ret
    fileX.p3.test(:,5) = repmat([1;1;1;1;2;2;2;2],(n.p3.test.trials/size(thecat,2))/4,1);% 5 poldnew 1 = pnew; 2 = pold  %% previously old or new in p2
    fileX.p3.test(:,1) = rand(size(fileX.p3.test,1),1);
    fileX.p3.test      = sortrows(fileX.p3.test,1);
    fileX.p3.test(:,1) = (1:n.p3.test.trials);% 1 trialnumber
    fileX.p3.test(fileX.p3.test(:,3) == 1,4:5) = 0;%condition 4 and 5 only exist for old images
    
    fileX.p3.train(:,2)   = repmat([1;2],n.p3.train.trials/size(thecat,2),1);%in/outdoor
    fileX.p3.train(:,3)   = repmat([1;1;2;2;2;2],2,1);%3 old/new
    fileX.p3.train(:,4)   = repmat([0;0;1;1;2;2],2,1);% 4 encret 1 = enc; 2 = ret
    fileX.p3.train(:,5)   = [0;0;1;1;1;1;0;0;2;2;2;2];% 5 poldnew 1 = pnew; 2 = pold  %% previously old or new in p2
    fileX.p3.train(:,1)   = rand(size(fileX.p3.train,1),1);
    fileX.p3.train        = sortrows(fileX.p3.train,1);
    fileX.p3.train(:,1)   = 1:n.p3.train.trials;
    
    for cati = 1:size(thecat,2)
        %assign scenes to phases of the experiment
        sc.all(:,1) = (1:1:n.pics.total/2);
        sc.all(:,2) = rand(size(sc.all,1),1);
        sc.all      = sortrows(sc.all,2);
        sc.all(:,2) = [ones(n.p1.train.pics.new/size(thecat,2),1);ones(n.p1.train.pics.targ/size(thecat,2),1)*2;ones(n.p1.test.pics.new/size(thecat,2),1)*3;...
            ones(n.p2.train.pics.new/size(thecat,2),1)*4;ones(n.p2.test.pics.new/size(thecat,2),1)*5;ones(n.p3.train.pics.new/size(thecat,2),1)*6;...
            ones(n.p3.test.pics.new/size(thecat,2),1)*7];%1=train p1; 2=target p1; 3=test p1; 4=train p2; 5=test p2; 6=train p3; 7=test p3
        
        sc.p1.train.new = sc.all(sc.all(:,2)==1,1);
        sc.p1.train.targ = sc.all(sc.all(:,2)==2,1);
        sc.p1.test.targ = sc.all(sc.all(:,2)==2,1);
        sc.p1.test.new  = sc.all(sc.all(:,2)==3,1);
        sc.p2.train.new = sc.all(sc.all(:,2)==4,1);
        sc.p2.test.new  = sc.all(sc.all(:,2)==5,1);
        sc.p3.train.new = sc.all(sc.all(:,2)==6,1);
        sc.p3.test.new  = sc.all(sc.all(:,2)==7,1);
        
        for partj = 1:size(thepart,2)
            %adapt sc to the number of times each scene is shown and include old images from previous phases; randomize
            %again
            sc.p1.(thepart{partj}).new      = repmat(sc.p1.(thepart{partj}).new,n.p1.(thepart{partj}).shows.reg,1);
            sc.p1.(thepart{partj}).new(:,2) = rand(size(sc.p1.(thepart{partj}).new,1),1);
            sc.p1.(thepart{partj}).new      = sortrows(sc.p1.(thepart{partj}).new,2);
            sc.p1.(thepart{partj}).new(:,2) = [];
            
            sc.p1.(thepart{partj}).targ     = repmat(sc.p1.(thepart{partj}).targ,n.p1.(thepart{partj}).shows.targ,1);
            sc.p1.(thepart{partj}).targ(:,2)= rand(size(sc.p1.(thepart{partj}).targ,1),1);
            sc.p1.(thepart{partj}).targ     = sortrows(sc.p1.(thepart{partj}).targ,2);
            sc.p1.(thepart{partj}).targ(:,2)= [];
            
            sc.p2.(thepart{partj}).old      = unique(sc.p1.(thepart{partj}).new);
            sc.p2.(thepart{partj}).old(:,2) = rand(size(sc.p2.(thepart{partj}).old,1),1);
            sc.p2.(thepart{partj}).old      = sortrows(sc.p2.(thepart{partj}).old,2);
            sc.p2.(thepart{partj}).old(:,2) = [];
            
            %put new and old scenes in fileX
            fileX.p1.(thepart{partj})(fileX.p1.(thepart{partj})(:,2)==cati & fileX.p1.(thepart{partj})(:,4)==1,6) = sc.p1.(thepart{partj}).new;
            fileX.p1.(thepart{partj})(fileX.p1.(thepart{partj})(:,2)==cati & fileX.p1.(thepart{partj})(:,4)==0,6) = sc.p1.(thepart{partj}).targ;
            
            fileX.p2.(thepart{partj})(fileX.p2.(thepart{partj})(:,2)==cati & fileX.p2.(thepart{partj})(:,3)==1,6) = sc.p2.(thepart{partj}).new;
            fileX.p2.(thepart{partj})(fileX.p2.(thepart{partj})(:,2)==cati & fileX.p2.(thepart{partj})(:,3)==2,6) = sc.p2.(thepart{partj}).old;
            
            %sort old scenes for p3 according to assigned conditions
            sc.p3.(thepart{partj}).old.pold.enc = fileX.p2.(thepart{partj})(fileX.p2.(thepart{partj})(:,2)==cati & fileX.p2.(thepart{partj})(:,3)==2 & fileX.p2.(thepart{partj})(:,4)==1,6);
            sc.p3.(thepart{partj}).old.pnew.enc = fileX.p2.(thepart{partj})(fileX.p2.(thepart{partj})(:,2)==cati & fileX.p2.(thepart{partj})(:,3)==1 & fileX.p2.(thepart{partj})(:,4)==1,6);
            
            sc.p3.(thepart{partj}).old.pold.ret = fileX.p2.(thepart{partj})(fileX.p2.(thepart{partj})(:,2)==cati & fileX.p2.(thepart{partj})(:,3)==2 & fileX.p2.(thepart{partj})(:,4)==2,6);
            sc.p3.(thepart{partj}).old.pnew.ret = fileX.p2.(thepart{partj})(fileX.p2.(thepart{partj})(:,2)==cati & fileX.p2.(thepart{partj})(:,3)==1 & fileX.p2.(thepart{partj})(:,4)==2,6);
            
            sc.p3.(thepart{partj}).old.pold.enc(:,2) = rand(size(sc.p3.(thepart{partj}).old.pold.enc,1),1);
            sc.p3.(thepart{partj}).old.pnew.enc(:,2) = rand(size(sc.p3.(thepart{partj}).old.pnew.enc,1),1);
            sc.p3.(thepart{partj}).old.pold.ret(:,2) = rand(size(sc.p3.(thepart{partj}).old.pold.ret,1),1);
            sc.p3.(thepart{partj}).old.pnew.ret(:,2) = rand(size(sc.p3.(thepart{partj}).old.pnew.ret,1),1);
            
            sc.p3.(thepart{partj}).old.pold.enc = sortrows(sc.p3.(thepart{partj}).old.pold.enc,2);
            sc.p3.(thepart{partj}).old.pnew.enc = sortrows(sc.p3.(thepart{partj}).old.pnew.enc,2);
            sc.p3.(thepart{partj}).old.pold.ret = sortrows(sc.p3.(thepart{partj}).old.pold.ret,2);
            sc.p3.(thepart{partj}).old.pnew.ret = sortrows(sc.p3.(thepart{partj}).old.pnew.ret,2);
            
            sc.p3.(thepart{partj}).old.pold.enc(:,2) = [];
            sc.p3.(thepart{partj}).old.pnew.enc(:,2) = [];
            sc.p3.(thepart{partj}).old.pold.ret(:,2) = [];
            sc.p3.(thepart{partj}).old.pnew.ret(:,2) = [];
            
            fileX.p3.(thepart{partj})(fileX.p3.(thepart{partj})(:,2)==cati & fileX.p3.(thepart{partj})(:,3)==1,6) = sc.p3.(thepart{partj}).new;
            fileX.p3.(thepart{partj})(fileX.p3.(thepart{partj})(:,2)==cati & fileX.p3.(thepart{partj})(:,3)==2 & fileX.p3.(thepart{partj})(:,4)==1 & fileX.p3.(thepart{partj})(:,5)==1,6) = sc.p3.(thepart{partj}).old.pnew.enc;
            fileX.p3.(thepart{partj})(fileX.p3.(thepart{partj})(:,2)==cati & fileX.p3.(thepart{partj})(:,3)==2 & fileX.p3.(thepart{partj})(:,4)==1 & fileX.p3.(thepart{partj})(:,5)==2,6) = sc.p3.(thepart{partj}).old.pold.enc;
            fileX.p3.(thepart{partj})(fileX.p3.(thepart{partj})(:,2)==cati & fileX.p3.(thepart{partj})(:,3)==2 & fileX.p3.(thepart{partj})(:,4)==2 & fileX.p3.(thepart{partj})(:,5)==1,6) = sc.p3.(thepart{partj}).old.pnew.ret;
            fileX.p3.(thepart{partj})(fileX.p3.(thepart{partj})(:,2)==cati & fileX.p3.(thepart{partj})(:,3)==2 & fileX.p3.(thepart{partj})(:,4)==2 & fileX.p3.(thepart{partj})(:,5)==2,6) = sc.p3.(thepart{partj}).old.pold.ret;
        end
        clear sc
    end
    
    clearvars -except fileX n thepart relnew thecat thecond time thephase inst2load init phasei parti
    save(fullfile(init.(thephase{phasei}).thepath.results,fileX.fileName),'fileX');
    save(fullfile(init.(thephase{phasei}).thepath.results,[fileX.fileName(1:end-4),'_init.mat']),'init');
end

%% INITIALIZE PSYCHTOOLBOX
init.(thephase{phasei}).screens      = Screen('Screens');
init.(thephase{phasei}).screenNumber = max(init.(thephase{phasei}).screens);%The highest display number is a best guess about where you want the stimulus displayed
if init.(thephase{phasei}).debug
    PsychDebugWindowConfiguration([],0.7)
else HideCursor;
    
    if strcmp(init.(thephase{phasei}).hostname,'triostim1')
        Screen('Preference', 'SkipSyncTests', 1);
        skipsync = input('You are skipping the sync test. Type y if you want to continue.','s');
        if ~strcmp(skipsync,'y')
            error('Experiment aborted');
        end
    end
end

try
    [init.(thephase{phasei}).expWin,init.(thephase{phasei}).rect] = PsychImaging('OpenWindow',init.(thephase{phasei}).screenNumber,[0.5 0.5 0.5]);%open onscreen Window
catch
    [init.(thephase{phasei}).expWin,init.(thephase{phasei}).rect] = PsychImaging('OpenWindow',init.(thephase{phasei}).screenNumber,[0.5 0.5 0.5]);%open onscreen Window
end

Priority(MaxPriority(init.(thephase{phasei}).expWin));

Screen('TextSize', init.(thephase{phasei}).expWin,24);
Screen('TextFont', init.(thephase{phasei}).expWin, 'Helvetica');
init.(thephase{phasei}).refresh = Screen('GetFlipInterval', init.(thephase{phasei}).expWin);
init.(thephase{phasei}).slack   = init.(thephase{phasei}).refresh/2;
[init.(thephase{phasei}).mx, init.(thephase{phasei}).my] = RectCenter(init.(thephase{phasei}).rect);
init.(thephase{phasei}).device = -1;%query all devices and report their merged state

%Calculate stimulus size
init.(thephase{phasei}).imgsizepix = calcstimsize(init,thephase,phasei);

%Load mex files now to not do it in the trial loop
KbCheck(init.(thephase{phasei}).device);
disp('======================');
disp('Press any key to start');
KbWait(init.(thephase{phasei}).device);
GetSecs;

%Fixation cross
FixCr=ones(20,20)*0.5;
FixCr(10:11,:)=1;FixCr(:,10:11)=1;

%% INITIALIZE EYELINK
if phasei == 2 && parti == 2
    
    init.el.recmode = init.(thephase{phasei}).debug;%1 = no EL connected, dummy mode; 0 = EL connected
    init.el.el = EyelinkInitDefaults(init.(thephase{phasei}).expWin);
    
    init.el.el.targetbeep               = 0;  % sound a beep when a target is presented
    init.el.el.feedbackbeep             = 0;
    init.el.el.backgroundcolour         = WhiteIndex(init.(thephase{phasei}).expWin)/2;
    init.el.el.foregroundcolour         = WhiteIndex(init.(thephase{phasei}).expWin);
    init.el.el.msgfontcolour            = WhiteIndex(init.(thephase{phasei}).expWin);
    init.el.el.imgtitlecolour           = WhiteIndex(init.(thephase{phasei}).expWin);
    init.el.el.calibrationtargetcolour  = WhiteIndex(init.(thephase{phasei}).expWin);
    init.el.el.calibrationtargetsize    = 1.5;
    init.el.el.calibrationtargetwidth   = 0.5;
    init.el.el.displayCalResults        = 1;
    init.el.el.eyeimgsize               = 50;
    init.el.el.waitformodereadytime     = 25;%ms
    
    EyelinkUpdateDefaults(init.el.el);
    PsychEyelinkDispatchCallback(init.el.el);
    
    if ~EyelinkInit(init.el.recmode,1);%enable callback = 1 is default; if initialization does not work
        error('Initialization not successful')
    end
    [init.el.v,init.el.vs] = Eyelink('GetTrackerVersion');
    
    Eyelink('Openfile',[fileX.fileName(8:end-3),'edf']);
    Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox CONTON Experiment (Nora Herweg)''');
    Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, init.p2.rect(3)-1, init.p2.rect(4)-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, init.p2.rect(3)-1, init.p2.rect(4)-1);
    % set calibration type.
    Eyelink('command','auto_calibration_messages = YES');
    Eyelink('command', 'calibration_type = HV13');
    Eyelink('command', 'select_parser_configuration = 1');%this the psychophysical setup, choose 0 for cognitive/standard
    %what do we want to record
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('command', 'use_ellipse_fitter = no');
    Eyelink('command', 'pupil_size_diameter = NO');
    
    % set sample rate in camera setup screen
    Eyelink('command', 'sample_rate = %d',1000);
    
    insttexture = Screen('MakeTexture',init.(thephase{phasei}).expWin,uint8(imread(fullfile(init.(thephase{phasei}).thepath.inst,'calibration.png'))));
    Screen('DrawTexture',init.(thephase{phasei}).expWin,insttexture);
    Screen('Flip', init.(thephase{phasei}).expWin);
    Screen('Close')
    KbWait([], 2);
    clear insttexture
    
    EyelinkDoTrackerSetup(init.el.el);
    [~, messageString] = Eyelink('CalMessage');
    Eyelink('Message','%s',messageString);
    WaitSecs(0.05);
    
    [ init.(thephase{phasei}).calibratePupil.sequenceComp,init.(thephase{phasei}).calibratePupil.targetMatX,init.(thephase{phasei}).calibratePupil.targetMatY  ] = calibratePupil(round(init.(thephase{phasei}).imgsizepix),ones(3,4),init.(thephase{phasei}).expWin,2,init.el.el,init.(thephase{phasei}).mx,init.(thephase{phasei}).my,fullfile(init.p2.thepath.inst,'calibration_pupil.png'),fullfile(init.(thephase{phasei}).thepath.results,[fileX.fileName(1:end-3),'png']),init.(thephase{phasei}).device,fullfile(init.p2.thepath.inst,'stim_calibration_pupil_1024triostim1.bmp'));
end

%% START SESSIONS
for numsession = 1:6-((phasei*2)+parti-3)
    disp('Starting session');
    DrawFormattedText(init.(thephase{phasei}).expWin,'Laden...','center','center',[1 1 1]);
    Screen('Flip',init.(thephase{phasei}).expWin);
    cd (init.(thephase{phasei}).thepath.results);
    exp_conton_phase123
    if parti == 2 && init.continuous == 1
        phasei = phasei+1;
    elseif parti == 2 && init.continuous == 0 || phasei == 2
        break
    end
    parti = 2/parti;
end

save(fullfile(init.(thephase{phasei}).thepath.results,fileX.fileName),'fileX');
save(fullfile(init.(thephase{phasei}).thepath.results,[fileX.fileName(1:end-4),'_init.mat']),'init');
RestrictKeysForKbCheck(27);%press escape to leave final screen
KbWait([], 2);
RestrictKeysForKbCheck([]);
ShowCursor;
sca