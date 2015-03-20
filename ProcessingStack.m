function ProcessingStack(imfolder)

%check if there is slash at the end. Filesep knows if it is windoz or unix
if strcmp(imfolder(end),filesep) == 0;
    imfolder(end+1) = filesep;
end

%Smooth Edges of the Faces and rgb2gray them
[f]        = SmoothEdgesFacegen(imfolder,8);
%Smooth the Face itself
[f]        = SmoothFaceFacegen(f,5,1.4);
%Normalize the (grayscaled) Face
[f]        = NormalizeMeanStdGray(f);
%save v1 response maps
[f]        = CalibrateFace_V1Model(f);

%compute euclidian distance
[ed_v1]    = V1_EuclidianDistance(f);

%get the v1 coordinates with 2 dimension
[v1_space] = V1Model2MDS(ed_v1,2);

CalibrateFace_V1Model_plot(ed_v1,v1_space,f);
% save the v1 response properties
ComputeV1BandPassProperties(f)

% % % % %finds the procrustes tranformation, plots a figure (also saved)
[M,facespace_r] = V12FaceGen_Affine(v1_space,f);
% % % % %plot its results
% % % % V12FaceGen_Procrustes_plot(v1_space);
