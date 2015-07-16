function fearcloud_plotratings(subject,run,aligned)
   
r=isn_GetRatings(subject,run,aligned);
h=bar(r(:,:,run));
if run>2
    SetFearGenBarColors(h)
    set(gca,'XTickLabel',{'-135','-90','-45','CSP','45','90','135','180'})
elseif run==2
    xlabel('Number of Face')
end
ylim([0 10])
ylabel('mean subjective p(shock)')
axis square
title(sprintf('Subject %d, Phase %d',subject,run))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%mean ratings business
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r1=isn_GetRatings(subjects,[2],0);
r2=isn_GetRatings(subjects,[3 4],1);
subplot(1,3,1)
h=bar(mean(r1,2));
xlabel('Number of Face')
ylim([0 10])
xlim([0 9])
ylabel('mean subjective p(shock)')
axis square
title('baseline')
subplot(1,3,2)
h=bar(mean(r2(:,:,1),2));SetFearGenBarColors(h);
%set(gca,'XTickLabel',{'-135','-90','-45','CSP','45','90','135','180'})
set(gca,'XTickLabel',{'','','','CS+','','','','CS-'})
ylim([0 10])
xlim([0 9])
axis square
title('conditioning')

subplot(1,3,3)
h=bar(mean(r2(:,:,2),2));SetFearGenBarColors(h);
%set(gca,'XTickLabel',{'-135','-90','-45','CSP','45','90','135','180'})
set(gca,'XTickLabel',{'','','','CS+','','','','CS-'})
ylim([0 10])
xlim([0 9])
axis square
title('testphase')
