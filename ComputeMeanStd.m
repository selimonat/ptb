function [m,s]=ComputeMeanStd(Folder)
%[m,s]=ComputeMeanStd(f)
%
% Returns the mean and std of all images.

global imfolder

f       = dir([Folder '*.bmp']);
tstim   = length(f);
sprintf('%d files found\n',tstim);
%% read all the images and compute the mean, std
for i = 1:tstim
    sprintf('File %d...\n',i);
    [im]        = imread([Folder f(i).name]);
    if ndims(im) == 3
        im = rgb2gray(im);
    end
    %get the face index from the filename
    face_index  = regexp(f(i).name,'[0-9][0-9]','match');
    face_index  = face_index{1};
    face_index  = str2num(face_index);
    %
    im    = double(im);
    %find the background
    imori = imread([imfolder f(i).name]);
    b     = ~magicwand(imori,1,1,0);
    % nan the image background
    im(~b) = NaN;
    %take Mean and Std of the image
    m(i) = nanmean(im(:));
    s(i) = nanstd(im(:));
end

subplot(1,2,1)
bar(m);
title('mean');
subplot(1,2,2)
bar(s);
title('std');
SaveFigure(sprintf('%s/M_S.png',save_path));
