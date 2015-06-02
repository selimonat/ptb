%% Loads the feargen ethno fixmat
clear all
filename = '/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/midlevel/fixmat.mat';
%
if ~exist(filename)
    ppath  = '~/Documents/BehavioralExperiments/2013_10_feargen_ethno/';
    addpath('/Users/onat/Documents/Code/Matlab/edfread/current.href/utils');
    addpath(genpath_exclude('/Users/onat/Documents/Code/Matlab/condprob','.svn'));
    f      = FilterF(ppath,'data.mat','eye');
    tf     = length(f);
    a      = load('/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno//sub002/phase03/stimulation/data.mat');
    f(:)
    %
    fixmat = [];
    for nf = 1:tf
        %
        load(f{nf});
        %extract subject information
        subject = (strvcat(regexp(strvcat(regexp(f{nf},'sub\d\d\d','match')),'\d\d\d','match')));
        load(sprintf('/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno//sub%03d/phase03/stimulation/data.mat',str2num(subject)));
        csp     = p.stim.cs_plus;
        %remove the space from the field name
        trials  = cell2struct( struct2cell(trials), regexprep(fieldnames(trials),' ',''));
        
        % now produce a set of new fields for fixations.m to be able to create
        % a nice fixmat for us.
        %
        for nt = 1:length(trials)
            T = trials(nt).UCS.msg(1,:);
            %extract relevant info first from the text message
            phase   = (strvcat(regexp(strvcat(regexp(T,'PHASE: \d\d','match')),'\d\d','match')));
            cond    = (strvcat(regexp(T,'\d\d\d','match')));
            ucs     = (strvcat(regexp(strvcat(regexp(T,'UCS: \d\d','match')),'\d\d','match')));
            odd     = (strvcat(regexp(strvcat(regexp(T,'ODDBALL: \d\d','match')),'\d\d','match')));
         
            chain   = (strvcat(regexp(strvcat(regexp(T,'CHAIN: \d\d','match')),'\d\d','match')));
            ctrial  = (strvcat(regexp(strvcat(regexp(T,'CHAINTRIAL: \d\d','match')),'\d\d','match')));
            ttrial  = (strvcat(regexp(strvcat(regexp(T,'TTRIAL: \d\d','match')),'\d\d','match')));
            isref   = (strvcat(regexp(strvcat(regexp(T,'ISREF: \d\d','match')),'\d\d','match')));
            file    = (strvcat(regexp(strvcat(regexp(T,'FILE: \d\d','match')),'\d\d','match')));
            dref    = (strvcat(regexp(strvcat(regexp(T,'DELTAREF: \d\d','match')),'\d\d','match')));
            dcsp    = (strvcat(regexp(strvcat(regexp(T,'DELTACSP: \d\d','match')),'\d\d','match')));
            dFG     = (strvcat(regexp(strvcat(regexp(T,'FGDELTA: \d\d','match')),'\d\d','match')));
            fxx     = (strvcat(regexp(strvcat(regexp(T,'FXX: \d\d','match')),'\d\d','match')));
            fxy     = (strvcat(regexp(strvcat(regexp(T,'FXY: \d\d','match')),'\d\d','match')));
            %
            trials(nt).trial.msg             = mat2str(nt);
            trials(nt).phase.msg             = phase;
            trials(nt).subject.msg           = subject;
            trials(nt).condition.msg         = cond;
