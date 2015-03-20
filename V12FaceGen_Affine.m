function [M] = V12FaceGen_Affine(v1_space,save_path)
%[D,Z,T] = V12FaceGen_Procrustes(v1_space)
facespace=GetFaceSpace;
v = ones(length(facespace),1);

facespace    = [facespace v];
% [D, Z, T] = procrustes(v1_space,facespace);

M         = facespace\[v1_space v*0];
M(end)    = 1;

v1space_r = facespace*M;


figure
plot(facespace(:,1),facespace(:,2),'ro-')
hold on;
plot(v1_space(:,1),v1_space(:,2),'bo-')
hold on;
plot(v1space_r(:,1),v1space_r(:,2),'m.--')
axis square
axis equal
SaveFigure([save_path mfilename '.png']);