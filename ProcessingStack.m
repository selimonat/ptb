function ProcessingStack(imfolder)



%Smooth Edges of the Faces and rgb2gray them
[f]        = SmoothEdgesFacegen(imfolder,8);
%Smooth the Face itself
[f]        = SmoothFaceFacegen(f,5,1.4);
%Normalize the (grayscaled) Face
[f]        = NormalizeMeanStdGray(f);
%compute euclidian distance and save v1 response maps
[ed_v1,f]  = CalibrateFace_V1Model(f);
%get the v1 coordinates with 2 dimension
[v1_space] = V1Model2MDS(ed_v1,2);

CalibrateFace_V1Model_plot(ed_v1,v1_space,f);
% save the v1 response properties
ComputeV1BandPassProperties(f)

% % % % %finds the procrustes tranformation, plots a figure (also saved)
[D,Z,T] = V12FaceGen_Procrustes(v1_space,f);
% % % % %plot its results
% % % % V12FaceGen_Procrustes_plot(v1_space);
keyboard;