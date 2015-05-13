function [dm,cond] = seq_optseq22dm(filename)

%read the optseq
[time cond  c d e] = textread(filename,'%f%f%s%s%s','delimiter','\t');
time    = time/2;
i       = cond == 0;
cond(i) = [];
time(i) = [];
time(end+1) = time(end);

for i = 1:length(cond)
    seq.cond_id(i) = cond(i);
    seq.isi(i)     = time(i+1)-time(i);
end
%% IRF
sampling_rate         = 2;
TR                    = sampling_rate;%in seconds
fMRI_T                = 16;%spm_get_defaults('stats.fmri_t');
fMRI_T0               = 1;%spm_get_defaults('stats.fmri.t0');in spm8 it was 1, so I am keeping it here
xBF.T                 = fMRI_T;
xBF.T0                = fMRI_T0;
xBF.dt                = TR/xBF.T;
xBF.UNITS             = 'scans';
xBF.Volterra          = 1;
xBF.name              = 'hrf';
xBF                   = spm_get_bf(xBF);
%%
Sess  = [];
for nt = 1:length(unique(seq.cond_id));
    Sess.U(nt).dt     = xBF.dt;%- time bin (seconds)
    Sess.U(nt).name   = {sprintf('%02d',nt)};%- cell of names for each input or cause
    %no parametric modulation here
    Sess.U(nt).dur    =  0;%- durations (in SPM.xBF.UNITS)
    Sess.U(nt).P.name =  'none';
    Sess.U(nt).P.P    =  'none';
    Sess.U(nt).P.h    =  0;%- order of polynomial expansion
    Sess.U(nt).P.i    =  1;%- sub-indices of u pertaining to P
end
SPM.xBF                 = xBF;
cums                    = cumsum(seq.isi);
SPM.nscan               = max(cums)+5;
SPM.Sess                = Sess;


%% get the onsets
for i = 1:length(unique(seq.cond_id));%one regressor for each condition
    SPM.Sess.U(i).ons  = cums( seq.cond_id == i );%- onsets    (in SPM.xBF.UNITS)
end
SPM.Sess.U = spm_get_ons(SPM,1);
%%
% Convolve stimulus functions with basis functions
[X,Xn,Fc]       = spm_Volterra(SPM.Sess.U,SPM.xBF.bf,SPM.xBF.Volterra);
% Resample regressors at acquisition times (32 bin offset)
dm               = X((0:(SPM.nscan - 1))*fMRI_T + fMRI_T0 + 32,:);