%             trials(nt).condition_aligned.msg = mat2str(ConditionAligner(FaceIndex2Degrees(csp(1),str2num(cond))) + 8*( 8 < str2num(cond)));
            trials(nt).ucs.msg               = ucs;
            trials(nt).oddball.msg           = odd;
            trials(nt).chain.msg             = chain;
            trials(nt).ctrial.msg            = ctrial;
            trials(nt).ttrial.msg            = ttrial;
            trials(nt).isref.msg             = isref;
            trials(nt).file.msg              = file;
            trials(nt).dref.msg              = dref;
            trials(nt).dcsp.msg              = dcsp;
            trials(nt).dFG.msg               = dFG;
            trials(nt).fxx.msg               = fxx;
            trials(nt).fxy.msg               = fxy;
        end
        %
        trials = rmfield(trials,{'StimOnset','StimOffset','FX','UCS','TRIALID','IMG','MODE'});
        dummy  = fixations(trials,info);
        %
        for fn = fieldnames(dummy)'
            if ~isfield(fixmat,fn{1})
                fixmat.(fn{1}) = [];
            end
            fixmat.(fn{1}) = [fixmat.(fn{1}) dummy.(fn{1})];
        end
        fixmat.rect = [400 800 600 1000];%[Y_start Y_stop X_start X_stop]
    end
    %remove out of frame fixations as well as oddball and ucs fixations
    fixmat = SelectFix(fixmat,'ucs',0,'oddball',0);
    save(filename,'fixmat');
else
    load(filename)
end
%% Compute Fixation Maps for each single subject and condition
% we create maps corrected with 3 different ways. The first one is the raw
% fixation maps, simple probability maps. The Second one is corrected
% within a given subject, by taking out the subject-specific average
% fixation map. This tell you in which conditions a given location is more
% fixated than the average. Across all conditions it sums to zero for a
% given subject. The Third way corrects by the global average, taken across
% all subjects. This tells you how much more or less a given location is
% fixated across all the subject group.
filename = '/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/midlevel/fixmaps.mat';
if ~exist(filename)
    map    = [];
    pp     = GetParameters('FWHM',20);
    nphase = 4;
    %
    for ns = unique(fixmat.subject)
        for cond = unique(fixmat.condition)
            fprintf('Processing: Subject: %d, Condition: %d\n',ns,cond);
            dummy               = fixmat2fixmap(fixmat,pp.kernel,0,1,'','subject',ns,'condition_aligned',cond,'phase',nphase);
            map{1}(:,cond,ns)   = Vectorize(dummy(401:800,601:1000));
        end
    end
    map{2}    = map{1} - repmat( mean(map{1},2) , [1 16 1] );
    map{3}    = map{1} - repmat( mean(mean(map{1},2),3) , [1 16 8] );
    save(filename,'map');
else
    load(filename)
end
%% plot subject specific fixation maps, here we exclude 2 because it sums to zero anyways. 
for n = [1 3]
    figure(n);
    set(gcf,'position',[ 5         -21        1676         955])
    clf
    imagesc(reshape(mean(map{n}(:,1:16,:),2),400,400*8));    
    axis image
    axis off
    colorbar
%     SaveFigure(sprintf('/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/figs/SubjectFixMat_%02d.png',n) ,'-r120');
end
%% compute how similar are different subjects? This is done by averaging the correlation across different conditions.
filename = '/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/midlevel/covmat_subjects.mat';
if ~exist(filename) | 1
    cmat_sub=[];
    for ntype = 1:3
        for conds = unique(fixmat.condition)
            cmat_sub{ntype}(:,:,conds) = corr(squeeze(map{ntype}(:,conds,:)));
        end
    end
    save(filename,'cmat_sub');
else
    load(filename);
end
%

for ntype = 1:3
    figure(ntype);    
    clf;
    imagesc(triu(mean(cmat_sub{ntype},3),1))
    axis square;
    colorbar
%     SaveFigure(sprintf('/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/figs/CovMat_subjects_%02d.png',ntype));
end
%% create a condition VS. subject matrix
for ntype = 1:3   
    %
    D = [];
    for ns = unique(fixmat.subject)
        D = [D ;reshape(map{ntype}(:,:,ns),400,400*16)];
    end
    figure(ntype);
    set(gcf,'position',[ 1776 -288 1550 893 ]);
    [d u] = GetColorMapLimits(D(:),[10]);
    imagesc(D,[d u]);
    colorbar;
    axis image;
    set(gca,'ytick',linspace(0,400*8,9),'ygrid','on','xtick',linspace(0,400*16,17),'xgrid','on','xticklabel',{'1' '2' '3' '4' '5' '6' '7' '8' '9' '10' '11' '12' '13' '14' '15' '16' ''} ,'yticklabel',{'1' '2' '3' '4' '5' '6' '7' '8' ''},'gridlinestyle','-')
    grid minor
