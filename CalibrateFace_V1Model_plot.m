function [d]=CalibrateFace_V1Model_plot(ed)
%ED is the output of CalibrateFace_V1Model, D is the coordinates in the V1
%space.




%% 1/show the similarity matrix and 2/plot off diagonal elements if R, G and B channels

% tChannel = size(ed,3);
% color = {'r' 'g' 'b'};
% close all;
% for nChannel = 1:tChannel
%     figure(1)
%     subplot(2,tChannel,nChannel);
%     imagesc(ed(:,:,nChannel));
%     drawnow;
%     axis image;
%     title(['Channel: ' color{nChannel}])
%     colorbar;        
% end
% 
% for noffset = 1:3
%     subplot(2,tChannel,noffset+3);
%     for nChannel = 1:tChannel
%         plot(diag(ed(:,:,nChannel),noffset),'color',color{nChannel},'linewidth',3)
%         hold on
%     end
%     hold off
%     box off
%     legend(color{:})
%     legend boxoff
%     title(['Offset: ' mat2str(noffset)])
% end
%SaveFigure('/home/onat/Documents/Experiments/_Notes/fig/CalibrateFaces_EffectOfChannel_800kernels.png')
%% plot the matrix and the first diagonal




figure('position',[3 321 1285 345])
subplot(1,3,1)
imagesc(mean(ed(:,:,:),3));colorbar;colormap jet;
axis image
title('Norm of the Difference')
%
subplot(1,3,2)
plot(diag(mean(ed(:,:,:),3),1),'o-')
hold on
plot( diag(mean(ed(:,:,:),3),size(ed,2)/2),'ro-')
hold off
box off
axis square

subplot(1,3,3)
% im = mean(ed,3); %just takes the mean of RGB-channels. Now weighted.
w  = [0.229,0.587,0.114];
im = ed(:,:,1)*w(1) + ed(:,:,2)*w(2)+ed(:,:,3)*w(3);
d   = mdscale(im,3); %set to (im,2) for 2-dimensional scaling.
% % 2d plot
% plot(d(:,1),d(:,2),'o-')
% text(d(:,1),d(:,2),num2str([1:size(ed,1)]'),'fontsize',10)
% hold on
% axis square
% axis equal

% 3d plot for 2x8 faces
% plot3(d(1:8,1),d(1:8,2),d(1:8,3),'bo-')
% hold on
% plot3(d(9:16,1),d(9:16,2),d(9:16,3),'ro-')
% text(d(:,1),d(:,2),num2str([1:size(ed,1)]'),'fontsize',10)
% axis square
% axis equal

% 3d plot for 2x16 faces
plot3(d(1:16,1),d(1:16,2),d(1:16,3),'bo-')
hold on
plot3(d(17:32,1),d(17:32,2),d(17:32,3),'ro-')
% text(d(:,1),d(:,2),num2str([1:size(ed,1)]'),'fontsize',8)
axis square
axis equal
xlabel 'ID'
ylabel 'gender'
zlabel 'ethnicity'

% SaveFigure([path2stim mfilename '.png']);
% save([path2stim mfilename],'ed');
