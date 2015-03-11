function [D,Z,T] = V12FaceGen_Procrustes(v1_space,save_path)
%[D,Z,T] = V12FaceGen_Procrustes(v1_space)

facespace = GetFaceSpace;
[D, Z, T] = procrustes(v1_space,facespace,'reflection',0);
figure
plot(facespace(:,1),facespace(:,2),'b')
hold on;
plot(v1_space(:,1),v1_space(:,2),'g')
hold on;plot(Z(:,1),Z(:,2),'r')
axis square
axis equal
SaveFigure([save_path mfilename '.png']);
