function CalibrateFace_V1Model_plot(ed,mds,path2stim)
%ED is the output of CalibrateFace_V1Model, D is the coordinates in the V1
%space.

%merge dimensions according perceptual weights of RGB channels
if ndims(ed) == 3
    w  = [0.229,0.587,0.114];
    ed = ed(:,:,1)*w(1) + ed(:,:,2)*w(2)+ed(:,:,3)*w(3);
end

figure('position',[3 321 1285 345])

% plot matrix of euclidian distances
subplot(1,3,1)
imagesc(ed);colorbar;colormap jet;
axis image
title('Norm of the Difference')

% plot the first and middle diagonals
subplot(1,3,2)
plot(diag(ed,1),'o-')
hold on
% plot( diag(ed,size(ed,2)/2),'ro-')
hold off
box off
axis square

% plot plot the MDS results
subplot(1,3,3)
timage = size(ed,1);
if size(mds,2) == 2
    % % 2d plot
    plot(mds(:,1),mds(:,2),'o-')
    text(mds(:,1),mds(:,2),num2str([1:timage]'),'fontsize',10)
    hold on
    axis square
    axis equal
else
    % 3d plot for 2x16 faces
    plot3(mds(1:timage/2,1),mds(1:timage/2,2),mds(1:timage/2,3),'bo-')
    hold on
    plot3(mds(timage/2+1:end,1),mds(timage/2+1:end,2),mds(timage/2+1:end,3),'ro-')
    % text(mds(:,1),mds(:,2),num2str([1:size(ed,1)]'),'fontsize',8)
    axis square
    axis equal
    xlabel 'ID'
    ylabel 'gender'
    zlabel 'ethnicity'
end
SaveFigure([path2stim mfilename '_' datestr(now,'ssFFF') '.png']);

figure;
if size(mds,2) == 2
    % % 2d plot
    plot(mds(:,1),mds(:,2),'o-')
    text(mds(:,1),mds(:,2),num2str([1:timage]'),'fontsize',10)
    hold on
    axis square
    axis equal
else
     % 3d plot for 2x16 faces
    plot3(mds(1:timage/2,1),mds(1:timage/2,2),mds(1:timage/2,3),'bo-')
    hold on
    plot3(mds(timage/2+1:end,1),mds(timage/2+1:end,2),mds(timage/2+1:end,3),'ro-')
    % text(mds(:,1),mds(:,2),num2str([1:size(ed,1)]'),'fontsize',8)
    axis square
    axis equal
    xlabel 'ID'
    ylabel 'gender'
    zlabel 'ethnicity'
end

SaveFigure([path2stim mfilename 'MDSzoom' '_' datestr(now,'ssFFF')  '.png']);