end
%% Compute Covariance Matrices between Condition Maps for each subject separately
filename = '/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/midlevel/covmat_fixmat.mat';
if ~exist(filename)    
    for ntype = 1:3
        c_cond =  0;
        for conds = [1:8 ; 9:16]';
            c_cond = c_cond + 1;
            for ns = unique(fixmat.subject)
                cmat{ntype}{c_cond}(:,:,ns)  = cov(map{ntype}(:,conds,ns));
            end
        end
    end
    save(filename,'cmat');
else
    load(filename)
end
imagesc([mean(cmat{2}{1},3) mean(cmat{2}{2},3)]);colorbar
SaveFigure('/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/figs/CovMat_fixmats.png' ,'-r120');

%% induced across GS subjects DELETE
% % % sub = 0;
% % % r   = [];
% % % for ns = gs
% % %     sub = sub + 1;
% % %     induced_corrected_map = map(:,1:8,ns) - repmat(mean(map(:,1:8,ns),2),[1 8 1]);
% % %     r{1}(:,:,sub) = cov(induced_corrected_map);
% % %     induced_corrected_map = map(:,9:16,ns) - repmat(mean(map(:,9:16,ns),2),[1 8 1]);
% % %     r{2}(:,:,sub) = cov(induced_corrected_map);
% % % end
% % % figure;imagesc([mean(r{1},3) mean(r{2},3) (mean(r{1},3)+mean(r{2},3))/2]);colorbar;
% % % [y x] = meshgrid(linspace(0,2*pi-2*pi/8,8));
% % % y     = repmat(y,[1 1 length(gs)]);
% % % x     = repmat(x,[1 1 length(gs)]);
% % % xdata = [y(:) x(:)];
% % % 

%% fit a model without the gaussian component: DEPENDING ON WHICH CELL ABOVE YOU FIRST EXECUTE
%% THE R will be overwritten
ntype = 2;%type of fixation map normalization, within subject normalization is good because 
%it doesn't get corrupted by the shape of the global mean from other subjects.
c = 0;
for dummy = cmat{ntype}
    c = c +1;
    RSA                                 = mean(dummy{1},3);
    options                             = optimset('Display','iter','maxfunevals',10000,'tolX',10^-12,'tolfun',10^-12,'MaxIter',10000,'Algorithm','');
    [y x]                               = meshgrid(linspace(0,2*pi-2*pi/8,8));
    xdata                               = [y(:) x(:)];
    %% fit a model with the diagonal    
    dia = trace(RSA)/8;
    %the diagonal component
    x0                                  = dia;
    model_diag                          = @(x) sum((RSA(:) - CorrMatDecomposition([0 0 0 0 0 x],xdata)).^2);
    %
    figure(1);
    imagesc( reshape([CorrMatDecomposition([0 0 0 0 0 x0],X) Vectorize(RSA)],8,16) );
    figure(2)
    [o.Est, o.Likelihood, o.ExitFlag]   = fminsearch(model_diag , x0 , options);
    dia                                 = o.Est;
    imagesc( reshape([CorrMatDecomposition([0 0 0 0 0 dia],X)  Vectorize(mean(RSA,3))  CorrMatDecomposition([0 0 0 0 0 dia],X)-Vectorize(mean(RSA,3))],8,24) ) ;
    
    
    %% fit a model with the similarity model, i.e. without any gaussian
    
    ampc  = abs(max(RSA(:)) - min(RSA(:))) - dia;
    freq  = 1.1;
    %
    x0               = [ampc freq ];
    model_nogaussian = @(x) sum((RSA(:) - CorrMatDecomposition([x 0 0 0 dia],xdata)).^2);
    figure(1);
    imagesc( reshape([CorrMatDecomposition([x0 0 0 0 dia],X) Vectorize(mean(RSA,3))],8,16) ) ;
    figure(2)
    [o.Est, o.Likelihood, o.ExitFlag]   = fminsearch(model_nogaussian, x0, options);
    ampc = o.Est(1);
    freq = o.Est(2);
    phase= 0;
    imagesc( reshape([CorrMatDecomposition([ampc freq 0 0 0 dia],X)  Vectorize(mean(RSA,3))  CorrMatDecomposition([ampc freq 0 0 0 dia],X)-Vectorize(mean(RSA,3))],8,24) ) ;
    
    %% fit a model with the gaussian componenet
    %
    ampg             = std(CorrMatDecomposition([ampc freq 0 0 0 dia],X)-Vectorize(mean(RSA,3)));
    sigma            = 1.4;
    %
    x0               = [ampg sigma ];
    model_gaussian   = @(x) sum((RSA(:) - CorrMatDecomposition([ampc freq 0 x dia],xdata)).^2);
    figure(1);
    imagesc( reshape([CorrMatDecomposition([ampc freq 0 x0(1) x0(2) dia] , X) Vectorize(mean(RSA,3))],8,16) ) ;
    figure(2)
    [o.Est, o.Likelihood, o.ExitFlag]   = fminsearch(model_gaussian, x0,options);
    ampg             = o.Est(1);
    sigma            = o.Est(2);
    imagesc( reshape([CorrMatDecomposition([ampc freq 0 ampg sigma dia ],X) Vectorize(mean(RSA,3))   CorrMatDecomposition([ampc freq 0 ampg sigma dia ],X)-Vectorize(mean(RSA,3))],8,24) ) ;
    
    
    %%
    
    Params{c} = [ampc freq phase ampg sigma dia];
    %plot separately the similarity and generalization componenets
    figure
    imagesc( reshape([CorrMatDecomposition([0 0 0 0 0 dia],X) CorrMatDecomposition([ampc freq 0 0 0 0],X) CorrMatDecomposition([0 0 0 ampg sigma 0],X) Vectorize(mean(RSA,3))],8,32) ) ;
    
