function [fitresult, data] = exp_fearadapt_makeindstim(subject)


%take subject number
%data
%data - sub001
%data - sub001 - stim
%data - sub001 - pmf
%data - sub001 - exp
[~, hostname] = system('hostname');
hostname                    = deblank(hostname);
if strcmp(hostname,'isn3464a9d59588')
    baselocation       = 'C:\Users\Lea\Documents\Experiments\';
elseif strcmp(hostname,'blab0')
    baselocation       = 'U:\kampermann\';
else
    keyboard;
end
addpath([baselocation 'Palamedes_1_8_2\Palamedes\']);
addpath([baselocation 'psignifit\']);


subpath          = [baselocation 'FearAdapt_Pilote\' 'data\' sprintf('sub%02d',subject) '\discr\'];
%create folder hierarchy
mkdir([subpath 'fit']);
p = load([subpath '\stimulation\p.mat']);p=p.p;
% get saved pmf info from discrimination experiment
rho_ind    = [];
meantheta  = [];
wmeantheta = [];
result_pal = [];
data       = [];
result_psi = [];

fit_pal = 1;
fit_psi = 0;
%% fit PMF using PAL. Why not. PAL_logistic
PF = @PAL_Logistic;
crit = .75;
%define delta as different in rho from comparison to standard (CS)
deltas=[0 0.05 0.075 0.10 0.15];
%or
deltas = unique(p.presentation.delta);


%combine +/- trials for each delta value, separately for each standard (CS)
dc = 0;
for d = deltas(:)'
    dc=dc+1;
    chain1 = p.presentation.nCS == 1;
    chain2 = p.presentation.nCS == 2;
    d_ind  = p.presentation.delta == d;
    datCS1(dc,:) = [d sum(p.psi.log.response(logical(chain1.*d_ind))) sum(chain1.*d_ind)];
    datCS2(dc,:) =  [d sum(p.psi.log.response(logical(chain2.*d_ind))) sum(chain2.*d_ind)];
end
if fit_pal == 1
fprintf('Starting to fit the 2 PMFs...')
out_CS1 = fit_pmf_pal(datCS1);
out_CS2 = fit_pmf_pal(datCS2);
fprintf('done.\n')

result_pal.CS1 = out_CS1;
result_pal.CS2 = out_CS2;
data.CS1 = datCS1;
data.CS2 = datCS2;
theta1 = PF(out_CS1.params,.75,'inverse');
theta2 = PF(out_CS2.params,.75,'inverse');
result_pal.theta1 = theta1;
result_pal.theta2 = theta2;
result_pal.crit = crit;
%FIGURE
fg=figure;
subplot(2,2,1);plot_pmf(datCS1,out_CS1,theta1);
subplot(2,2,2);plot_pmf(datCS2,out_CS2,theta2);

meantheta = mean([theta1 theta2]); result_pal.thetamean = meantheta;
end
% % fg.Position = [400 200 700 450];
% % st = supertitle(sprintf('Fit for Sub:%02d, Theta_{ave} = %04.3f.',subject,meantheta));set(st,'FontSize',16)
% pause
% fprintf('Paused. Check fit and press any button to continue.\n')
% % % pause
% % cd([subpath 'fit'])
% % print(fg,sprintf('fit_PAL_sub%02d',subject),'-dpng');
% 
% fprintf('Saving fit and data at %s.\n',[subpath 'fit'])
% save([subpath 'fit\' sprintf('fit_sub%02d.mat',subject)],'fitresult','data')
% fprintf('DONE.\n')
% %calculate weighted mean of the two theta, i.e. alphas
% CIthetaCS1=diff(sCS1.conf_Intervals(1,:));
% CIthetaCS2=diff(sCS2.conf_Intervals(1,:));
%
% %calculate weighted mean of the two 75% thresholds for use in main expr
% meanTheta= ((1/CIthetaCS1)/(1/CIthetaCS1 + 1/CIthetaCS2))*thetaCS1 + ((1/CIthetaCS2)/(1/CIthetaCS1 + 1/CIthetaCS2))*thetaCS2;

%% fit psychometric function for each CS separately using psignifit (logistic sigmoid)  NORBURY COPY
if fit_psi == 1
datCS1_psi = datCS1; datCS1_psi(:,2)=datCS1_psi(:,2)./datCS1_psi(:,3);
datCS2_psi = datCS2; datCS2_psi(:,2)=datCS2_psi(:,2)./datCS2_psi(:,3);

out_psi_CS1 = fit_pmf_psigni(datCS1_psi);
out_psi_CS2 = fit_pmf_psigni(datCS2_psi);

thetaCS1 = out_psi_CS1.Fit(1);
thetaCS2 = out_psi_CS2.Fit(1);

CS1_conf68 = out_psi_CS1.conf_Intervals(1,:,3); %1st param, last confInt def (68%)
CS2_conf68 = out_psi_CS2.conf_Intervals(1,:,3);

CIthetaCS1=CS1_conf68(2)-CS1_conf68(1);
CIthetaCS2=CS2_conf68(2)-CS2_conf68(1);

out_psi_CS1.theta.mean=thetaCS1;
out_psi_CS1.theta.CI=CIthetaCS1;
out_psi_CS2.theta.mean=thetaCS2;
out_psi_CS2.theta.CI=CIthetaCS2;

%calculate weighted mean of the two 75% thresholds for use in main expr
wmeantheta = ((1/CIthetaCS1)/(1/CIthetaCS1 + 1/CIthetaCS2))*thetaCS1 + ((1/CIthetaCS2)/(1/CIthetaCS1 + 1/CIthetaCS2))*thetaCS2;

result_psi.wmeantheta = wmeantheta;
% out.CS1 = out_psi_CS1; %This is waaaay to big, we can't take that thing with us.
% out.CS2 = out_psi_CS2;
result_psi.CS1 = IndexedStructCopy(out_psi_CS1,{'logPmax','Fit','options','data','conf_Intervals','theta'});
result_psi.CS2 = IndexedStructCopy(out_psi_CS2,{'logPmax','Fit','options','data','conf_Intervals','theta'});
result_psi.thetaCS1 = thetaCS1;
result_psi.thetaCS2 = thetaCS2;
result_psi.CIthetaCS1 = CIthetaCS1;
result_psi.CIthetaCS2 = CIthetaCS2;
clear out_psi_CS1 out_psi_CS2 %too big

%FIGURE
subplot(2,2,3);plot_pmf_psi(datCS1_psi,result_psi.CS1);
subplot(2,2,4);plot_pmf_psi(datCS2_psi,result_psi.CS2);
end

fg.Position = [400 200 700 450];
fg.Color = [1 1 1]; %white bg
% st = supertitle(sprintf('Fit for Sub:%02d, Theta_{PAL} = %04.3f. Theta_{PSI} = %04.3f.',subject,meantheta,wmeantheta));set(st,'FontSize',16,'Position',[.028 .55 0])
% fprintf('Paused. Check fit and press any button to continue.\n')
% pause
cd([subpath 'fit'])
print(fg,sprintf('fit_sub%02d',subject),'-dpng'); close all;

fprintf('Saving fit and data at %s.\n',[subpath 'fit'])
save([subpath 'fit\' sprintf('fit_sub%02d.mat',subject)],'result_pal','data','result_psi')
fprintf('DONE.\n')

%%
if fit_psi == 1
    final_theta = wmeantheta;
else
    final_theta = meantheta;
end
fprintf('Making Stimuli.');
make_stim(final_theta);
cd(baselocation)

    function out = fit_pmf_pal(data)
        % define a search grid
        xlevels = data(:,1);
        searchGrid.alpha  = linspace(0,max(data(:,1)),10);    %structure defining grid to
        searchGrid.beta   = 10.^[-1:0.1:10];         %search for initial values
        searchGrid.gamma  = linspace(0,0.5,10);
        searchGrid.lambda = linspace(0,0.1,10);
        paramsFree        = [1 1 1 1];
        options                      = PAL_minimize('options');
        options.MaxIter              = 10.^3;
        options.MaxFunEvals          = 10.^3;
        options.Display              = 'On';
        options.ToX                  = -10.^3;
        options.TolFun               = -10.^3;
        xlevels_HD                   = linspace(min(data(:,1)),max(data(:,1)),100);
        
        %fit the function using PAL
        [params, LL, exitflag,output]       = PAL_PFML_Fit(data(:,1), data(:,2), data(:,3), searchGrid, paramsFree, PF,'lapseLimits',[0 .2],'guessLimits',[0 .5]);
        out.params        = params;
        out.LL             = LL;
        out.exitflag       = exitflag;
        out.y              = PF(params,xlevels_HD);
        out.xHD            = xlevels_HD;
        out.x              = xlevels;
        out.PF             = PF;
    end
    function out = fit_pmf_psigni(data)
        options=struct;
        options.sigmoidName    = 'logistic';
        options.threshPC       = .75;
        options.CImethod       = 'percentiles'; %'project' %'stripes'
        options.estimateType   = 'MAP';
        out = psignifit(data,options);
    end
    function plot_pmf_psi(data,psiout)
        xsteps   = data(:,1);
        NumPos   = data(:,2).*data(:,3);
        OutOfNum = data(:,3);
        pdiff    = NumPos./OutOfNum;
        var_pdiff= (OutOfNum.*NumPos./OutOfNum.*(1-NumPos./OutOfNum))./OutOfNum;%var of binomial distr. (np(1-p))
        
         if strcmp(hostname,'blab0')
            scatter(xsteps,pdiff,120,'MarkerEdgeColor','k','MarkerFaceColor',[.3 .3 .3]);
        else
            scatter(xsteps,pdiff,120,'MarkerEdgeColor','k','MarkerFaceColor','k','MarkerFaceAlpha',.3);
        end
        hold on;
        errorbar(xsteps,pdiff,var_pdiff,'.','markersize',8,'color','k','LineWidth',2);
        
        
        %plot the fits
        hold on
        xlength   = max(psiout.data(:,1))-min(psiout.data(:,1));
        x         = linspace(min(psiout.data(:,1)),max(psiout.data(:,1)),1000);
        fitValues = (1-psiout.Fit(3)-psiout.Fit(4))*arrayfun(@(x) psiout.options.sigmoidHandle(x,psiout.Fit(1),psiout.Fit(2)),x)+psiout.Fit(4);

        plot(x,fitValues,'color','r','linewidth',3);
        axis tight;box off;axis square;ylim([-0.1 1.2]);xlim([-.01 .17]);drawnow;
        hold on;plot(xlim,[0 0 ],'k-');
        plot(xlim,[0.5 0.5],'k:');plot(xlim,[1 1 ],'k-');%plot grid lines
%         plot([psiout.Fit(1) psiout.Fit(1)],[0 1],'LineStyle',':','LineWidth',1,'color','k'); %plot PF's default threshold
        
        %plot theta
        line([psiout.Fit(1) psiout.Fit(1)],[0 1],'LineWidth',2)
        line(xlim,[crit crit],'LineWidth',2);
        %plot CI as shaded area
        area(psiout.conf_Intervals(1,:,1),[1 1],'FaceColor',[0 114 189]./255,'FaceAlpha',.3,'EdgeColor','none')
        text(.12,.25,sprintf('theta = %04.3f\n LL = %04.2f.',psiout.Fit(1),psiout.logPmax));
        set(gca,'FontSize',14);
        set(gcf,'Color','w')
%         tt=title(sprintf('theta = %04.3f, LL = %04.2f.',psiout.Fit(1),psiout.logPmax));set(tt,'FontSize',12);
    end
    function plot_pmf(data,fit,theta)
        xsteps   = data(:,1);
        NumPos   = data(:,2);
        OutOfNum = data(:,3);
        pdiff    = NumPos./OutOfNum;
        var_pdiff= (OutOfNum.*NumPos./OutOfNum.*(1-NumPos./OutOfNum))./OutOfNum;%var of binomial distr. (np(1-p))
        
        if strcmp(hostname,'blab0')
            scatter(xsteps,pdiff,120,'MarkerEdgeColor','k','MarkerFaceColor',[.3 .3 .3]);
        else
            scatter(xsteps,pdiff,120,'MarkerEdgeColor','k','MarkerFaceColor','k','MarkerFaceAlpha',.3);
        end
            hold on;
            errorbar(xsteps,pdiff,var_pdiff,'.','markersize',8,'color','k','LineWidth',2);
            
            
        %plot the fits
        hold on
        plot(fit.xHD,fit.y,'color','r','linewidth',3);
        axis tight;box off;axis square;ylim([-0.1 1.2]);xlim([-.01 .17]);drawnow;
        hold on;plot(xlim,[0 0 ],'k-');plot(xlim,[0.5 0.5],'k:');plot(xlim,[1 1 ],'k-');%plot grid lines
        plot([fit.params(1) fit.params(1)],[0 1],'LineStyle',':','LineWidth',1,'color','k'); %plot PF's default threshold
        
        %plot theta
        line([theta theta],[0 1],'LineWidth',2)
        line(xlim,[crit crit],'LineWidth',2);
        text(.12,.25,sprintf('theta = %04.3f\n LL = %04.2f.',theta,fit.LL));
        set(gca,'FontSize',14);
        set(gcf,'Color','w')
%         tt=title(sprintf('theta = %04.3f, LL = %04.2f.',theta,fit.LL));set(tt,'FontSize',12);
    end
    function make_stim(theta)
        path2print = strrep(subpath,'discr','exp\stim');
        fprintf('Target folder for stimuli is %s.\n',path2print);
        if ~exist(path2print)
            mkdir(path2print)
        end
        % for CS = 1:nCS
        %     for drho = delta_rho(:)'
        %         q = gen_shape(rhoCSs(CS)+drho,nSpikes,R);
        %         print(q,sprintf('CSplus%d_p%03d',CS,drho*1000),'-dpng');
        %         %         sprintf('CSplus%d_p%03d',CS,drho*1000)
        %         close all;
        %         if drho>0
        %             q = gen_shape(rhoCSs(CS)-drho,nSpikes,R);
        %             print(q,sprintf('CSplus%d_n%03d',CS,drho*1000),'-dpng');
        %             %                 sprintf('CSplus%d_n%03d',CS,drho*1000)
        %         end
        %     end
        % end
        % end
        
        
        %DEFINE STIMULI: cf NORBURY
        rhoCSplus1=0.25;
        rhoCSplus2=0.75;
        rhoCSplus1pTheta=rhoCSplus1 + theta;
        rhoCSplus1nTheta=rhoCSplus1 - theta;
        rhoCSplus2pTheta=rhoCSplus2 + theta;
        rhoCSplus2nTheta=rhoCSplus2 - theta;
        rhoCSminus=rhoCSplus2-2*theta;
        
        %randomly reflect spikiness axis for half ppts and record
        i=rand;
        if i>0.5
            switch_spike = 1;
            rhoCSplus1=1-rhoCSplus1;
            rhoCSplus2=1-rhoCSplus2;
            rhoCSplus1pTheta=1-rhoCSplus1pTheta;
            rhoCSplus1nTheta=1-rhoCSplus1nTheta;
            rhoCSplus2pTheta=1-rhoCSplus2pTheta;
            rhoCSplus2nTheta=1-rhoCSplus2nTheta;
            rhoCSminus=1-rhoCSminus;
        else
            switch_spike = 0;
        end
        
        rhos=[rhoCSplus1nTheta rhoCSplus1 rhoCSplus1pTheta rhoCSminus rhoCSplus2nTheta rhoCSplus2 rhoCSplus2pTheta];
        stiminfo.rhos = rhos;
        stiminfo.switch_spike = switch_spike;
        stiminfo.theta = theta;
        fprintf('Saving stiminfo.mat at %s.\n',path2print)
        save([path2print 'stiminfo.mat'],'stiminfo');
        
        %GENERATE STIMULI:
        nSpikes=5; R=12.5;
        cd(path2print);
        fprintf('Generating stimuli...') %we add the ID_ here so that it will be loaded into the filematrix in exp_fearadapt_main correctly.
        q=gen_shape(rhoCSplus1,nSpikes,R); print(q,'2_CSplus1','-dpng'); close all;
        q=gen_shape(rhoCSplus2,nSpikes,R); print(q,'3_CSplus2','-dpng'); close all;
        q=gen_shape(rhoCSminus,nSpikes,R); print(q,'1_CSminus','-dpng'); close all;
        q=gen_shape(rhoCSplus1nTheta,nSpikes,R); print(q,'4_CSplus1nTheta','-dpng'); close all;
        q=gen_shape(rhoCSplus1pTheta,nSpikes,R); print(q,'5_CSplus1pTheta','-dpng'); close all;
        q=gen_shape(rhoCSplus2nTheta,nSpikes,R); print(q,'6_CSplus2nTheta','-dpng'); close all;
        q=gen_shape(rhoCSplus2pTheta,nSpikes,R); print(q,'7_CSplus2pTheta','-dpng'); close all;
        fprintf('done.\n')
        cd(subpath)
    end
    function q = gen_shape(rho, nSpikes, R)
        
        %%GEN_SHAPE is function to generate perceptually linear 'spiky' shapes parameterised by
        % spikiness parameter rho, number of spikes, and full shape radius R, as
        % defined in van Dam & Ernst (2015), PloS Comp Biol
        % (https://doi.org/10.1371/journal.pcbi.1004172)
        %   set 'spikiness' rho param using values between 0.01 and 1 [surface area is constant]
        %   in vD & E, nSpikes=5, and R=12.5(mm)
        
        
        %%define outer (r_o) and inner (r_i) radii based on shape param rho
        if rho<1
            r_o = R * sqrt( (2*log(rho)) / (rho^2 - 1) );
        else
            r_o = R;
        end
        r_i = rho * r_o;
        
        
        %%draw shape based distance from centre of polar coordinates:
        theta_i=1;
        theta_o=theta_i + (360/(2*nSpikes));
        
        for a=1:nSpikes
            
            for theta_deg = theta_i:theta_o
                
                r_deg(theta_deg) = r_i * exp( (theta_deg - theta_i)/(theta_i - theta_o) * log(r_i/r_o) );
                
            end
            
            theta_i = theta_i + (360/nSpikes);
            
            for theta_deg = theta_o:theta_i
                
                r_deg(theta_deg) = r_i * exp( (theta_deg - theta_i)/(theta_i - theta_o) * log(r_i/r_o) );
                
            end
            
            theta_o=theta_o + (360/nSpikes);
            
        end
        
        theta = (1:length(r_deg)).*(pi/180);
        r = r_deg.*(pi/180);
        
        q=figure;
        set(q,'Resize','off')
        p=polar(theta, r);
        
        ax=gca;
        %set(ax,'Position',[0.,0,0.55,0.55])
        %set(ax,'XlimMode','manual')
        set(ax,'Ylim',[-0.5,0.5])
        
        z = findall(gcf,'type','patch');
        z(q == z) = [];
        delete(z);
        
        set(p, 'Color', [0.5 0.5 0.5])
        j=patch(get(p,'XData'), get(p,'YData'), [0 0.8 0.8]);
        set(j, 'LineStyle', 'none')
        
        h = findall(gcf,'type','line');
        h(h == q) = [];
        delete(h);
        
        t = findall(gcf,'type','text');
        delete(t);
        
        
    end
    function T = IndexedStructCopy(S, FieldList) %adapted from https://de.mathworks.com/matlabcentral/answers/405944-how-do-i-extract-subset-of-all-fields-from-structure
        if nargin == 1 
            FieldList = fieldnames(S);
        end
        for iField = 1:numel(FieldList)
            Field    = FieldList{iField};
            T.(Field) = S.(Field);
        end
    end
end

% %% OLD STUFF
% % datCS1 = [        0    0.0000   16.0000;...
% %     0.0500    3.0000   16.0000;...
% %     0.0750    9.0000   16.0000;...
% %     0.1000    12.0000   16.0000;...
% %     0.1500   14.0000   16.0000];
% % datCS2 = [        0    0.0000   16.0000;...
% %     0.0500    4.0000   16.0000;...
% %     0.0750    6.0000   16.0000;...
% %     0.1000    12.0000   16.0000;...
% %     0.1500   14.0000   16.0000];
% %
% %combine +/- trials for each delta value, separately for each standard (CS)
% CSplus1d0=TaskDataTest(TaskDataTest(:,2)<10 & TaskDataTest(:,4)==deltas(1),:);
% CSplus1d05=TaskDataTest(TaskDataTest(:,2)<10 & TaskDataTest(:,4)==deltas(2),:);
% CSplus1d075=TaskDataTest(TaskDataTest(:,2)<10 & TaskDataTest(:,4)==deltas(3),:);
% CSplus1d10=TaskDataTest(TaskDataTest(:,2)<10 & TaskDataTest(:,4)==deltas(4),:);
% CSplus1d15=TaskDataTest(TaskDataTest(:,2)<10 & TaskDataTest(:,4)==deltas(5),:);
%
% CSplus2d0=TaskDataTest(TaskDataTest(:,2)>=10 & TaskDataTest(:,4)==deltas(1),:);
% CSplus2d05=TaskDataTest(TaskDataTest(:,2)>=10 & TaskDataTest(:,4)==deltas(2),:);
% CSplus2d075=TaskDataTest(TaskDataTest(:,2)>=10 & TaskDataTest(:,4)==deltas(3),:);
% CSplus2d10=TaskDataTest(TaskDataTest(:,2)>=10 & TaskDataTest(:,4)==deltas(4),:);
% CSplus2d15=TaskDataTest(TaskDataTest(:,2)>=10 & TaskDataTest(:,4)==deltas(5),:);
%
% %compile data in appropriate format [value, proportion judged different, ntrials]
% datCS1 = [deltas(1) nanmean(CSplus1d0(:,13)) length(CSplus1d0(:,1))-sum(isnan(CSplus1d0(:,11)));
%           deltas(2) nanmean(CSplus1d05(:,13)) length(CSplus1d05(:,1))-sum(isnan(CSplus1d05(:,11)));
%           deltas(3) nanmean(CSplus1d075(:,13)) length(CSplus1d075(:,1))-sum(isnan(CSplus1d075(:,11)));
%           deltas(4) nanmean(CSplus1d10(:,13)) length(CSplus1d10(:,1))-sum(isnan(CSplus1d10(:,11)));
%           deltas(5) nanmean(CSplus1d15(:,13)) length(CSplus1d15(:,1))-sum(isnan(CSplus1d15(:,11)))];
%
% datCS2 = [deltas(1) nanmean(CSplus2d0(:,13)) length(CSplus1d0(:,1))-sum(isnan(CSplus2d0(:,11)));
%           deltas(2) nanmean(CSplus2d05(:,13)) length(CSplus1d05(:,1))-sum(isnan(CSplus2d05(:,11)));
%           deltas(3) nanmean(CSplus2d075(:,13)) length(CSplus1d075(:,1))-sum(isnan(CSplus2d075(:,11)));
%           deltas(4) nanmean(CSplus2d10(:,13)) length(CSplus1d10(:,1))-sum(isnan(CSplus2d10(:,11)));
%           deltas(5) nanmean(CSplus2d15(:,13)) length(CSplus1d15(:,1))-sum(isnan(CSplus2d15(:,11)))];
%
%       %
% options = struct;
% options.sigmoidName    = 'logistic';
% options.threshPC       = .75;
% options.confP          = .68;
%
%
% sCS1=psignifit(datCS1,options);
% sCS2=psignifit(datCS2,options);
% figure;subplot(1,2,1);plotPsych(sCS1);subplot(1,2,2);plotPsych(sCS2)
% thetaCS1 = sCS1.Fit(1);
% thetaCS2 = sCS2.Fit(1);
% %+/- 1SD interval on threshold at 0.75 of sigmoid (~=0.75% performance)
% CIthetaCS1=diff(sCS1.conf_Intervals(1,:));
% CIthetaCS2=diff(sCS2.conf_Intervals(1,:));
%
% %calculate weighted mean of the two 75% thresholds for use in main expr
% meanTheta= ((1/CIthetaCS1)/(1/CIthetaCS1 + 1/CIthetaCS2))*thetaCS1 + ((1/CIthetaCS2)/(1/CIthetaCS1 + 1/CIthetaCS2))*thetaCS2;
%
%
%
% %generate test stimuli for psychometric discrimination task
% cd(subfolder);
% mkdir('stim')
% cd('stim')
% R = 12.5; %radius
% nSpikes=5; % number of spikes
% rhoCSplus1 = .25; % rho of 1st CS+
% delta_rho = [0 .05 .075 .1 .15];
%
% for CS = 1:nCS
%     for drho = delta_rho(:)'
%         q = gen_shape(rhoCSs(CS)+drho,nSpikes,R);
%         print(q,sprintf('CSplus%d_p%03d',CS,drho*1000),'-dpng');
%         %         sprintf('CSplus%d_p%03d',CS,drho*1000)
%         close all;
%         if drho>0
%             q = gen_shape(rhoCSs(CS)-drho,nSpikes,R);
%             print(q,sprintf('CSplus%d_n%03d',CS,drho*1000),'-dpng');
%             %                 sprintf('CSplus%d_n%03d',CS,drho*1000)
%         end
%     end
% end
% end
%
% a=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_1.mat');C(1,:)=histc(a.TestTrialMatrix,1:9)
% b=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_2.mat');C(2,:)=histc(b.TestTrialMatrix,1:9)
% c=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_3.mat');C(3,:)=histc(c.TestTrialMatrix,1:9)
% d=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_4.mat');C(4,:)=histc(d.TestTrialMatrix,1:9)
% e=load('C:\Users\Lea\Documents\Documents\FearAdapt\Norbury_Paper\avoidance task MRI\TestTrialMatrix_1_5.mat');C(5,:)=histc(e.TestTrialMatrix,1:9)