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
%prepare the kernel
g = make_gaussian2D(40,40,fwhm,fwhm,20,20);
g = g./sum(g(:));
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
%         dummy(~bmask(:)) = 0;        
        bmask            = b(:,:,fi);
        I = double(bmask);
        Gx = [-1 1];
        Ix = conv2(I,Gx,'same');        
        Iy = conv2(I,Gx','same');
        I  = sqrt(Ix.^2+Iy.^2);
        Id = imdilate(I,strel('disk',4)) > 0;
        Id = logical(Id);
        %
        dummyg       = conv2(dummy,g,'same');
        dummy(Id(:)) = dummyg(Id(:));
        %
%         bg = i(1,1,nch);%assumes the first channel to represent bg value.
%         bg = repmat(bg,400,400);
        
        
        %get the mean of the face for R,G and B channels, will make our life
        %easier if values are located in the 3rd dimension.
        face_mean(fi,1,nch) = mean(dummy(bmask));
        %smooth it with a gaussian kernel of fullwidthhalfmaximum (input)    
%         bmaskg    = conv2(double(bmask),g,'same');
%         bmaskg    = Scale(bmaskg.^4);
        
%         %take the derivatives, take their absolute values, inverse it    
%         v         = abs(diff(bmaskg,1,2));v = [ones(s(1),1) v];
%         h         = abs(diff(bmaskg,1,1));h = [ones(1,s(2));h];
%         m         = Scale((v+h));
%         edge_mask = -m+1;
%         dummy =  bg.*(1-bmaskg) + dummy.*bmaskg;
        %
        %mask it: first remove its mean from the face (R, G, B separately if
        %an RGB image, and then point-wise multiply with the mask. In the
        %second, loop we will add the mean)
%         i2(:,:,nch,fi)      = (dummy - face_mean(fi,1,nch)).*edge_mask;%we will add later the mean of the global face mean
        tobesaved(:,:,nch) = dummy;
    end
    imwrite(tobesaved/255,sprintf('%s%s',imfolder_target,imname{1}));
end

% % %% run once more across all images to add the global mean
% % for imname = ListFiles([f '*.bmp'])'
% %     %get the face index from the filename
% %     fi  = regexp(imname{1},'[0-9][0-9]','match');
% %     fi  = fi{1};
% %     fi  = str2num(fi);
% %     % add the same global mean to all images.
% %     for nch = 1:3
% %         dummy              = i2(:,:,nch,fi);    
% %         dummy              = dummy + repmat(face_mean(fi,1,nch),[400 400 1]);%+ repmat(mean(face_mean),[size(dummy,1) size(dummy,2) 1]);    
% %         dummy(isnan(dummy))= face_mean(fi,1,nch);
% %         tobesaved(:,:,nch) = dummy;
% %     end
% %     %
% %     imwrite(tobesaved/255,sprintf('%s%s',imfolder_target,imname{1}));
% % end