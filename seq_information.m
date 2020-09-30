function [out]=seq_information(s,isi,varargin)
%[out]=seq_information(s,isi,varargin)
%
%   Will spit out interesting information on the sequences S. Interesting
%   stuff are also shown as a figure. Assumes the last and last -1 are UCS
%   and oddballs, respectively. OUT contains all the information. 
%
%   If ISI is [], then a constant ISI is assumed. The jitter in this case
%   is implemented using null trials. However ISI can also be explicitely
%   given. This only matters for the measurements of efficiencies.
%
%   Use VARARGIN flag to turn off visualizations or verbose. [0 0]
%   no figure, no verbose, [1 0], only figure, [0 1] only vervose. Default
%   [1 1].
%
%   This version attempts to achieve sequence analysis independent of the
%   study.

verbose = 1;
fig     = 1;
if nargin > 2
    fig     = varargin{1}(1);
    verbose = varargin{1}(2);
end
%%set some constants
nummods = 10;%number of time bin in the FIR matrix
odd_id  = 10;
ucs_id  = 9;
null_id = 0;
%%
s = s(:);
tcond      = length(unique(s));%with the null event
tstimcond  = max(unique(s));%stimulus showing conditions i.e. without the null
conds      = 0:tstimcond;
out.ttrial = length(s);
if verbose
    fprintf('\n\n\n\n\n');
    fprintf('Total trial: %g\n',out.ttrial);
    fprintf('%g and %g are considered as UCS and oddball, respectively\n',ucs_id,odd_id);
    fprintf('Probability of different conditions:\n');
end
count     = zeros(1,tstimcond);
for c = 1:tcond
    count(c) = sum(s == conds(c));
    if verbose
        fprintf('Cond %g: %g (%g)\n',conds(c),count(c),count(c)./out.ttrial);
    end
end

ucs     = sum(s == ucs_id);
csp     = sum(s == 2);
out.rr  = ucs./(ucs+csp)*100;

odd     = sum(s == odd_id);
out.or  = odd./out.ttrial*100;
if verbose
    fprintf('=====================================\n');
    fprintf('RRei: %g percent.\n',out.rr);
    fprintf('=====================================\n');
    fprintf('ROdd: %g percent.\n',out.or);
    fprintf('=====================================\n');    
end
%%
fprintf('Transition Check\n');
n                      = hist3([s(1:end-1) s(2:end)],{conds conds});
[dummy_eff  dummy_det] = calc_meffdet(s, 10 , tstimcond, 3);
[~,~,max_det,max_eff]  = tcurve(tstimcond,10,length(s));
tmaxeff                = out.ttrial/(2*(tcond)*10);
eff_norm               = dummy_eff(1)./max_eff(1);
if verbose
    fprintf('=====================================\n');
    fprintf('Efficiency: %g\n',dummy_eff(1));
    fprintf('Max efficiency: %g\n',tmaxeff);
    fprintf('Normalized efficiency: %g percent\n',eff_norm(1)*100 );
    fprintf('Power: %g\n',dummy_det(1));
    fprintf('Normalized power: %g\n',dummy_det(1)/max_det(1)*100);
    fprintf('=====================================\n');
    for isis = [1 2.5 3 6]
        fprintf('Expected duration: ISI of %g s -> %g minutes..\n',isis,isis*out.ttrial/60);
    end
end
%% compute second-order optimality.
fprintf('=====================================\n');
fprintf('=====================================\n');
sopt = seq_SecondOrderBalanceOptimality(s);
fprintf('If this sequence was randomized, it would have a ');
seq_SecondOrderBalanceOptimality(Shuffle(s));
fprintf('And if the sequence was sorted, it would be ');
seq_SecondOrderBalanceOptimality(sort(s));
fprintf('=====================================\n');
fprintf('=====================================\n');
fprintf('=====================================\n');
%% compute design efficiency, this is taken from:
% Experimental Design: Efficiency,
% Coding, and Choice Designs Warren F. Kuhfeld

if isempty(isi)
    isi = ones(length(s),1)*3;
end
dm             = seq_designmatrix(s,isi);
dm             = dm(:,1:8);

