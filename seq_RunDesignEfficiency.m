function [E,power]=seq_RunDesignEfficiency
%[E,power]=seq_RunDesignEfficiency
%
%
%   Tests the efficiency of different experimental designs made of different
%   presentation possibilites. Uses spm machinery to generate, convolve and
%   produce design matrices. Works with spm_hrf, so not yet adapted to irf
%   of other modalities such as scr. POWER is the average power spectra of
%   different methods specified in INPUTS.
%
%   Dependency: seq_feargen_eyelab, spm_Volterra, spm_get_bf,
%   spm_get_onsets.
tseq          = 100;%how many to test
sampling_rate = 2;
% IRF
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
%% IRF power
%% fft 
fft_N                   = 2048*4;
power.freq              = 1/fft_N*[1:fft_N/2-1];
irf_f                   = fft(xBF.bf,fft_N);
irf_f                   = abs(irf_f).^2;
ind                     = 2:ceil(1+length(irf_f)/2)-1;
power.irf               = irf_f(ind);
%% function to test
dummy       = {};
seq_gen     = @(dummy) seq_feargen_eyelab(dummy{:});%function to generate sequences
%inputs to the sequencer
inputs      = {{'b' 1  'quasiuniform' [2 3 4 5]} {'b' 1 'random' [2 3 4 5] } {'b' 1  'exponential' [2 3 4 5]} ...
    {'b' 1 'quasiuniform' [2 4 6] } {'b' 1  'random' [2 4 6]} {'b' 1  'exponential' [2 4 6]}};
t_input     = length(inputs);
E           = nan(t_input,tseq);
%% make the simulation
c_input     = 0;
for input = inputs;
    c_input = c_input + 1;
    dummy   = seq_gen(input{1});%a dummy sequence
    tcond   = length(unique(dummy.cond_id));
    cums    = cumsum(dummy.isi);
    %% The constant part for the spm_function that will generate the DM    
    Sess  = [];
    for nt = 1:length(unique(dummy.cond_id));
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
    %% load the sequences
    nseq   = 0;    
    dummy  = zeros(length(ind),1);    
    while nseq <= tseq
        fprintf('\tRUN: %03d, SEQUENCE %03d of %03d...\n',c_input,nseq,tseq);
        nseq    = nseq + 1;
        seq     = seq_gen(input{1});                
        %% get the onsets
        for i = 1:length(unique(seq.cond_id));%one regressor for each condition
            SPM.Sess.U(i).ons  = cums( seq.cond_id == i );%- onsets    (in SPM.xBF.UNITS)
        end
        SPM.Sess.U = spm_get_ons(SPM,1);
        %%        
        % Convolve stimulus functions with basis functions
        [X,Xn,Fc]       = spm_Volterra(SPM.Sess.U,SPM.xBF.bf,SPM.xBF.Volterra);
        % Resample regressors at acquisition times (32 bin offset)
        X               = X((0:(SPM.nscan - 1))*fMRI_T + fMRI_T0 + 32,:);  
        % efficiency(nseq) =1./trace(Con*inv(X'*X)*Con');
        E(nseq,c_input) = 1./trace(inv(X'*X));
        %% Compute also the power spectrum of the X*[1..1]'
        Xf                = 2*abs(fft(mean(X,2),fft_N).^2);
        dummy             = dummy + Xf(ind)./tseq;
    end    
    power.y(:,c_input)    = dummy;
end
