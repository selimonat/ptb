function [imfolder_target]=SmoothEdgesFacegen(imfolder, fwhm )

imfolder_target = sprintf('%ssmoothededges_%03d\\',imfolder,fwhm);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
%
for imname = ListFiles([imfolder '\*.bmp'])'
    fprintf('Processing image: %s\n',imname{1})
    %read all the image
    i_rgb = imread(sprintf('%s%s',imfolder,imname{1}));
    i     = rgb2gray(i_rgb);
    i     = double(i(:,:,1));
    s     = size(i);
    %create a binary mask
    b = ~magicwand(i_rgb,1,1, 0);
    % nan the image background
    i(~b) = NaN;
    %smooth it a gaussian kernel of fullwidthhalfmaximum (input)
    g = make_gaussian(40,40,fwhm,fwhm,20,20);
    bg = conv2(double(b),g,'same');
    %take the derivatives, take their absolute values, inverse it
    
    v = abs(diff(bg,1,2));v = [ones(s(1),1) v];
    h = abs(diff(bg,1,1));h = [ones(1,s(2));h];
    m = Scale(v+h);
    m2 = -m+1;
    %mask it
    i2 = (i - nanmean(i(:))).*m2 + nanmean(i(:));
    i2(~b) = nanmean(i(:));
    imwrite(i2/255,sprintf('%s%s',imfolder_target,imname{1}));
%     imagesc(m);
end