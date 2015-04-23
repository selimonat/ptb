%create contrast
%
Con = [ 1   0  0  0  0  0  0 -1 0 0; ...
       -1   1  0  0  0  0  0  0 0 0; ...
        0  -1  1  0  0  0  0  0 0 0; ...
        0   0 -1  1  0  0  0  0 0 0; ...
        0   0  0  -1 1  0  0  0 0 0; ...
        0   0  0  0  -1 1  0  0 0 0; ...
        0   0  0  0  0  -1 1  0 0 0; ...
        0   0  0  0  0  0  -1 1 0 0; ...
        0   0  0  0  0  0  0  0 0 0; ...
        0   0  0  0  0  0  0  0 0 0; ...
    ]

%% load the sequences
load /home/onat/Documents/Experiments/FearGeneralization_Scanner/Sequences/BigPool.mat
Seq = out.S;

%generate an HRF
hrf_resol = 0.5; % this is only done to get a more accurate convolution, later everything is downsampled again
hrf=spm_hrf(hrf_resol);
efficiency = zeros(1,size(Seq,2));

for nseq= 1:size(Seq,2);
    nseq
    %% Get the Sequence
    stim_id  = Seq(:,nseq);
    isi      = randsample(4,length(stim_id),1);
    
    %%
    time     = cumsum(isi+1);
    design_matrix = zeros(time(end),length(unique(stim_id)));
    for nstim = 1:length(stim_id)
        design_matrix( time(nstim) , stim_id(nstim)) = 1;
    end
    
    %% Create a Design Matrix
    %%
    HPF     = 128;
    TR      = 2;
    n_scans = size(design_matrix,1);
    
    %%
    conv_designmat = conv2(hrf,1,design_matrix);
    conv_designmat(:,end) = 1; % constant
    conv_designmat = conv_designmat(1:(TR/hrf_resol):end,:);
    K = struct('HParam',HPF,'row',1:size(conv_designmat,1),'RT',TR);
    
    X = spm_filter(K,conv_designmat);
    
    
    efficiency(nseq) =1./trace(Con*inv(X'*X)*Con');
end
