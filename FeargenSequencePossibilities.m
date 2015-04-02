%for test
tface = 8;

mat = [];
for n = 3:6
    for m = 1:12
        
        S = SecondOrderBalancedSequence(10,[n n n n n n n n m 1],1);
        %
        nTrial_face = sum(S==2);
        nTrial_ucs  = sum(S==9);
        nTrial_odd  = sum(S==10);
        %
        mat = [mat ; n m nTrial_face nTrial_ucs./(nTrial_face+nTrial_ucs) length(S) nTrial_odd./length(S)*100];
    end
end
t = {'N' 'M' 'nTrial_Face' 'RR' 'tTrial' 'Odd'}
figure
for i = 1:size(mat,2)
    subplot(size(mat,2),1,i)
    plot(mat(:,i),'o-')
    box off;
    grid on;
    title(t{i},'interpreter','none')
    axis tight
end



%% for conditioning
tface = 2;

mat = [];
for m = 1:6
    for n = 12:36            
%         S = SecondOrderBalancedSequence(4,[n n m 1],1);
%         nTrial_face = sum(S==2);
%         nTrial_ucs  = sum(S==3);
%         nTrial_odd  = sum(S==4);
        %
        S = SecondOrderBalancedSequence(3,[n n m],2);
        %1 is CS+, 2 is CS-, 3 is ODDball, 4 is UCS;
        i = find(S == 1);
        i = Shuffle(i);
        i = i(1:round(length(i)/2));
        S(i) = 4;
        %
        nTrial_CSm = sum(S == 2);
        nTrial_CSp = sum(S == 1);
        nTrial_ucs = sum(S == 4);
        nTrial_odd = sum(S == 3);
        %        
        mat = [mat ; n m nTrial_CSm nTrial_ucs./(nTrial_CSp + nTrial_ucs) length(S) nTrial_odd./length(S)*100];
    end
end
t = {'N' 'M' 'nTrial_CS-' 'RR' 'tTrial' 'Odd'}
for i = 1:size(mat,2)
    subplot(size(mat,2),1,i)
    plot(mat(:,i),'o-')
    title(t{i},'interpreter','none')
    box off
end

