function [test]=NormalizeMeanStd(Folder)
%this function normalizes the mean luminance and standard deviation of RGB
%channells independently, it thereofre equalized the color. The input to
%this script must be the .png version of the faces with transparent
%background. The reason is that, the background should not contribute to
%the computation of the RGB ML and LC values. In order to run the script
%first go to the Folder where different stimuli are located.

%Folder = './Circle12_08Face_Frontal_SkinModerated_Transparent/';
% Folder = 'C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\selim first\36\png\'
save_path = regexprep(Folder,'png','Normalized');
if exist(save_path) == 0
    mkdir(save_path);
else
    delete([save_path '*'])
end
f = dir([Folder '*.png']);
tstim = length(f);
sprintf('%d files found\n',tstim);

%read all the images and compute the mean, std of R, G, B channels
for i = 1:tstim
    sprintf('File %d...\n',i);
    [im map alpha] = imread([Folder f(i).name]);
    %
    im    = double(im);
    alpha = alpha>0;
    %
    R = im(:,:,1);
    G = im(:,:,2);
    B = im(:,:,3);
    %
    R = R(alpha);
    G = G(alpha);
    B = B(alpha);
    %
    mR(i) = mean(R);
    mG(i) = mean(G);
    mB(i) = mean(B);    
    vR(i) = std(R);
    vG(i) = std(G);
    vB(i) = std(B);    
end    

%take the mean, std across all images for R, G and B channels
    mtR  = mean(mR);
    mtG  = mean(mG);
    mtB  = mean(mB);
    vtR  = mean(vR);
    vtG  = mean(vG);
    vtB  = mean(vB);             
    
    BG   = rgb2gray([mtR mtG mtB]./255)*255;
    
    
for i = 1:tstim
    [im map alpha] = imread([Folder f(i).name]);
    %
    im    = double(im);
    alpha = alpha>0;
    %
    R = im(:,:,1);
    G = im(:,:,2);
    B = im(:,:,3);
    %
    R = R(alpha);
    G = G(alpha);
    B = B(alpha);
    %
    R2 = zeros(length(alpha(:)),1);
    G2 = zeros(length(alpha(:)),1);
    B2 = zeros(length(alpha(:)),1);
    % all face pixels will have the same R, G, B mean values as well as std
    R2(alpha) = (R-mR(i))./vR(i)*vtR+mtR;
    G2(alpha) = (G-mG(i))./vG(i)*vtG+mtG;
    B2(alpha) = (B-mB(i))./vB(i)*vtB+mtB; 
    % all background pixels gathers BG value
    
    R2(~alpha) = BG(1);
    G2(~alpha) = BG(1);
    B2(~alpha) = BG(1);

    %
    im2 = cat(3,reshape(R2,400,400),reshape(G2,400,400),reshape(B2,400,400));
    imwrite(uint8(im2), [ save_path regexprep(f(i).name,'png$','bmp')],'bmp');
end
 

f       = dir([ save_path  '*.bmp']);
f_alpha = dir([Folder '*.png']);
for i = 1:tstim
    [im map dummy]     = imread([ save_path f(i).name ]);
    [dummy shit alpha] = imread([Folder f_alpha(i).name]);
    %
    im    = double(im);
    alpha = alpha>0;
    %
    R = im(:,:,1);
    G = im(:,:,2);
    B = im(:,:,3);
    %
    R = R(alpha);
    G = G(alpha);
    B = B(alpha);
    %
    test.mR(i) = mean(R);
    test.mG(i) = mean(G);
    test.mB(i) = mean(B) ;   
    test.vR(i) = std(R);
    test.vG(i) = std(G);
    test.vB(i) = std(B) ;
end
    

    