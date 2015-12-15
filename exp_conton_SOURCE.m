
%Contextual Modulation of old/new effects%
%3-Nov-2015, n.herweg@uke.de

%% CLEAN UP
clear all;close all;clc;
PsychDefaultSetup(2);
sca;

%seed random number generator based on the current time
rng('shuffle');

%% DEFINE VARIABLES
%Phase 1: initial encoding
time.p1.pic         = 1;
time.p1.fix         = 1.5;
time.p1.resp        = time.p1.fix+time.p1.pic; 

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
time.p2.fix         = 2;
time.p2.resp        = time.p2.fix+time.p2.pic;

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
time.p3.fix         = 3;%minimum fixation duration
time.p3.resp        = 3+time.p3.pic;%3 sec is maximum fixation duration

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

%specify project path
thepath.project = 'C:\USER\herweg\pilot';

thepath.pics_inn=[thepath.project '\pics\inn_color\mean1275RGB'];
thepath.pics_out=[thepath.project '\pics\out_color\mean1275RGB'];
thepath.results=[thepath.project '\data'];
thepath.inst= [thepath.project '\experiment\instructions'];
thepath.scripts=[thepath.project '\experiment'];
addpath(fullfile(thepath.project,'experiment\functions'));

%% LOAD/CREATE FILEX
%enter subject ID 
subID    = input('Enter subject ID: ','s');
fileName = ['CONTON_' num2str(subID) '.mat'];

%check if fileX already exists and warn, if overwriting is confirmed load
if exist(fullfile(thepath.results,fileName),'file')
    
    resp=input(['The file ' fileName ' already exists. Do you want to overwrite it? [Type ok to overwrite]'], 's');
    
    if ~strcmp(resp,'ok') %abort experiment if overwriting was not confirmed
        disp('experiment aborted')
        return
    end
    
    load(fullfile(thepath.results,fileName)); %Loads the .m-file containing the subject's data.
