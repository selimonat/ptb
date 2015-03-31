function [imfolder_target]=SmoothEdgesFacegen(f, fwhm, color )
%Smoothens edges of the face, however to do so it requires the BG and the
%face to have same mean luminance. The resulting effect is like a face
%emerging from the background; if the face ML is different than the BG 
%edges become salient.


global imfolder%original folder of RGB images

%create the target folder if not existing
imfolder_target = sprintf('%ssmoothededges_%03d%s',f,fwhm,filesep);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
%prepare the kernel for smoothing the image
g = make_gaussian2D(40,40,fwhm,fwhm,20,20);
g = g./sum(g(:));
Gx = [-1 1];%contour detection kernel
%%
for imname = ListFiles([f '*.bmp'])'
    %
    fprintf('Processing image: %s\n',imname{1})
    %get the face index from the filename
    fi  = regexp(imname{1},'[0-9][0-9]','match');
    fi  = fi{1};
    fi  = str2num(fi);
    %
    %create a binary mask of the face and store it
    i_rgb       = imread(sprintf('%s%s',imfolder,imname{1}));        
    b(:,:,fi)   = ~magicwand(i_rgb,1,1, 0);
    %
    %read the image    
    i           = imread(sprintf('%s%s',f,imname{1}));
    %remove color if desired
    if ndims(i) == 3 && ~color
        i       = rgb2gray(i);
    end
    i           = double(i);
    s           = size(i);    
    %    
    for nch = 1:size(i,3)%masking on a channel by channel basis
        %get channel by channel
        dummy           = i(:,:,nch);
        %zero the background  
        bmask    = b(:,:,fi);
        I        = double(bmask);        
        Ix       = conv2(I,Gx,'same');        
        Iy       = conv2(I,Gx','same');
        I        = sqrt(Ix.^2+Iy.^2);
        Id       = imdilate(I,strel('disk',4)) > 0;
        Id       = logical(Id);
        %
        dummyg       = conv2(dummy,g,'same');
        dummy(Id(:)) = dummyg(Id(:));        
        %                
        tobesaved(:,:,nch) = dummy;
    end
    imwrite(tobesaved/255,sprintf('%s%s',imfolder_target,imname{1}));
end