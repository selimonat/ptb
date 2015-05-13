function [X]=seq_seq2dm(seq)
%[X]=seq_seq2dm(seq)
%
%   SEQ is the output of seq_SecondOrderBalancedSequence or compatible
%   (e.g. presentation protocol file). This function returns a spm-like
%   design matrix based on canonical HRF definition from SEQ. SEQ has to
%   have ISI and COND_ID fields. 

cums                    = cumsum(seq.isi);
%
TR                    = 2;%in seconds
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
SPM.nscan               = max(cums)+5;
SPM.Sess                = Sess;
%% get the onsets
for i = 1:length(unique(seq.cond_id));%one regressor for each condition
    SPM.Sess.U(i).ons  = cums( seq.cond_id == i );%- onsets    (in SPM.xBF.UNITS)
end
SPM.Sess.U = spm_get_ons(SPM,1);
%%
% Convolve stimulus functions with basis functions
[X,~,~]       = spm_Volterra(SPM.Sess.U,SPM.xBF.bf,SPM.xBF.Volterra);
% Resample regressors at acquisition times (32 bin offset)
X               = X((0:(SPM.nscan - 1))*fMRI_T + fMRI_T0 + 32,:);