function [Facegen_new_2]=V12FaceGen_Procrustes_plot(v1_space)
% ED is the output of CalibrateFace_V1Model
% [ed]=CalibrateFace_V1Model('C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\selim first\36\Normalized\');
% save('36.mat','ed')
% [ed]=CalibrateFace_V1Model(path2stim);
[D,Z,T] = V12FaceGen_Procrustes(v1_space);
plot(Z(:,1),Z(:,2),'r')
% text(Z(:,1),Z(:,2),num2str([1:size(Z,1)]'),'fontsize',10)
%Circle coordinates resolution of 36 faces

% [X_koord] = cos([0:10:350]*pi/180)*r
% [Y_koord] = sin([0:10:350]*pi/180)*r
% [circle] = [X_koord;Y_koord]';
% plot(X_koord,Y_koord,'o-m')

%Procrustes Transformation now applied to our Coordinates, backwards

% [Facegen_new] = inv(T.b)*(circle - T.c)*inv(T.T);
% figure
% plot(Facegen_new(:,1),Facegen_new(:,2),'ro-');
% axis square
% axis equal
% hold on
% plot(face_space(:,1),face_space(:,2),'bo-')
% title('FaceGen Space')

%low resolution perfect circle
hold on
[X_koord_2] = cos([0:45:355]*pi/180)*r
[Y_koord_2] = -sin([0:45:355]*pi/180)*r
[circle_2] = [X_koord_2;Y_koord_2]';
plot(X_koord_2,Y_koord_2,'go-')


[Facegen_new_2] = round(inv(T.b)*(circle_2 - T.c(1:size(circle_2,1),:))*inv(T.T))
hold on
plot(Facegen_new_2(:,1),Facegen_new_2(:,2),'k-')

%plotting it with the same scale as the perfect circle
factor=(circle_2(1,1)/Facegen_new_2(1,1));
scaledCoord=Facegen_new_2*factor
hold on
plot(scaledCoord(:,1),scaledCoord(:,2),'mp-')
text(scaledCoord(:,1),scaledCoord(:,2),num2str([1:size(scaledCoord,1)]'),'fontsize',10)
% 
%if you want to save it..
% SaveFigure('C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\realCircleNov\procrustes150newGWTW\ethnic\raw22steps.eps')
% SaveFigure('C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\realCircleNov\procrustes150newGWTW\ethnic\raw22steps.png')

%higher resolution for the Psychometric Function Task:


[X_koord_3] = cos([22.5:45:350]*pi/180)*r
[Y_koord_3] = -sin([22.5:45:355]*pi/180)*r
[circle_3] = [X_koord_3;Y_koord_3]';
plot(X_koord_3,Y_koord_3,'go-')


[Facegen_new_3] = round(inv(T.b)*(circle_3 - T.c(1:size(circle_3,1),:))*inv(T.T))
hold on
plot(Facegen_new_3(:,1),Facegen_new_3(:,2),'y-')

%plotting it with the same scale as the perfect circle
factor=(circle_2(1,1)/Facegen_new_2(1,1));
scaledCoord_3=Facegen_new_3*factor
hold on
plot(scaledCoord_3(:,1),scaledCoord_3(:,2),'yp-')
text(scaledCoord_3(:,1),scaledCoord_3(:,2),num2str([1:size(scaledCoord_3,1)]'),'fontsize',10)
% figure
% plot(Facegen_new_2(:,1),Facegen_new_2(:,2),'gp-');
% axis square
% axis equal
% hold on
% plot(face_space(:,1),face_space(:,2),'bo-')
% title('FaceGen Space')
% 
% Facegen_Coord=round([Facegen_new(1,:);Facegen_new_2(5,:);Facegen_new(10,:);Facegen_new_2(14,:);Facegen_new(19,:);Facegen_new_2(23,:);Facegen_new(28,:);Facegen_new_2(32,:)])
% % Facegen_Coord=round(Facegen_Coord)

% save('C:\Users\onat\Desktop\FaceSimilarityQuantification\_creation steps\realCircleNov\procrustes150newGWTW\....mat','Facegen_new_2')
% %Scaling 
% coordsv1=CalibrateFace_V1Model_plot(ed)
% dist15=sqrt((coordsv1(1,1)-coordsv1(5,1))^2+(coordsv1(1,2)-coordsv1(5,2))^2)

%stretching of 3 to 7 to same distance as 1 to 5
% v15=[ans(1,:);ans(5,:)]
% d15=pdist(v15)
% v37=[ans(3,:);ans(7,:)]
% d37=pdist(v37)
% v1space(7,:)=[1.5*v1space(7,:)]
% v1space(3,:)=[1.5*v1space(3,:)]
% stretched=round(inv(T.b)*(v1space - T.c(1:size(v1space,1),:))*inv(T.T))
