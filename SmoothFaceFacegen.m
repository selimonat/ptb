function [imfolder_target]=SmoothFaceFacegen(imfolder, kernelsize,fwhm )


imfolder_target = sprintf('%ssmoothed_%03d_%03.2g%s',imfolder,kernelsize,fwhm,filesep);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
% create Gaussian Kernel
g = make_gaussian2D(kernelsize,kernelsize,fwhm,fwhm,round(kernelsize/2),round(kernelsize/2));
g = g/sum(g(:));
for imname = ListFiles([imfolder '*.bmp'])'
    fprintf('Processing image: %s\n',imname{1})
    %read all the image
    i = imread(sprintf('%s%s',imfolder,imname{1}));
    if ndims(i) == 3
        i = rgb2gray(i);
    end
    i = double(i);
    s     = size(i);
    
    %smooth it a gaussian kernel of fullwidthhalfmaximum (input)
    
    
    ig = conv2(i,g,'same');
    
    k=round(kernelsize/2);
    bgc=ig(k,k);
    ig(1:k,:)=bgc;
    ig(end-k:end,:)=bgc;
    ig(:,1:k)=bgc;
    ig(:,end-k:end)=bgc;
    
    
    imwrite(ig/255,sprintf('%s%s',imfolder_target,imname{1}));
end


end
