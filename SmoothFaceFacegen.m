function [imfolder_target]=SmoothFaceFacegen(imfolder, kernelsize,fwhm )


imfolder_target = sprintf('%ssmoothed_%03d_%03d\\',imfolder,kernelsize,fwhm);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
% create Gaussian Kernel
 g = make_gaussian(kernelsize,kernelsize,fwhm,fwhm,round(kernelsize/2),round(kernelsize/2));
 g = g/sum(g(:));
for imname = ListFiles(imfolder)'
    fprintf('Processing image: %s\n',imname{1})
    %read all the image
    i = double(imread(sprintf('%s%s',imfolder,imname{1})));
    s     = size(i);
    
    %smooth it a gaussian kernel of fullwidthhalfmaximum (input)
   
    ig = conv2(i,g,'same');
   
    imwrite(ig/255,sprintf('%s%s',imfolder_target,imname{1}));
end