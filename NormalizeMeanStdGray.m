function [save_path]=NormalizeMeanStdGray(Folder,group)
%this function normalizes the mean luminance and standard deviation of RGB
%channells independently, it thereofre equalized the color. The input to
%this script must be the .png version of the faces with transparent
%background. The reason is that, the background should not contribute to
%the computation of the RGB ML and LC values. In order to run the script
%first go to the Folder where different stimuli are located.
%
% Group defines group identity for separate mean/std normalization.
%
%Folder = './Circle12_08Face_Frontal_SkinModerated_Transparent/';
% Folder = 'C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\selim first\36\png\'


global imfolder%original folder of RGB images

%% save path
save_path = sprintf('%s%s%s%s',fileparts(Folder),filesep,'Normalized',filesep);
if exist(save_path) == 0
    mkdir(save_path);
else
    fprintf('Deleting the already existing folder before creating anew.\n')
    delete([save_path '*'])
    mkdir(save_path);
end
%% get image filenames
f       = dir([Folder '*.bmp']);
tstim   = length(f);
sprintf('%d files found\n',tstim);
if tstim == 0
    fprintf('%s: No file found here...\n',mfilename)
    return;
end
%% if group is empty then all are one single group
if isempty(group) 
    group = ones(1,tstim);
end
%% read all the images and compute the mean, std: this is necessary to get the global mean.
for i = 1:tstim
    sprintf('File %d...\n',i);
    [im]        = imread([Folder f(i).name]);
    %get the face index from the filename
    face_index  = regexp(f(i).name,'[0-9][0-9]','match');
    face_index  = face_index{1};
    face_index  = str2num(face_index);
    %    
    im    = double(im);
    %find the background from the original RGB images
    imori = imread([imfolder f(i).name]);
    b     = ~magicwand(imori,1,1,0);
    for nchannel = 1:size(im,3)
        dummy     = im(:,:,nchannel);        
        %take Mean and Std of the image
        imm(face_index,nchannel) = mean(dummy(b(:)));
        ims(face_index,nchannel) = std(dummy(b(:)));
    end
end
%% save the values as a bar plot
figure;
subplot(2,2,1)
bar(imm(~isnan(imm)));
title('before_mean','interpreter','none');
subplot(2,2,2)
bar(ims(~isnan(ims)));
title('before_std','interpreter','none');

%% run a second loop with the global information
for g = unique(group)
    ig = (group == g);
    for filename = {f(ig).name}
        %% read
        [image]     = imread([Folder filename{1}]);
        %get the face index from the filename
        face_index  = regexp(filename{1},'[0-9][0-9]','match');
        face_index  = face_index{1};
        face_index  = str2num(face_index);
        %
        image       = double(image);
        %find the background
        imori       = imread([imfolder filename{1}]);
        b           = ~magicwand(imori,1,1,0);
        %%
        %1 subtract its own mean
        %2 divide by its own std
        %3 multiply by the group std
        %4 add the group mean
        im = [];
        for nd = 1:size(image,3)
            dummy     = image(:,:,nd);
            dummy(b)  = ((dummy(b)-imm(face_index,nd))/ims(face_index,nd))*mean(ims(ig,nd))+mean(imm(ig,nd));
            % Background is the global mean across groups
            dummy(~b) = mean(imm(ig,nd));
            im        = cat(3,im,dummy);
            % control statistics, these should be perfectly constant
            imm2(face_index,nd) = mean(dummy(b(:)));
            ims2(face_index,nd) = std(dummy(b(:)));
        end     
        %%
        imwrite(uint8(im), [ save_path filename{1}],'bmp');
        
    end
end
%%
subplot(2,2,3)
bar(imm2(~isnan(imm2)));
title('after_mean','interpreter','none');
subplot(2,2,4)
bar(ims2(~isnan(ims2)));
title('after_std','interpreter','none');
SaveFigure(sprintf('%s/M_S.png',save_path));