end

%% create a mask: mask values are: 
%0   : face
%255 : left eye
%182 : right eye
%53  : mouth
%87  : bg
%make mask human readable.
M           = rgb2gray(imread('/Users/onat/Documents/BehavioralExperiments/2013_10_feargen_ethno/figs/mask.png'));
M(M == 0)   = 1;%face
M(M == 255) = 2;%left eye
M(M == 182) = 3;%right eye
M(M == 53)  = 4;%mouthn
M(M == 87)  = 5;%bg
M.d = M;%the mask
M.label = {'face' 'left eye' 'right eye' 'mouth' 'bg'}
for nroi = 1:5;
    M.ind(:,nroi)   = double(M.d(:) == nroi);
end
M.ind = M.ind./repmat(sum(M.ind),size(M.ind,1),1);
% count fixation density
roi=[];
for ns = 1:8;
    roi(:,:,ns)=squeeze(map{2}(:,1:16,ns))'*M.ind(:,2:4);    
end
%
t = {'L.Eye' 'R.eye' 'Mouth'}
for nroi = 1:3
    subplot(3,1,nroi);
    bar(mean(roi(:,nroi,:),3));
    title(t{nroi});
    axis tight
    box off
end
%% compute entropy
for ns = 1:8
    for ncond = 1:16
        E(ncond,ns) = -nansum(map(:,ncond,ns).*log2(map(:,ncond,ns)));
    end
end
%% count number of fixations on different parts of the face for each
% condition
P = [];
for nphase = 4
    for ns = unique(fixmat.subject)
        for nface = unique(fixmat.condition_aligned)
            [ns nface]
            %
            i     = (fixmat.subject == ns) & (fixmat.phase == nphase) & (fixmat.condition_aligned == nface);
            %
            x     = round(fixmat.x(i) - fixmat.rect(3));
            y     = round(fixmat.y(i) - fixmat.rect(1));            
            %
            dummy = diag(M.d(y,x));
            for nroi = 1:5
                P(nroi,mod(nface-1,8)+1,ns) = sum(dummy == nroi);
            end
        end
        P(:,:,ns) = P(:,:,ns)./repmat(sum(P(:,:,ns)),5,1)*100;
    end
end







% compute the similarity of fixation maps and average
gs = [1 3 4 5 6 7];











