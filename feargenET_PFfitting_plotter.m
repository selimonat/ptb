alphas  = unique(d.param.alpha);
sds      = unique(d.param.sd);
trials  = unique(d.param.ttrials);
%
cmap    = jet(length(As));%in rgb
cmap    = rgb2hsv(cmap);%in hsv, it is easier to change color and brightness separately
%%
%plot the bias separately for different trials
figure(1);
clf;
hold on;
for i_a = 1:length(alphas)
   for i_s = 1:length(sds)       
       %select a color for each a, and change its brightness for different
       %s values.
       color = [cmap(i_a,1:2) i_s./length(Ss)];
       m     = squeeze(mean(d.alpha(:,i_a,i_s,:)));%average estimation
       
       plot(trials, m , 'o-' , 'color' , hsv2rgb(color) );
   end
end
hold off