max_efficiency = 1./trace(inv(diag(sum(dm))));
fprintf('The maximum efficiency is %g...\n',max_efficiency);
efficiency     = 1./(trace(inv(dm'*dm)));
fprintf('Efficiency of this design is %g (%g percent)...\n',efficiency,100*efficiency./max_efficiency);
out.dm = dm;
fprintf('=====================================\n');
fprintf('=====================================\n');
fprintf('=====================================\n');
%% get the FIR matrix and efficiencies
try
[X,CX]          = seq_seq2fir(s,nummods);
[effmat]        = calc_meffdet(s,nummods,tstimcond,eye(out.ttrial));
[~,~,~,tmaxeff] = tcurve(tstimcond,nummods,out.ttrial,0);
[~, v]          = eig(CX(1:(tstimcond-2)*nummods,1:(tstimcond-2)*nummods));
end
%% compute also the entropies
out.ent_order = 1:5;
for order = 1:5
    [out.ent(order),out.ent0,out.entmax] = calcent(s,order);
end
%% viz stuff.
if fig
    figure(1000);
    clf;
    nr = 4;
    nc = 4;
    %
    subplot(nr,nc,1:3);
    plot(s,'.-','markersize',10);hold on;
    plot(find(s == ucs_id),s(s == ucs_id),'+r','markersize',10);
    plot(find(s == odd_id),s(s == odd_id),'sg','markersize',10);
    xlabel('trials')
    set(gca,'ytick',0:tstimcond,'yticklabel',{'N' '1' '2' '3' '4' '5' '6' '7' '8' 'UCS' 'ODD'})
    grid on;
    title(sprintf('the sequence (length: %g, duration: %3.3g m (ISI:3s))',out.ttrial,3*out.ttrial/60))
    box off
    hold off;
    ylim([0 tstimcond+1])
    %
    subplot(nr,nc,4);
    imagesc(n);
    colormap jet
%     thincolorbar('vertical');
    title(sprintf('2nd order Transition Matrix (%g)',sopt));
    set(gca,'ytick',1:tstimcond+1,'yticklabel',{'N' '1' '2' '3' '4' '5' '6' '7' '8' 'UCS' 'ODD'})
    set(gca,'xtick',1:tstimcond+1,'xticklabel',{'N' '1' '2' '3' '4' '5' '6' '7' '8' 'U' 'O'})
    %
    subplot(nr,nc,5)
    imagesc(X);colormap('jet');
    title('FIR matrix')
    set(gca,'xtick',[],'ytick',[])
    xlabel('conditions');ylabel('trials')
    %
    subplot(nr,nc,6)
    bar([1./mean(effmat(2:tstimcond)) ;1./effmat(2:tstimcond+1)],'k')
    hold on
    plot(xlim,[tmaxeff tmaxeff],'r--')
    ylim([0 tmaxeff]*1.5);
    xlim([0 tstimcond+1+1])
    box off
    xlabel('conditions');
    ylabel('efficiency');
    set(gca,'xticklabel',{'All' '1' '2' '3' '4' '5' '6' '7' '8' 'U' 'O'})
    title(sprintf('Eff. of estimation(%2.4g %% ) ',1./mean(effmat(2:tstimcond))/tmaxeff*100))
    hold off
    %
    subplot(nr,nc,7)
    bar(1./effmat(tstimcond+2:end),'k')
    hold on;
    plot(xlim,[tmaxeff tmaxeff],'r--');
    hold off
    title('Eff. of contrasts')
    axis tight;
    ylim(ylim*1.5);
    xlim([0 length(effmat)-tstimcond] );
    box off;
    %
    subplot(nr,nc,8)
    bar([0 out.ent_order]+1, [ out.ent0 out.ent],'k')
    hold on
    xlabel('n^{th} order')
    ylabel('entropy')
    box off
    axis tight;
    plot(xlim,[out.entmax out.entmax],'r--')
    ylim(ylim*1.2);
    title('entropy')
    grid on;
    %
    subplot(nr,nc,9)
    imagesc(cov(X));
%     thincolorbar('vertical');
    title(sprintf('covariance (rank: %g (%g))',rank(cov(X)),size(X,2)));axis off;
    %
    try
        subplot(nr,nc,10)
        plot(diag(v),'ok-')
        title('Eigenvalue spectrum')
        box off;
    end
    %
    subplot(nr,nc,11)    
    if length(unique(isi)) > 1
       hist(isi);
    else
       hist(diff(find(s ~= 0)));
    end    
    title('Distribution of ISIs')
    box off;    
    %
    subplot(nr,nc,13)
    [e v] = eig(inv(dm'*dm));
    bar(diag(v))    
    title(sprintf('ev of the dm'));    
    %
    subplot(nr,nc,14)
    imagesc(dm);
    colormap gray
    title(sprintf('design matrix eff(max):\n %2.2g(%2.2g))',efficiency,max_efficiency));
    box off;    
    axis tight;
end
%% create output
out.eff_overall   = 1./mean(effmat(2:tstimcond));
out.eff_estimate  = 1./effmat(2:tstimcond+1);
out.eff_contrasts = 1./effmat(tstimcond+2:end);
out.eff_max       = tmaxeff;
out.eff_norm      = out.eff_overall./out.eff_max*100;
out.probability   = count./out.ttrial;
