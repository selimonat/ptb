function [out]=seq_feargen_information(s,varargin)
%[out]=seq_feargen_information(s,varargin)
%
%   Will spit out interesting information on the sequences S. Interesting
%   stuff are also shown as a figure. Assumes the last and last -1 are UCS
%   and oddballs, respectively. OUT contains all the information. Use
%   VARARGIN flag to turn off visualizations or verbose. [0 0]
%   no figure, no verbose, [1 0], only figure, [0 1] only vervose. Default
%   [1 1].
%
%

verbose = 1;
fig     = 1;
if nargin > 1
    fig     = varargin{1}(1);
    verbose = varargin{1}(2);
end

nummods = 10;%number of time bin in the FIR matrix
s = s(:);
tcond     = 11;%with the null event
tstimcond = 10;
conds     = 0:tstimcond;
out.ttrial    = length(s);
if verbose
    fprintf('\n\n\n\n\n');
    fprintf('Total trial: %g\n',out.ttrial);
    fprintf('Probability of different conditions:\n');
end
count     = zeros(1,tstimcond);
for c = 1:tcond
    count(c) = sum(s == conds(c));
    if verbose
        fprintf('Cond %g: %g (%g)\n',conds(c),count(c),count(c)./out.ttrial);
    end
end

ucs     = sum(s == tstimcond-1);
csp     = sum(s == 1);
out.rr      = ucs./(ucs+csp)*100;

odd     = sum(s == (tstimcond));
out.or      = odd./out.ttrial*100;
if verbose
    fprintf('=====================================\n');
    fprintf('RRei: %g percent.\n',out.rr);
    fprintf('=====================================\n');
    fprintf('ROdd: %g percent.\n',out.or);
    fprintf('=====================================\n');
    fprintf('Transition Check\n');
end
n       = hist3([s(1:end-1) s(2:end)],{conds conds});
[dummy_eff  dummy_det] = calc_meffdet(s, 10 , tstimcond, 3);
[~,~,max_det,max_eff]  = tcurve(tstimcond,10,length(s));
tmaxeff = out.ttrial/(2*(tcond)*10);
eff_norm    = dummy_eff(1)./max_eff(1);
if verbose
    fprintf('=====================================\n');
    fprintf('Efficiency: %g\n',dummy_eff(1));
    fprintf('Max efficiency: %g\n',tmaxeff);
    fprintf('Normalized efficiency: %g percent\n',eff_norm(1)*100 );
    fprintf('Power: %g\n',dummy_det(1));
    fprintf('Normalized power: %g\n',dummy_det(1)/max_det(1)*100);
    fprintf('=====================================\n');
    for isis = [1 2.5 3 3.5]
        fprintf('Expected duration: ISI of %g s -> %g minutes..\n',isis,isis*out.ttrial/60);
    end
end
%% get the FIR matrix and efficiencies
[X,CX]          = seq_seq2fir(s,nummods);
[effmat]        = calc_meffdet(s,nummods,tstimcond,eye(out.ttrial));
[~,~,~,tmaxeff] = tcurve(tstimcond,nummods,out.ttrial,0);
[~, v]           = eig(CX(1:(tstimcond-2)*nummods,1:(tstimcond-2)*nummods));
%% compute also the entropies
out.ent_order = 1:5;
for order = 1:5
    [out.ent(order),out.ent0,out.entmax] = calcent(s,order);
end
%% viz stuff.
if fig
    figure(1000);
    clf;
    nr = 3;
    nc = 4;
    %
    subplot(nr,nc,1:3);
    plot(s,'.-','markersize',10);hold on;
    plot(find(s == tstimcond-1),s(s == tstimcond-1),'+r','markersize',10);
    plot(find(s == tstimcond),s(s == tstimcond),'sg','markersize',10);
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
    thincolorbar('vertical');
    title('2nd order Transition Matrix');
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
    ylim([0 tmaxeff]*1.3);
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
    ylim(ylim*1.2);
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
    %
    subplot(nr,nc,9)
    imagesc(cov(X));
    thincolorbar('vertical');
    title(sprintf('covariance (rank: %g (%g))',rank(cov(X)),size(X,2)));axis off;
    %
    subplot(nr,nc,10)
    plot(diag(v),'ok-')
    title('Eigenvalue spectrum')
    box off;
end
%% create output
out.eff_overall   = 1./mean(effmat(2:tstimcond));
out.eff_estimate  = 1./effmat(2:tstimcond+1);
out.eff_contrasts = 1./effmat(tstimcond+2:end);
out.eff_max       = tmaxeff;
out.eff_norm      = out.eff_overall./out.eff_max*100;
out.probability   = count./out.ttrial;
