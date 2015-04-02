function [result]=Similarity(repetition);

path2experiment = 'C:\Users\onat\Desktop\CalibrationTests\Experiments\SimilarityExperiment\';
path2stim = 'C:\Users\onat\Desktop\CalibrationTests\Stimuli\Gradients\Circle07_Frontal_SkinModerated\';

tSub = length(dir([path2experiment 'data\*.mat']));
result.name = input('Name: \n','s');
filename = sprintf([regexprep(path2experiment,'\\','\\\') '\\data\\subject_%02d_%s.mat'],tSub+1, result.name);
result.filename = filename;

CONFIG_DISPLAY( 1, 2, [0.47 0.47 0.47], [1 1 1], 'Arial', 40, 20,0 );
CONFIG_KEYBOARD(1, 5,'exclusive' )
 
start_cogent;
files  = dir([path2stim '*.bmp']);
tfiles = length(files);
display([mat2str(tfiles) ' found in the destination.'])
spic   = 400;

%randomization
Pairs  = find(tril(ones(tfiles)));
tPairs = length(Pairs);
%replicate as required by REPETITION
ri = [];%random indices
for nRep = 1:repetition;
    ri=[ri randperm(tPairs)];
end
Pairs  = Pairs(ri);


%add 10 familiarization pairs at the beginning
fam = reshape(randperm(tfiles),[3 tfiles/3]);
fam = [[fam(1,:) ; fam(1,:)] [fam(2,:) ; fam(2,:)+6] [fam(1,:) ; fam(1,:)+3]];
fam = mod(fam-1,tfiles)+1;
fam = sub2ind([tfiles tfiles],fam(1,:),fam(2,:));
fam = fam(randperm(12));
Pairs = [fam';Pairs];

%Save information to the output variable
%initialize vector R and T to save ratings
result.stimulus = path2stim;
result.r  = zeros(1,tPairs);
result.t  = result.r;
counter   = 0;

for np = Pairs'
    counter = counter + 1;
    [y x]=ind2sub([tfiles,tfiles],np);
    clearkeys
    loadpict([path2stim files(y).name], 1,-spic/2,0,400,400);
    loadpict([path2stim files(x).name], 1,spic/2,0,400,400);
    %drawpict(1)
    %wait(2000)
    %clearpict(1)
    preparestring('1     .     .     4     .     .     7',1,0,-200)
    preparestring('very different                 identical',1,0,-240)
    drawpict(1)
    [key,t,n] = waitkeydown(inf,[28:34]);
    clearpict(1);
    drawpict(1);
    wait(500);
    %
    result.r(counter) = key-27;
    result.t(counter) = t;
    result.stim(:,counter) = [y;x];
    save(filename,'result')
end

stop_cogent;