else
    
    fileX.subID    = subID;
    fileX.fileName = fileName;
    fileX.keycond  = input('Enter number for key mapping (1-4): ','s');
    
    %assign category, condition, targetness and oldnew to trials
    for parti = 1:size(thepart,2)
        fileX.p1.(thepart{parti})(:,2) = repmat([1;2],n.p1.(thepart{parti}).trials/size(thecat,2),1);% 2 category
        fileX.p1.(thepart{parti})(:,3) = [ones(n.p1.(thepart{parti}).pics.targ*n.p1.(thepart{parti}).shows.targ,1);ones(n.p1.(thepart{parti}).pics.new*n.p1.(thepart{parti}).shows.reg,1)*0];%3 targetness 1 = target, 0 = no target
        fileX.p1.(thepart{parti})(:,1) = rand(size(fileX.p1.(thepart{parti}),1),1);
        fileX.p1.(thepart{parti})      = sortrows(fileX.p1.(thepart{parti}),1);
        fileX.p1.(thepart{parti})(:,1) = (1:n.p1.(thepart{parti}).trials);%1 trialnumber
        fileX.p1.(thepart{parti})(fileX.p1.(thepart{parti})(:,3)==0,4) = 1; %all trials that are not targets are encoding trials
        
        fileX.p2.(thepart{parti})(:,1) = (1:n.p2.(thepart{parti}).trials);%1 trialnumber
        
        for blocki = 1:n.p2.(thepart{parti}).blocks %equal number of in/out and old/new per block 
            catrand(:,1) = repmat([1;2],n.p2.(thepart{parti}).tpb/size(thecat,2),1);% 2 category
            catrand(:,2) = repmat([1;2;2;1],(n.p2.(thepart{parti}).tpb/size(thecat,2))/2,1);% 3 oldnew 1 = new; 2 = old
            catrand(:,3) = rand(size(catrand,1),1);
            catrand      = sortrows(catrand,3);
            
            fileX.p2.(thepart{parti})(1+((blocki-1)*n.p2.(thepart{parti}).tpb):n.p2.(thepart{parti}).tpb+((blocki-1)*n.p2.(thepart{parti}).tpb),2:3) = catrand(:,1:2);
            clear catrand
        end
        for runi = 1: n.p2.(thepart{parti}).runs
            condrand      = repmat([1;2],n.p2.(thepart{parti}).bpr/size(thecond,2),1);
            condrand(:,2) = rand(size(condrand,1),1);
            condrand      = sortrows(condrand,2);
            
            fileX.p2.(thepart{parti})(1+((runi-1)*n.p2.(thepart{parti}).tpr):n.p2.(thepart{parti}).tpr+((runi-1)*n.p2.(thepart{parti}).tpr),4) = kron(condrand(:,1),ones(n.p2.(thepart{parti}).tpb,1));%4 encret 1 = enc; 2 = ret
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
         
        for parti = 1:size(thepart,2)
            %adapt sc to the number of times each scene is shown and include old images from previous phases; randomize
            %again
            sc.p1.(thepart{parti}).new      = repmat(sc.p1.(thepart{parti}).new,n.p1.(thepart{parti}).shows.reg,1);
            sc.p1.(thepart{parti}).new(:,2) = rand(size(sc.p1.(thepart{parti}).new,1),1);
            sc.p1.(thepart{parti}).new      = sortrows(sc.p1.(thepart{parti}).new,2);
            sc.p1.(thepart{parti}).new(:,2) = [];
            
            sc.p1.(thepart{parti}).targ     = repmat(sc.p1.(thepart{parti}).targ,n.p1.(thepart{parti}).shows.targ,1);
            sc.p1.(thepart{parti}).targ(:,2)= rand(size(sc.p1.(thepart{parti}).targ,1),1);
            sc.p1.(thepart{parti}).targ     = sortrows(sc.p1.(thepart{parti}).targ,2);
            sc.p1.(thepart{parti}).targ(:,2)= [];
            
            sc.p2.(thepart{parti}).old      = unique(sc.p1.(thepart{parti}).new);
            sc.p2.(thepart{parti}).old(:,2) = rand(size(sc.p2.(thepart{parti}).old,1),1);
            sc.p2.(thepart{parti}).old      = sortrows(sc.p2.(thepart{parti}).old,2);
            sc.p2.(thepart{parti}).old(:,2) = [];
            
            %put new and old scenes in fileX
            fileX.p1.(thepart{parti})(fileX.p1.(thepart{parti})(:,2)==cati & fileX.p1.(thepart{parti})(:,4)==1,6) = sc.p1.(thepart{parti}).new;
            fileX.p1.(thepart{parti})(fileX.p1.(thepart{parti})(:,2)==cati & fileX.p1.(thepart{parti})(:,4)==0,6) = sc.p1.(thepart{parti}).targ;
            
            fileX.p2.(thepart{parti})(fileX.p2.(thepart{parti})(:,2)==cati & fileX.p2.(thepart{parti})(:,3)==1,6) = sc.p2.(thepart{parti}).new;
            fileX.p2.(thepart{parti})(fileX.p2.(thepart{parti})(:,2)==cati & fileX.p2.(thepart{parti})(:,3)==2,6) = sc.p2.(thepart{parti}).old;
            
            %sort old scenes for p3 according to assigned conditions
            sc.p3.(thepart{parti}).old.pold.enc = fileX.p2.(thepart{parti})(fileX.p2.(thepart{parti})(:,2)==cati & fileX.p2.(thepart{parti})(:,3)==2 & fileX.p2.(thepart{parti})(:,4)==1,6);
            sc.p3.(thepart{parti}).old.pnew.enc = fileX.p2.(thepart{parti})(fileX.p2.(thepart{parti})(:,2)==cati & fileX.p2.(thepart{parti})(:,3)==1 & fileX.p2.(thepart{parti})(:,4)==1,6);
            
            sc.p3.(thepart{parti}).old.pold.ret = fileX.p2.(thepart{parti})(fileX.p2.(thepart{parti})(:,2)==cati & fileX.p2.(thepart{parti})(:,3)==2 & fileX.p2.(thepart{parti})(:,4)==2,6);
            sc.p3.(thepart{parti}).old.pnew.ret = fileX.p2.(thepart{parti})(fileX.p2.(thepart{parti})(:,2)==cati & fileX.p2.(thepart{parti})(:,3)==1 & fileX.p2.(thepart{parti})(:,4)==2,6);
 
            sc.p3.(thepart{parti}).old.pold.enc(:,2) = rand(size(sc.p3.(thepart{parti}).old.pold.enc,1),1);
            sc.p3.(thepart{parti}).old.pnew.enc(:,2) = rand(size(sc.p3.(thepart{parti}).old.pnew.enc,1),1);
            sc.p3.(thepart{parti}).old.pold.ret(:,2) = rand(size(sc.p3.(thepart{parti}).old.pold.ret,1),1);
            sc.p3.(thepart{parti}).old.pnew.ret(:,2) = rand(size(sc.p3.(thepart{parti}).old.pnew.ret,1),1);
            
            sc.p3.(thepart{parti}).old.pold.enc = sortrows(sc.p3.(thepart{parti}).old.pold.enc,2);
            sc.p3.(thepart{parti}).old.pnew.enc = sortrows(sc.p3.(thepart{parti}).old.pnew.enc,2);
            sc.p3.(thepart{parti}).old.pold.ret = sortrows(sc.p3.(thepart{parti}).old.pold.ret,2);
            sc.p3.(thepart{parti}).old.pnew.ret = sortrows(sc.p3.(thepart{parti}).old.pnew.ret,2);
            
            sc.p3.(thepart{parti}).old.pold.enc(:,2) = [];
            sc.p3.(thepart{parti}).old.pnew.enc(:,2) = [];
            sc.p3.(thepart{parti}).old.pold.ret(:,2) = [];
            sc.p3.(thepart{parti}).old.pnew.ret(:,2) = []; 

            fileX.p3.(thepart{parti})(fileX.p3.(thepart{parti})(:,2)==cati & fileX.p3.(thepart{parti})(:,3)==1,6) = sc.p3.(thepart{parti}).new;
            fileX.p3.(thepart{parti})(fileX.p3.(thepart{parti})(:,2)==cati & fileX.p3.(thepart{parti})(:,3)==2 & fileX.p3.(thepart{parti})(:,4)==1 & fileX.p3.(thepart{parti})(:,5)==1,6) = sc.p3.(thepart{parti}).old.pnew.enc;
            fileX.p3.(thepart{parti})(fileX.p3.(thepart{parti})(:,2)==cati & fileX.p3.(thepart{parti})(:,3)==2 & fileX.p3.(thepart{parti})(:,4)==1 & fileX.p3.(thepart{parti})(:,5)==2,6) = sc.p3.(thepart{parti}).old.pold.enc;
            fileX.p3.(thepart{parti})(fileX.p3.(thepart{parti})(:,2)==cati & fileX.p3.(thepart{parti})(:,3)==2 & fileX.p3.(thepart{parti})(:,4)==2 & fileX.p3.(thepart{parti})(:,5)==1,6) = sc.p3.(thepart{parti}).old.pnew.ret;
            fileX.p3.(thepart{parti})(fileX.p3.(thepart{parti})(:,2)==cati & fileX.p3.(thepart{parti})(:,3)==2 & fileX.p3.(thepart{parti})(:,4)==2 & fileX.p3.(thepart{parti})(:,5)==2,6) = sc.p3.(thepart{parti}).old.pold.ret;
        end
        clear sc
    end
    
    clearvars -except fileX key n thepart thepath relnew thecat thecond time thephase inst2load
    save(fullfile(thepath.results,fileX.fileName),'fileX');
