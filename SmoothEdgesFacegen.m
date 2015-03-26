function [imfolder_target]=SmoothEdgesFacegen(f, fwhm, color )

global imfolder%original folder of RGB images

%create the target folder if not existing
imfolder_target = sprintf('%ssmoothededges_%03d%s',f,fwhm,filesep);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
%prepare the kernel
g = make_gaussian2D(40,40,fwhm,fwhm,20,20);
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
    %get the image
    if ndims(i) == 3 && ~color
        i       = rgb2gray(i);
    end
    i           = double(i);
    s           = size(i);    
    %
    % nan the image background, repmat the mask along 3rd dimen if
    % necessary
    i(repmat(~b(:,:,fi),[1 1 size(i,3)])) = NaN;
    %get the mean of the image
    face_mean(fi,1,:) = squeeze(nanmean(nanmean(i,1),2));
    %smooth it with a gaussian kernel of fullwidthhalfmaximum (input)    
    bg = conv2(double(b(:,:,fi)),g,'same');
    %take the derivatives, take their absolute values, inverse it    
    v  = abs(diff(bg,1,2));v = [ones(s(1),1) v];
    h  = abs(diff(bg,1,1));h = [ones(1,s(2));h];
    m  = Scale(v+h);
    m2 = -m+1;
    %
    %mask it
    i2(:,:,:,fi)      = (i - repmat(face_mean(fi,1,:),[size(i,1) size(i,2) 1])).*repmat(m2,[1 1 size(i,3)]);%we will add later the mean of the global face mean
end

%% run once more across all images to add the global mean
for imname = ListFiles([f '*.bmp'])'
    %get the face index from the filename
    fi  = regexp(imname{1},'[0-9][0-9]','match');
    fi  = fi{1};
    fi  = str2num(fi);
    % add the same global mean to all images.
    dummy              = i2(:,:,:,fi);
    dummy(isnan(dummy))= 0;
    dummy              = dummy + repmat(mean(face_mean),[size(dummy,1) size(dummy,2) 1]);    
    %
    imwrite(dummy/255,sprintf('%s%s',imfolder_target,imname{1}));
end