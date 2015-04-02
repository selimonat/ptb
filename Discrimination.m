function [p]=Discrimination(name,repetition)

p        = [];%information to be saved to the disk
st       = [];%stimulus properties
stim     = [];%will store the stimulus
stimPink = [];%will store the pink noise images
SetParams;
%
ConfigCogent;
CreateSprites(st.fam_path2stim, st.fam_files , (1:st.fam_tStim) +100 );
CreateSprites(st.path2stim, st.files , 1:st.tStim );

clearpict(20);
drawpict(20);
%
%familiarization runs%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 cgtext('Bewertung der Gesichterpaare ("identisch" und "verschieden") mit STRG-links und STRG-rechts',0,0);
 cgflip(st.bg);
 waitkeydown(inf);
 cgtext('Zuerst einige Probedurchgänge... Bitte Taste drücken um anzufangen',0,0);
 cgflip(st.bg);
 waitkeydown(inf);
 for np = sub2ind([st.tStim st.tStim],[1 2 3 4 5 3], [1 6 3 7 5 8])%        
     [y x]   = ind2sub([st.tStim,st.tStim],np);
     y = y + 100;
     x = x + 100;
     clearkeys;
     %show stimulus
     Trial;        
 end
%
%main experiment.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cgtext('Probedurchgänge abgeschlossen... Nun beginnt das echte Experiment... Bitte beliebige Taste drücken',0,0);

%%% cgtext('Info zum Experiment, CTRL
cgflip(st.bg);
waitkeydown(inf);
%
p.results.count_mat = zeros(st.tStim);
p.results.response  = zeros(st.tStim);
counter             = 0;
tTrial              = length(p.presentation.order');
for np = p.presentation.order'
    counter = counter + 1;
    [y x]   = ind2sub([st.tStim,st.tStim],np);
    clearkeys;
    %show stimulus
    Trial;
    if key == 60
        p.results.response(y,x)    = p.results.response(y,x) + 1;
    elseif key == 91
        p.results.response(y,x)    = p.results.response(y,x) + 0;
    end
    p.results.time(counter)        = t;
    p.results.pair(:,counter)      = [y;x];
    p.results.count_mat(y,x)       = p.results.count_mat(y,x) + 1;
    save(savefilename,'p')
    
    if counter == round(tTrial/2)        
        cgtext('Pause, Taste drücken um fortzufahren',0,0);
        cgflip(st.bg);
        [key,t,n] = waitkeydown( inf );
    end
    
end
stop_cogent;
%
    function Trial
        GetPinkNoise;
        %add the fixation cross
        %Show the pink noise
        cgdrawsprite(17,0,0);
        cgflip(st.bg);
        wait(p.duration.pn_prestim*(rand(1)+1));%duration changes between [pn_prestim 2*pn_prestim];
        %Show the face 1
        cgdrawsprite(x,0,0);
        cgflip(st.bg);
        wait(p.duration.stim);
        %Show the pink noise
        cgdrawsprite(18,0,0);
        cgflip(st.bg);
        wait(p.duration.isi*(rand(1)+1));
        %Show the face 2
        cgdrawsprite(y,0,0);
        cgflip(st.bg);
        wait(p.duration.stim);
        %Show text
        cgtext('Identisch                     Verschieden',0,0);
        cgflip(st.bg);
        %91: right control (different)
        %60: left control (same)
        [key,t,n] = waitkeydown( inf , [60 91] );
        
    end
    function GetPinkNoise
        res  = st.resolution(1);
        tPix = st.resolution(1).*st.resolution(2);
        for n = 1:3
            stimPink(:,:,:,n) = repmat(maskit(Image2PinkNoise(stim(:,:,y)),st.win,st.bg(1)),[1 1 3]);
            cgloadarray(16+n,res,res,reshape(double(imrotate(stimPink(:,:,:,n),90)),[tPix 3]),res,res);
            cgsetsprite(16+n);
        end
        cgsetsprite(0);
    end
    function im = maskit(im,win,bg)
        m  = mean2(im);
        im = (im - repmat(m,size(im))).*win + bg;
    end
    function CreateSprites(root, files, sprite_index)
        %cgopen(1,32,0,0);
        res  = st.resolution(1);
        tPix = st.resolution(1).*st.resolution(2);
        %
        for nStim = 1:size(files)
            filename        = [files(nStim).name];
            cgmakesprite(sprite_index(nStim),res,res,st.bg);
            im              = imread([root filename]);
            stim(:,:,sprite_index(nStim)) = rgb2gray(double(imread([st.path2stim files(nStim).name]))./255);%save it for pink noise generation
            cgloadarray(sprite_index(nStim),res,res,reshape(double(imrotate(im,90))./255,[tPix 3]),res,res);
        end
        cgflip([st.bg]);
        cgflip([st.bg]);
        %create the window
        st.win        = tukeywin(st.resolution(1),st.tukey)*tukeywin(st.resolution(2),st.tukey)';
        
    end
    function SetParams
        %st: for stimulus information to be passed to other functions
        %p: important information to be saved at the end of the experiment.
        path2experiment        = 'C:\Users\onat\Documents\Experiments\DiscriminationExperiment\';
        stimfolder             = 'Circle11_08Face_Frontal_SkinModerated_Transparent_Normalized';
        st.path2stim           = ['C:\Users\onat\Documents\Experiments\Stimuli\Gradients\' stimfolder '\'];
        %get paths of stim files
        st.files               = dir([st.path2stim '*.bmp']);
        st.tStim               = length(st.files);
        %
        %name of the file to be written.
        savefilename               = [path2experiment '\data\' datestr(now,30) '_' stimfolder '_' name];
        st.tukey               = 0.1;
        dummy_im               = imread([st.path2stim st.files(1).name]);
        st.resolution          = [size(dummy_im,1) size(dummy_im,2)];
        %durations in millisecond
        p.duration.pn_prestim  = 1500;
        p.duration.isi         = 1000;
        p.duration.stim        = 750;
        %
        st.bg                  = repmat(double(dummy_im(1))./255,1,3);
        %Presentation randomization
        p.presentation.repetition = repetition;
        Pairs                  = find(tril(ones(st.tStim)));%all possible pairs
        tPairs                 = length(Pairs);%total number of pairs
        %
        %replicate as required by REPETITION
        ri                     = [];%random indices.
        for nRep = 1:p.presentation.repetition;
            %shuffle pairs, that is stimulus order.
            ri   = [ri randperm(tPairs)];
        end
        p.presentation.order  = Pairs(ri);
        %add the familiarization trials
        %load the familiarization faces.
        %
        testfolder       = 'Circle09_FaceFrontal_4IDnogender';
        st.fam_path2stim = ['C:\Users\onat\Documents\Experiments\Stimuli\Gradients\' testfolder '\'];
        
        st.fam_files   = dir([st.fam_path2stim '*.bmp']);        
        st.fam_tStim   = size(st.fam_files,1);
        
        %make 3 additional sprites for the pink noise images
        cgmakesprite(17:20,st.resolution(1),st.resolution(1),st.bg);
        cgsetsprite(0);
    end
    function ConfigCogent
        %
        fs  = 1;
        res = 0;
        config_display( fs, res, st.bg, [1 1 1], 'Arial', 40, 20,0 );
        config_keyboard(1, 5,'exclusive' );
        start_cogent;
        cgfont('Arial',20)
        cgpencol([1 1 1])
        cgflip(st.bg);
        cgflip(st.bg);
    end
end