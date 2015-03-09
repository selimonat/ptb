function [save_path]=NormalizeMeanStdGray(Folder)
%this function normalizes the mean luminance and standard deviation of RGB
%channells independently, it thereofre equalized the color. The input to
%this script must be the .png version of the faces with transparent
%background. The reason is that, the background should not contribute to
%the computation of the RGB ML and LC values. In order to run the script
%first go to the Folder where different stimuli are located.

%Folder = './Circle12_08Face_Frontal_SkinModerated_Transparent/';
% Folder = 'C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\selim first\36\png\'
save_path = sprintf('%s%s%s%s',fileparts(Folder),filesep,'Normalized',filesep);
if exist(save_path) == 0
    mkdir(save_path);
else
    fprintf('Deleting the already existing folder before creating anew.\n')
    delete([save_path '*'])
    mkdir(save_path);
end
f       = dir([Folder '*.bmp']);
tstim   = length(f);
sprintf('%d files found\n',tstim);
if tstim == 0
    fprintf('%s: No file found here...\n',mfilename)
    return;
end
%read all the images and compute the mean, std
for i = 1:tstim
    sprintf('File %d...\n',i);
    [im] = imread([Folder f(i).name]);
    %
    im    = double(im);
    %find the background
    b = ~magicwand(im(:,:,[1 1 1]),1,1,0);
    % nan the image background
    im(~b) = NaN;
    %take Mean and Std of the image
    imm(i) = nanmean(im(:));
    ims(i) = nanstd(im(:));
    
end

%take the global mean, std across all images
mimm  = mean(imm);
mims  = mean(ims);

for i = 1:tstim
    [im] = imread([Folder f(i).name]);
    %
    im    = double(im);
    %find the background
    b = ~magicwand(im(:,:,[1 1 1]),1,1,0);
    im(b)=(im(b)-imm(i))./ims(i)*mims+mimm;
    % Background is the global mean
    im(~b) = mimm;
    imwrite(uint8(im), [ save_path f(i).name],'bmp');
end

