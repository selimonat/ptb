function [ed]=CalibrateFace_V1Model(path2stim)
%[ed]=CalibrateFaces_V1EuclidianDistance(path2stim)
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

%% Get all the stimuli (by default it loads the stimuli used in the experiment). 

if nargin == 0%default location for the files
    path2folder = ['C:\Users\onat' filesep 'Documents' filesep 'Experiments' filesep 'Stimuli' filesep 'Gradients'];
    folder      = 'Circle11_08Face_Frontal_SkinModerated_Transparent_Normalized';%'Radius_clean_Normalized';
    path2stim   = sprintf('%s%s%s%s',path2folder,filesep,folder,filesep);
    f           = dir([path2stim '*.bmp']);
    f           = [f(1:8)];%discard the shock symbol
else
    path2folder = [];
    folder      = [];    
    f           = dir([path2stim '/*.bmp']);
end
%read and store the images    
im = [];
tStim = length(f);
for nf = 1:tStim
    im(:,:,:,nf) = imresize(imread(sprintf('%s%s',path2stim,f(nf).name)),[128 128],'bilinear','antialiasing',1);
end


%% run the V1 model
JetsMagnitude = [];
JetsPhase     = [];
GridPosition  = [];
for nf = 1:size(im,4)
    for nchannel = 1:3
        fprintf('Processing face %d, channel %d\n',nf,nchannel);
        %(image,simpleORComplex[0 1],GridSize[0 1 2],sigma)
        [JetsMagnitude(:,:,nchannel,nf), JetsPhase(:,:,nchannel,nf), GridPosition(:,:,nchannel,nf)] = GWTWgrid_Simple(im(:,:,nchannel,nf),1,0);
    end
end


%% compute a difference metric
for nchannel = 1:3;
    r = [];
    for nf1 = 1:size(im,4)                
        for nf2 = 1:size(im,4)
            fprintf('Processing face %d-%d, channel %d\n',nf1,nf2,nchannel);
            %uncorrected
            data1 = Vectorize(JetsMagnitude(:,:,nchannel,nf1));
            data2 = Vectorize(JetsMagnitude(:,:,nchannel,nf2));
            %            
            ed(nf1,nf2,nchannel)          = norm(data1(:)-data2(:));
        end
    end
end
