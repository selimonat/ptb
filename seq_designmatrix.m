function [X] = seq_designmatrix(seq,isi);
%[X] = seq_designmatrix(seq,isi);
%
%   Will generate a design matrix based on the condition labels in seq and
%   isis in ISI (in seconds). This 

TR                    = 1;
fMRI_T                = 16;%spm_get_defaults('stats.fmri_t');
fMRI_T0               = 1;%spm_get_defaults('stats.fmri.t0');in spm8 it was 1, so I am keeping it here
xBF.T                 = fMRI_T;
xBF.T0                = fMRI_T0;
xBF.dt                = TR/xBF.T;
xBF.UNITS             = 'scans';
xBF.Volterra          = 1;
xBF.name              = 'hrf';
xBF                   = spm_get_bf(xBF);

onsets                = cumsum(isi);
%%
tcond = max(seq);
for i = 1:tcond;%one regressor for each condition
    Sess.U(i).dt     = xBF.dt;%- time bin (seconds)
    
    Sess.U(i).ons    = onsets( seq == i );%- onsets    (in SPM.xBF.UNITS)
    Sess.U(i).name   = {sprintf('%02d',i)};%- cell of names for each input or cause
    
    %no parametric modulation here
    Sess.U(i).dur    =  repmat(0,length(Sess.U(i).ons),1);%- durations (in SPM.xBF.UNITS)
    Sess.U(i).P.name =  'none';
    Sess.U(i).P.P    =  'none';
    Sess.U(i).P.h    =  0;%- order of polynomial expansion
    Sess.U(i).P.i    =  1;%- sub-indices of u pertaining to P
end
%
k                       = max(onsets)+6;
SPM.xBF                 = xBF;
SPM.nscan               = k;
SPM.Sess                = Sess;
SPM.Sess.U              = spm_get_ons(SPM,1);

%%
% Convolve stimulus functions with basis functions
[X,Xn,Fc]               = spm_Volterra(SPM.Sess.U,SPM.xBF.bf,SPM.xBF.Volterra);
% Resample regressors at acquisition times (32 bin offset)
X                       = X((0:(k - 1))*fMRI_T + fMRI_T0 + 32,:);