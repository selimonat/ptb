function [imfolder_target]=CalibrateFace_V1Model(path2stim)
%[imfolder]=CalibrateFaces_V1EuclidianDistance(path2stim)
%
%   Computes V1 responses using V1 complex cell model used in Yue et
%   al, Vision Research 2012. For RGB images, it will run it on all the
%   channels. V1 responses will be written as BMP images as well as
%   .MAT files.
%
%
%Selim Onat, 19-Mar-2013 15:40:48

%% Get all the stimuli

f           = dir([path2stim '*.bmp']);

%% read and store the images
im = [];
tStim = length(f);
for nf = 1:tStim
    im(:,:,:,nf) = imread(sprintf('%s%s',path2stim,f(nf).name));
end

%% save the output
imfolder_target = sprintf('%sV1responses%s',path2stim,filesep);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end

%% run the V1 model
JetsMagnitude = [];
JetsPhase     = [];
GridPosition  = [];
for nf = 1:size(im,4)
    fprintf('Processing face %d\n',nf);
    for nd = 1:size(im,3)
        %(image,simpleORComplex[0 1],GridSize[0 1 2],sigma)
        [dummy]     = GWTWgrid_Simple(im(:,:,nd,nf),0,2);
        % average across filters
        dummy       = mean(dummy,2);
        v1r(:,:,nd) = imrotate(reshape(dummy(:),size(im,1),size(im,2)),-90);        
    end
    if size(im,3) == 3        
        %merge
        v1  = v1r(:,:,1)*.3 + v1r(:,:,2)*.59 + v1r(:,:,3)*.11;        
    end
    save(sprintf('%sV1_%02d.mat',imfolder_target,nf),'v1');
    %
    % save also as pic to see    
    imwrite(Scale(v1r),sprintf('%s%02d_V1.bmp',imfolder_target,nf),'bmp');
end
