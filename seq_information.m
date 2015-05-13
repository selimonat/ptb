function seq_information(s)
%seq_information(s)
%
%   Will spit out interesting information on the sequences. Assumes the
%   last and last -1 are oddballs and ucss.

fprintf('\n\n\n\n\n');
s = s(:);
conds     = unique(s);
tcond     = length(conds);%with the null event
tstimcond = max(conds);
ttrial    = length(s);
fprintf('Total trial: %g\n',ttrial);
fprintf('Probability of different conditions:\n');
for c = 1:tcond
    count(c) = sum(s == conds(c));
    fprintf('Cond %g: %g (%g)\n',conds(c),count(c),count(c)./ttrial);
end
fprintf('=====================================\n');
ucs     = sum(s == tstimcond-1);
csp     = sum(s == 1);
RR      = ucs./(ucs+csp)*100;
fprintf('RRei: %g percent.\n',RR);
fprintf('=====================================\n');
odd     = sum(s == (tstimcond));
OR      = odd./ttrial*100;
fprintf('ROdd: %g percent.\n',OR);
fprintf('=====================================\n');
fprintf('Transition Check\n');
n       = hist3([s(1:end-1) s(2:end)],{conds conds});
fprintf('=====================================\n');
[dummy_eff  dummy_det] = calc_meffdet(s, 10 , tstimcond, 3);
[~,~,max_det,max_eff]  = tcurve(tstimcond,10,length(s));
eff_norm               = dummy_eff(1)./max_eff(1);
fprintf('Efficiency: %g\n',dummy_eff(1));
fprintf('Normalized efficiency: %g percent\n',eff_norm(1)*100 );
fprintf('Power: %g\n',dummy_det(1));
fprintf('Normalized power: %g\n',dummy_det(1)/max_det(1)*100);
figure(1000);
fprintf('=====================================\n');
for isis = [1 2.5 3.5]
    fprintf('Expected duration: ISI of %g s -> %g minutes..\n',isis,isis*ttrial/60);
end

% viz stuff.
subplot(2,1,1);
imagesc(n);
colorbar;
subplot(2,1,2);
plot(s,'o-');
hold on;
% plot(find(s == tstimcond-1),s(s == tstimcond-1),'+r','markersize',10);
% plot(find(s == tstimcond),s(s == tstimcond),'sg','markersize',10);
hold off;





