path     = '/home/onat/Documents/CalibrationTests/Experiments/SimilarityExperiment/';
%path     = '/Users/sonat/Documents/ProjectsSCIENCE/UKE/LabComputer/onat/Documents/CalibrationTests/Experiments/SimilarityExperiment/';
savepath = [path 'results/'];
readpath = [path 'data/'];
%
f     = dir([readpath '*.mat']);
%sList = 1:length(f);%subjects you want to analyze
sList = [1 2 3 5 7 8 9 10 11];%discard the bad subjects
genderi = [0 0 0 1 0 1 1 0 1 1 1];%ge
%some constants (these could be obtained from the result file actually)
tStim = 12;%
tPair = tStim*(tStim-1)/2+tStim;%total comparisons
tAdap = tStim;%the number of adaptation trials
mat   = [];block   = [];sub = [];time = [];gender=[];%
[y x] = meshgrid(1:tStim,1:tStim);
for nf = sList      
    load([readpath f(nf).name])
    tBlock = (length(result.r)-tAdap)/tPair;%number of blocks    
    for nb = 1:tBlock%
        ind   = tAdap + (tPair*(nb-1)+1 : tPair*(nb));%get the trials of block NB
        %
        %the similarity matrix
        %lower triangular
        LT      = accumarray(result.stim(:,ind)',  result.r(ind), [tStim tStim]);
        %symmetric;
        SM      = LT' + LT;
        SM(x==y) = LT(x==y);
        %
        mat   = cat(3,mat,SM);
        %
        %subject, block and the duration
        sub   = [sub nf];
        block = [block nb];
        time  = [time diff(result.t(ind)/1000) ];
        gender = [gender genderi(nf)];
    end    
end

%now align different columns of the mat
alignto = 6;
for nmat = 1:size(mat,3);   
    for ncol = 1:tStim
        ind = mod((1:12)+(alignto-1)-(ncol-1)-1,tStim)+1;
        mat_a(ind,ncol,nmat) = mat(:,ncol,nmat);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plot subjectsxblock
figure(1)
%set(gcf,'position',[1882 58 356 1266])
set(gcf,'position',[1166 4 643 1114])
tSub = length(unique(sub));
counter = 0;
for nsub = unique(sub);
    subi = (nsub == sub);
    for nb = 1:3    
        counter = counter + 1;
        subplot(tSub,3,counter);
        imagesc(mean(mat_a(:,:,(block == nb) & (subi)),3),[1 7]);
        set(gca,'xtick',1:12,'ytick',6,'yticklabel','0','xticklabel',{'1' '' '3' '' '5' '' '7' '' '9' '' '11' ''})        
        axis image
        if nb == 2;
            title(cell2mat((regexp(cell2mat(regexp(f(nsub).name,'_\D\w*\.','match')),'[a-z,A-Z]','match'))));
        end
    end
end
SaveFigure([savepath 'AlignedMatrix_subject.eps']);
SaveFigure([savepath 'AlignedMatrix_subject']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2);
set(gcf,'position',[1083 141 679 959])
for nb=1:3;
    %
    subplot(3,2,(2*(nb-1)+1));   
    imagesc(mean(mat_a(:,:,block == nb),3),[1 7]);
    set(gca,'xtick',[0:12]+0.5,'ytick',[0:12]+0.5,'xticklabel',[],'yticklabel',[]);grid on;
    axis image
    title(['block' mat2str(nb)])
    colorbar
    %
    subplot(3,2,(2*(nb-1)+1)+1);
    contourf(mean(mat_a(:,:,block == nb),3),1:7);
    set(gca,'xtick',[0:12]+0.5,'ytick',[0:12]+0.5,'xticklabel',[],'yticklabel',[]);grid on;
    axis image
    axis ij
    title(['block' mat2str(nb)])
    colorbar
    %
end
SaveFigure([savepath 'AlignedMatrix_Averaged.eps']);
SaveFigure([savepath 'AlignedMatrix_Averaged']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(3);
subplot(1,2,1)
imagesc(mean(mat_a(:,:,:),3),[1 7]);axis image;colorbar
set(gca,'xtick',[0:12]+0.5,'ytick',[0:12]+0.5,'xticklabel',[],'yticklabel',[]);grid on;
subplot(1,2,2)
contourf(mean(mat_a(:,:,:),3),1:7);axis image;axis ij;colorbar
set(gca,'xtick',[0:12]+0.5,'ytick',[0:12]+0.5,'xticklabel',[],'yticklabel',[]);grid on;
SaveFigure([savepath 'GrandAverage.eps']);
SaveFigure([savepath 'GrandAverage']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot 3 plots for each block
figure(4);
c = {'r' 'g' 'b'};
plot(-5:6,mean(mean(mat_a(:,:,:),3),2),'o-','color',c{nb},'linewidth',3);
axis([-5 6 1 7])
title('similarity = f(block)');
xlabel('distance from reference')
ylabel('similarity rating')
axis square
SaveFigure([savepath 'SimilarityProfile.eps']);
SaveFigure([savepath 'SimilarityProfile']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fit Gaussians to the aligned correlation matrix
cmat_a = mean(mat_a(:,:,:),3);
opts = optimset('display','iter','tolfun',10^-9,'tolx',10^-9);
clear X;
for ns = 1:size(cmat_a,2)
    x0 = [ max(cmat_a(:,ns)) 6 min(cmat_a(:,ns)) ];%[peak fwhm baseline];
%    out = make_gaussian1d(Xsize,amplitude,center,fwhmX,baseline)
    [X(ns,:) fval(ns) ef(ns)] = ...
fminsearch( @(X) sum((cmat_a(:,ns)' - make_gaussian1d(12,X(1),6,X(2),X(3)) ).^2) , x0, opts );
    cmat_fit(:,ns) = make_gaussian1d(12,X(ns,1),6,X(ns,2),X(ns,3));
end
figure(5);
subplot(1,2,1);
imagesc(cmat_fit);axis image;
set(gca,'xtick',[0:12]+0.5,'ytick',[0:12]+0.5,'xticklabel',[],'yticklabel',[]);grid on;
theta = deg2rad((0:-(360./tStim):-(360-(360./tStim)))+90);
theta = [theta(:) ;theta(1)];
rho   = X(:,2);
rho   = [rho(:) ;rho(1)];
subplot(1,2,2);
h = polar(theta,rho);set(h,'linewidth',3,'color','k')
SaveFigure([savepath 'SimilarityWidth.eps']);
SaveFigure([savepath 'SimilarityWidth']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%make the pca
figure(6);
cmat = mean(mat(:,:,:),3);
[coeff, score, latent, tsquared]=princomp(cmat);
subplot(1,2,2)
plot(score(:,1),score(:,2),'o-');set(gca,'xtick',0,'ytick',0);grid on;
axis square
axis([-6 6 -6 6])
subplot(1,2,1)
plot(latent,'o-');
axis square
SaveFigure([savepath 'PCA.eps']);
SaveFigure([savepath 'PCA']);

% % 
% % figure(4)  
% % cmat_a = mean(mat_a(:,:,:),3);
% % flank = [];
% % for ns = 1:tStim        
% %     flank(ns) = mean(cmat_a([5 7],ns)-cmat_a([6],ns));
% % end
% % rho   = [flank flank(1)];
% % theta = deg2rad(0:(360./tStim):360-(360./tStim));
% % theta = [theta theta(1)];
% % h = polar(theta,rho)
% % set(h,'linewidth',3);
% % end
% % 
% % 
% % 
% % 
% % figure(6)
% % for nb = 1:3    
% %     cmat_a = mean(mat_a(:,:,block == nb),3);
% %     [u s v]=svd(cmat_a);
% %     subplot(1,3,nb);
% %     polar(deg2rad(0:(360./tStim):360-(360./tStim)),flank)
% % end
% % 
