function ProcessingStack(imfolder,color,varargin)
%VARARGIN{1} = the group identity.

%check if there is slash at the end. Filesep knows if it is windoz or unix
if strcmp(imfolder(end),filesep) == 0;
    imfolder(end+1) = filesep;
end

%
if nargin > 2
    group = varargin{1};
else
    group = [];
end

%Smooth Edges of the Faces and rgb2gray them
[f]        = SmoothEdgesFacegen(imfolder,8,color);

%Smooth the Face itself
[f]        = SmoothFaceFacegen(f,5,1.4,color);

% Normalize the (grayscaled) Face
[f]        = NormalizeMeanStdGray(f,group);

 
%save v1 response maps
[f]        = CalibrateFace_V1Model(f);
% 
% %compute euclidian distance
[ed_v1]    = V1_EuclidianDistance(f);
% 
% %get the v1 coordinates with 2 dimension
[v1_space_3d] = V1Model2MDS(ed_v1,3);
[v1_space_2d] = V1Model2MDS(ed_v1,2);
% 
CalibrateFace_V1Model_plot(ed_v1,v1_space_2d,f);
CalibrateFace_V1Model_plot(ed_v1,v1_space_3d,f);
% % save the v1 response properties
% ComputeV1BandPassProperties(f)

% find the affine tranformation M, plots a figure
% [M] = V12FaceGen_Affine(v1_space,f);
% reverse perfect V1 circle to new Facegen Coordinates
% [facespace_new] = V12NewFaceSpace(M,f,v1_space);



  