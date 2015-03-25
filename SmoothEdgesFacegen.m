function [imfolder_target]=SmoothEdgesFacegen(f, fwhm )

global imfolder%original folder of RGB images


imfolder_target = sprintf('%ssmoothededges_%03d%s',f,fwhm,filesep);
if exist(imfolder_target) == 0
    mkdir(imfolder_target);
end
%
g = make_gaussian2D(40,40,fwhm,fwhm,20,20);
for imname = ListFiles([f '*.bmp'])'
    
    %get the face index from the filename
    face_index  = regexp(imname{1},'[0-9][0-9]','match');
    face_index  = face_index{1};
    face_index  = str2num(face_index);
    %
    fprintf('Processing image: %s\n',imname{1})
    %create a binary mask of the face
    i_rgb = imread(sprintf('%s%s',imfolder,imname{1}));        
    b(:,:,face_index)     = ~magicwand(i_rgb,1,1, 0);
    
    %read the image    
    i     = imread(sprintf('%s%s',f,imname{1}));
    if ndims(i) == 3
        i = rgb2gray(i);
    end
    i     = double(i(:,:,1));
    s     = size(i);    
    %
    % nan the image background
    bg_mean(face_index)   = mean(i(b(:,:,face_index) == 0));
    face_mean(face_index) = mean(i(b(:,:,face_index) == 1));
    %
    i(~b(:,:,face_index)) = NaN;
    %smooth it with a gaussian kernel of fullwidthhalfmaximum (input)    
    bg = conv2(double(b(:,:,face_index)),g,'same');
    %take the derivatives, take their absolute values, inverse it    
    v  = abs(diff(bg,1,2));v = [ones(s(1),1) v];
    h  = abs(diff(bg,1,1));h = [ones(1,s(2));h];
    m  = Scale(v+h);
    m2 = -m+1;
    %
    %mask it
    i2(:,:,face_index)      = (i - face_mean(face_index)).*m2;%we will add later the mean of the global face mean

    
end

%% run once across all images to detect the global mean
for imname = ListFiles([f '*.bmp'])'
    %get the face index from the filename
    face_index  = regexp(imname{1},'[0-9][0-9]','match');
    face_index  = face_index{1};
    face_index  = str2num(face_index);
    %
    dummy      =  i2(:,:,face_index);
    dummy      = dummy + mean(face_mean);
    dummy(~b(:,:,face_index))  = mean(face_mean);        
    %
    imwrite(dummy/255,sprintf('%s%s',imfolder_target,imname{1}));
end