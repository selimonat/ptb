function [ed,imfolder_target]=CalibrateFace_V1Model(path2stim)
%[ed,imfolder]=CalibrateFaces_V1EuclidianDistance(path2stim)
%
%   Computes a similarity metric using V1 simple cell model used in Yue et
%   al, Vision Research 2012. So basically it is a wrapper around Yue's
%   function to analyze the faces we use. PATH2STIM can optionaly be used
%   to run the analysis on different faces tham the default set, in that
%   case PATH2STIM must be a string representing the path to the folder
%   containing the faces.
%
%   Example usage:
%
%Selim Onat, 19-Mar-2013 15:40:48

%% Get all the stimuli

f           = dir([path2stim '/*.bmp']);

%read and store the images
im = [];
tStim = length(f);
for nf = 1:tStim
    im(:,:,nf) = imread(sprintf('%s%s',path2stim,f(nf).name));
end

% save the output
imfolder_target = sprintf('%sV1responses\\',path2stim);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end

%% run the V1 model
JetsMagnitude = [];
JetsPhase     = [];
GridPosition  = [];
for nf = 1:size(im,3)
    fprintf('Processing face %d\n',nf);
    %(image,simpleORComplex[0 1],GridSize[0 1 2],sigma)
    [v1] = GWTWgrid_Simple(im(:,:,nf),0,2,4.2);
    % average across filters
    v1 = mean(v1,2);
    v1 = imrotate(reshape(v1(:),400,400),-90);
    save(sprintf('%sV1_%02d.mat',imfolder_target,nf),'v1');
    % save also as pic to see 
    imwrite(Scale(v1),sprintf('%s%02d_V1.bmp',imfolder_target,nf),'bmp');
end

%% compute a difference metric
ed = zeros(size(im,3));
r = [];
for nf1 = 1:size(im,3)
    for nf2 = 1:size(im,3)
        if nf2<nf1
            fprintf('Processing face %d-%d\n',nf1,nf2);
            a = load(sprintf('%sV1_%02d.mat',imfolder_target,nf1));
            b = load(sprintf('%sV1_%02d.mat',imfolder_target,nf2));
            %
            ed(nf1,nf2) = norm(a.v1(:)-b.v1(:));
            ed(nf2,nf1) = ed(nf1,nf2);
        end
    end
end

