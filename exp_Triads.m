function S=Triads(subject,repetition,stim_duration,familiarization)
%S=Triads(subject,repetition,stim_duration,familiarization)
%
%stim_duration is in milliseconds. 

clear mex global functions
cgshut;
StartTime   = datestr(now,30);
%
%set the stimulus location
[dummy p.hostname] = system('hostname');
p.hostname         = cell2mat(regexp(p.hostname,'[A-z]','match'));
if strcmp(p.hostname,'isndeab')%laptop
    location       = ['C:\Users\onat\Documents\Experiments\'];
else%mainly behavioral lab
    location       = ['C:\USER\onat\Experiments\'];
end
stimfolder         = 'Circle11_08Face_Frontal_SkinModerated_Transparent_Normalized';
path2stim          = [location 'Stimuli\Gradients\' stimfolder '\'];
path2experiment    = [location 'Triads\'];
files              = FileMatrix([path2stim '*.bmp']);
TotalStim          = size(files,1);
%set the background gray according to the background of the stimuli
for i = 1:TotalStim;im = imread(files(i,:));bg(i)=im(1,1,1);end
if sum(diff(bg))==0;bg = double([bg(1) bg(1) bg(1)])./255;else;keyboard;end;
%
win        = tukeywin(400,.1)*tukeywin(400,.1)';
EdgeSize    = 500;
h           = sqrt(3)*EdgeSize./2;
pos_stim    = [0 h/2 ; -EdgeSize/2 -h/2 ; EdgeSize/2 -h/2];%(x,y): up, left, right
pos_marker  = [-h/4 0 -30; 0 -h/2 90; h/4 0 30];%(x,y): upper-left, bottom, upper-right
%
ConfigCogent;
%
CreateStimSprites(files,1:TotalStim,0);%load stimuli
CreateStimSprites(files,(1:TotalStim)+200,1);%load also the pink noise images that will be used as mask
CreateMarkerSprites;
%load the familiarization faces.
if familiarization
    testfolder        = 'Circle09_FaceFrontal_4IDnogender';
    path2test         = [location 'Stimuli\Gradients\' testfolder '\'];
    files             = FileMatrix([path2test '*.bmp']);
    TotalStim         = size(files,1);
    CreateStimSprites(files,(1:TotalStim)+10,0);
    CreateStimSprites(files,(1:TotalStim)+210,1);
end
%
t           = [];
size_stim   = [];
size_sprite = [];
keyout      = 0;
S           = zeros(TotalStim);
index       = [1 2; 2 3; 1 3];
%
green       = 60;
red         = 91;
space       = 71;
%create triplets;
T = [];
for repetition = 1:repetition;
    dummy           = PAL_MLDS_GenerateStimList(3, TotalStim, TotalStim, 1);
    %first randomization
    T           = [T ; PositionBalancer(dummy)];
end
tTriplet    = size(T,1);

%second randomization...
T           = T(Shuffle(1:tTriplet,tTriplet),:);
%create 5 dummy triplets, these will be used for familiarization.
%save the sequence for later usage
Response.Sequence = T;
%
if familiarization
    nFamiliarization = 5;
    T                = [T(1:nFamiliarization ,:)+10 ; T];%+10 ensures that we use another set of faces.
else
    nFamiliarization = 0;
end
%mainloop;
Timer = 1;
tTriplet    = size(T,1);%update the triplet number
for nTriplet = 1:tTriplet
    
    t = T(nTriplet,:);%current triplet
    count([red green]) = Shuffle(1:3,2);
    ShowStims(stim_duration);
    MoveMarker;
    %only record the results if passed the familiarization step.
    if nTriplet > nFamiliarization
        %record the start time with the presentation of the first stim.
        if Timer
        start_time = time;
        Timer = 0;
        end
        %increment the selected pairs
        S(sub2ind([TotalStim TotalStim],t(index(count(green),[1 2])),t(index(count(green),[2 1])))) = ...
            S(sub2ind([TotalStim TotalStim],t(index(count(green),[1 2])),t(index(count(green),[2 1])))) + 2;
        
        red_c = setdiff(1:3,[count(green) count(red)]);%switch to the unselected one
        
        S(sub2ind([TotalStim TotalStim],t(index(count(red),[1 2])),t(index(count(red),[2 1])))) = ...
            S(sub2ind([TotalStim TotalStim],t(index(count(red),[1 2])),t(index(count(red),[2 1])))) + 1;
        %save the response to be on the safe side
        Response.Green(nTriplet-nFamiliarization,:) = t(index(count(green),[1 2]));
        Response.Red(nTriplet-nFamiliarization,:)   = t(index(count(red),[1 2]));        
    %
    end
    
    cgflip(bg);
end
cgtext('Danke...',0,0);
cgflip(bg);

duration= round(time-start_time)./1000./60;%time since subject first pressed a button.
save([path2experiment '\data\' StartTime '_' stimfolder '_' subject],'S','duration','Response');
wait(5000);
stop_cogent;
cgshut;
    function MoveMarker   
        ShowMask;
        cgrotatesprite(101, pos_marker(count(red)  ,1)  , pos_marker(count(red),2), pos_marker(count(red),3));
        cgrotatesprite(100, pos_marker(count(green),1)  , pos_marker(count(green),2), pos_marker(count(green),3));
        cgflip(bg);
        [keyout] = waitkeydown(Inf,[green red space]);
        if keyout ~= space%stay inside as long as space is not pressed
            Accumulate;
        end
        
        function Accumulate
            count(keyout)  = count(keyout) + 1;
            count(keyout)  = mod(count(keyout)-1,3)+1;
            if count(green) == count(red)
                Accumulate;
            else
                MoveMarker;
            end
        end
    end
    function ShowStims(stim_duration)
        for i = 1:3
            cgdrawsprite(t(i), pos_stim(i,1), pos_stim(i,2) );
        end
        cgtext([ mat2str(nTriplet) '\' mat2str(tTriplet)],0,0);
        cgflip(bg);
        Wait(stim_duration);       
    end
    function ShowMask
        for i = 1:3
            cgdrawsprite(t(i)+200,     pos_stim(i,1), pos_stim(i,2) );
        end
        cgtext([ mat2str(nTriplet) '\' mat2str(tTriplet)],0,0);
%         cgflip(bg);
    end
    function CreateStimSprites(files,sprite_index,shuffle)
        
        %loads all the stims to video memory, Sprites 1 to N are used,
        %where N is the total number of stims,
        tStim = size(files,1);
        if length(sprite_index) ~= tStim
            keyboard
        end
        
        for nStim = 1:tStim
            filename    = files(nStim,:);
            im          = imread(filename);
            if shuffle
                im = repmat(maskit(Image2PinkNoise(rgb2gray(im)),win,bg(1)*255),[1 1 3]);
                im = uint8(im);
            end
            size_stim   = [size(im,1) size(im,2)];
            size_sprite = size_stim;
            cgmakesprite(sprite_index(nStim),size_sprite(2),size_sprite(2),bg);
            %cgloadarray(nStim,size_stim(2),size_stim(1),reshape(double(imrotate(im,90))./255,[size_stim(1)*size_stim(2) 3]),size_sprite(1),size_sprite(1));
            cgloadarray(sprite_index(nStim),size_stim(2),size_stim(1),reshape(double(imrotate(im))./255,[size_stim(1)*size_stim(2) 3]),size_sprite(1),size_sprite(1));
        end
        function [im]=imrotate(im)
            %I define a custom made imrotate because stim computer doesnt have
            %one.
            im = cat(3,rot90(im(:,:,1)),rot90(im(:,:,2)),rot90(im(:,:,3)));
        end
        function im = maskit(im,win,bg)
        m  = mean2(im);
        im = (im - repmat(m,size(im))).*win + bg;
    end
    end
    function CreateMarkerSprites
        %
        cgmakesprite(100,200,200,[0 0 1]);
        cgpencol([0 1 0]);
        cgsetsprite(100);
        cgpolygon([-.5 0 .5].*100,[0 1 0].*-100);
        cgpolygon([-.5 0 .5].*100,[0 1 0].*100);
        cgtrncol(100, 'b');
        %
        cgmakesprite(101,200,200,[0 0 1]);
        cgpencol([1 0 0]);
        cgsetsprite(101);
        cgpolygon([-.5 0 .5].*100,[1 0 1].*-100);
        cgpolygon([-.5 0 .5].*100,[1 0 1].*100);
        cgtrncol(101, 'b');
        %
        cgsetsprite(0);
    end
    function FM = FileMatrix(path)
        %Takes a path with file extension associated to regexp (e.g.
        %C:\blabl\bla\*.bmp) returns the file matrix
        dummy = dir(path);
        FM    = [repmat([fileparts(path) filesep],length(dummy),1) vertcat(dummy(:).name)];
    end
    function ConfigCogent
        %
        fs  = 1;
        res = 0;
        config_display( fs, res, bg);
        config_keyboard;
        start_cogent;
        cgfont('Arial',20)
        cgpencol([1 1 1])
        cgflip(bg);
        cgflip(bg);
    end
    function shuffled = Shuffle(vector,N)
        %takes first N from the SHUFFLED before outputting. This function
        %could be used as a replacement for randsample.
        if nargin < 2;N = length(vector);end
        [dummy, idx]    = sort(rand([1 length(vector)]));
        shuffled        = vector(idx(1:N));
        shuffled        = shuffled(:);
    end
    function [Tnew] = PositionBalancer(T)
        %Balances stimulus and locations so that each stimulus is presented
        %equally likely at all locations.
        %
        %number of different stimuli
        TotalStim = length(unique(T));
        %number of possible pairs (not respecting position);
        tPairs    = (TotalStim-1)*(TotalStim-2)./2;
        %number of times a given stimuli appears at a given location
        tPerPos   = tPairs./3;
        if tPerPos ~= round(tPerPos)
            display('The required balancing is not possible with the current parameters');
            return
        end
        %matrix to hold the position information organized as Stimulus x Location.
        %As long as entries are <1 a given stimulus can be placed at that position.
        M         = zeros(TotalStim,3);
        factor    = 1./tPerPos;
        for s = 1:size(T,1)
            %get the current stimulus index;
            y      = T(s,:);
            ok     = 1;
            %indices of positions.
            x      = [1 2 3];
            while ok
                %if it is possible to place the stimuli at locations determined by
                %X then do it.
                %0.99 yapmamizin nedeni bazen factor * tPerPos bire esit gelmiyor
                %roundoff errorleri yuzunden
                if sum(diag(M(y,x)) > (1-factor*0.5)) == 0
                    %increment positions by factor
                    M(y,x) = M(y,x) + diag(repmat(factor,1,3));
                    ok     = 0;
                else%otherwise reshuffle x and try until it works.
                    x      = Shuffle(x);
                end
            end
            %store the new balanced T
            Tnew(s,x) = T(s,1:3);
        end
    end
    function [StimList] = PAL_MLDS_GenerateStimList(ptq, NumLevels, MaxDiff, NumRep)
        %
        %PAL_MLDS_GenerateStimList   Generate stimulus sets of pairs, triads or
        %   quadruples for use in scaling experiment.
        %
        %   syntax: StimList = PAL_MLDS_GenerateStimList(ptq, NumLevels, MaxDiff,
        %        NumRep)
        %
        %   'ptq' should be either 2, 3, or 4 depending on whether one wishes to
        %       generate pairs, triads or quadruples respectively.
        %
        %   'NumLevels' is the number of stimulus levels one wishes to utilize in
        %       experiment.
        %
        %   'MaxDiff' precludes stimulus combinations that are 'too far apart'.
        %       Specifically, if 'ptq' is set to 2, all stimulus pairs i-j (i < j)
        %       for which (j - i) has a value not exceeding 'MaxDiff' will be
        %       included in stimulus set. If 'ptq' is set to 3, all triads i-j-k
        %       (i < j < k) for which |(k - j) - (j - i)| has a value not exceeding
        %       'MaxDiff' will be included in stimulus set. If 'ptq' is set to 4,
        %       all quadruples i-j-k-l (i < j < k < l) for which
        %       |(l - k) - (j - i)| has a value not exceeding 'MaxDiff' will be
        %       included in stimulus set.
        %
        %    'NumRep' sets the number of times each possible pair/triad/quadruple
        %       will be included in the stimulus set.
        %
        %   Example:
        %
        %       StimList = PAL_MLDS_GenerateStimList(2, 4, 1, 2)
        %
        %       returns:
        %
        %       StimList =
        %
        %        1     2
        %        2     3
        %        3     4
        %        1     2
        %        2     3
        %        3     4
        %
        %   PAL_randomizeArray may be used to obtain a randomized stimulus list,
        %   e.g.:
        %
        %   StimList = PAL_randomizeArray(PAL_MLDS_GenerateStimList(2, 4, 1, 2))
        %
        %   will return the same list as above but now in a random order.
        %
        %Introduced: Palamedes version 1.0.0 (NP)
        
                
        count = 0;
        
        if ptq == 2
            for i = 1:NumLevels-1
                for j = i+1:min(i+MaxDiff,NumLevels)
                    count = count+1;
                    StimList(count,:) = [i j];
                end
            end
        end
        if ptq == 3
            for i = 1:NumLevels-2
                for j = i+1:NumLevels-1
                    for k = j+1:NumLevels
                        count = count+1;
                        StimList(count,:) = [i j k];
                    end
                end
            end
            StimList = StimList(abs(StimList(:,3)-2*StimList(:,2)+StimList(:,1))<=MaxDiff,:);
        end
        if ptq == 4
            for i = 1:NumLevels-3
                for j = i+1:NumLevels-2
                    for k = j+1:NumLevels-1
                        for l = k+1:NumLevels
                            count = count+1;
                            StimList(count,:) = [i j k l];
                        end
                    end
                end
            end
            StimList = StimList(abs(StimList(:,4)-StimList(:,3)-StimList(:,2)+StimList(:,1))<=MaxDiff,:);
        end
        StimList = repmat(StimList,[NumRep 1]);
    end
end