end

%Enter session number
phasei  = input('Enter experimental phase (1, 2, or 3): ');
parti = input('Enter subpart (1 for training, 2 for testing): ');

%Counterbalance keys
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

%% INITIALIZE PSYCHTOOLBOX
% Perform standard setup
init.screens      = Screen('Screens');
init.screenNumber = max(init.screens);%The highest display number is a best guess about where you want the stimulus displayed
KbCheck;
%PsychDebugWindowConfiguration([],0.7)%transparent window, comment for testing!
try
    [init.expWin,init.rect] = PsychImaging('OpenWindow',init.screenNumber,[0.5 0.5 0.5]);%open onscreen Window
catch
    [init.expWin,init.rect] = PsychImaging('OpenWindow',init.screenNumber,[0.5 0.5 0.5]);%open onscreen Window
end
Screen('TextSize', init.expWin,24);
Screen('TextFont', init.expWin, 'Helvetica');
init.refresh = Screen('GetFlipInterval', init.expWin);
init.slack   = init.refresh/2;
[init.mx, init.my] = RectCenter(init.rect);
HideCursor;%get rid of the mouse cursor, uncomment for testing!

%Fixation cross
FixCr=ones(20,20)*0.5;
FixCr(10:11,:)=1;FixCr(:,10:11)=1;

%% START SESSIONS
for numsession=1:6-((phasei*2)+parti-3)
    DrawFormattedText(init.expWin,'Laden...','center','center',[1 1 1]);
    Screen('Flip',init.expWin);
    cd (thepath.scripts);
    phase123
    if parti == 2
        phasei = phasei+1;
    end
    parti = 2/parti;
end

save(fullfile(thepath.results,fileX.fileName),'fileX');
RestrictKeysForKbCheck(27);%press escape to leave final screen
KbWait([], 2);
RestrictKeysForKbCheck([]);
ShowCursor;
sca