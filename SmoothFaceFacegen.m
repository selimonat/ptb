function [imfolder_target]=SmoothFaceFacegen(imfolder, kernelsize,fwhm,color)

%% create the folder if necessary
imfolder_target = sprintf('%ssmoothed_%03d_%03.2g%s',imfolder,kernelsize,fwhm,filesep);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
%% create Gaussian Kernel
g = make_gaussian2D(kernelsize,kernelsize,fwhm,fwhm,round(kernelsize/2),round(kernelsize/2));
g = g/sum(g(:));
k = round(kernelsize/2);
%%
for imname = ListFiles([imfolder '*.bmp'])'
    fprintf('Processing image: %s\n',imname{1})
    % read the image
    i = imread(sprintf('%s%s',imfolder,imname{1}));
    if ndims(i) == 3 && ~color%unless color is required
        i = rgb2gray(i);
    end
    i = double(i);        
    % smooth it a gaussian kernel of fullwidthhalfmaximum (input)
    for nd = 1:size(i,3)
        ig(:,:,nd) = conv2(i(:,:,nd),g,'same');    
        % correct for edge artefacts        
        bgc                = ig(k,k,nd);
        ig(1:k,:,nd)       = bgc;
        ig(end-k:end,:,nd) = bgc;
        ig(:,1:k,nd)       = bgc;
        ig(:,end-k:end,nd) = bgc;
    end
    
    % save
    imwrite(ig/255,sprintf('%s%s',imfolder_target,imname{1}));
end