function ComputeV1BandPassProperties(folder)
%ComputeV1BandPassProperties(folder)
%
% Computes the spatial frequency sensitivity of the v1 model. 36 is the
% pixels per degree, which is the sampling frequency, computed when the
% monitor is 50 cm away from the eye. The monitor is 40.7x30.6cm with a
% resolution of 1600x1200



[a,b,c,d] = GWTWgrid_Simple(rand(400),0,2,4.2);
[vec,freq]=ReduceFFT2(d);
figure;
plot(freq*36,vec,'k');
set(gca,'xscale','log','xtick',[.5 1 2 4 8 16]);
axis tight
xlim([0.5 16]);
xlabel('Spatial Frequency (cycles per degree)');
hold on;
plot([2 2],ylim,'r-');
plot([8 8 ],ylim,'r-');
hold off;
SaveFigure([folder 'V1_FilterProperties.png'])
figure;
imagesc(d);
axis image;
SaveFigure([folder 'V1_FilterProperties2.png'])
