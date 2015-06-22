function [o,out]=fearcloud_fitgauss(subjects,runs)
% gets aligned mean ratings per subject via the isn_GetRatings function,
% then fits gaussian to this data
o=[];
cs=0;
for sub=subjects
    cs=cs+1;
    cr=0;
    for run=runs
        cr=cr+1;
        r=isn_GetRatings(sub,run,1);
        out = FitGauss(deg2rad(-135:45:180),r,3);
        o.a(cs,cr)=out.Est(1);
        o.sigma(cs,cr)=rad2deg(out.Est(2));
        o.p(cs,cr)=out.pval;
        o.likelihood(cs,cr)=out.Likelihood;
    end
end

end

