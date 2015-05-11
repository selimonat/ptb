function [s]=seq_feargen_eyelab_pool2subjects(varargin)
%[s]=seq_feargen_eyelab_pool2subjects(pool,phases)
%[s]=seq_feargen_eyelab_pool2subjects(pool,phases,pool2,phases2,...)
%
%   Will distribute sequences in a pool (following filtering) to subjects,
%   phases and runs. This can be then be read by the stimulus presentation
%   function.
%
%   Examples:
%   This distributes pool into phases 1 and 3
%   [s]=seq_feargen_eyelab_pool2subjects(pool,[1 3]);
%   This distributes pool into phases 1 and 3 and pool2 into phase 2.
%   [s]=seq_feargen_eyelab_pool2subjects(pool,[1 3],pool2,[2]);
%
%

%%

trun   = 5;%how many runs per subject, each run is about 8-10 minutes so this has to be decided,
%but 5 seems to be a reasonable upper limit.
%
for v = 1:2:length(varargin)/2;
    %will distribute sequences POOL to phases.
    pool   = varargin{v};
    phases = varargin{v+1};
    tseq   = length(pool);
    %For each phase fill in the phase and runs with randomly selected
    %sequences.
    for ns = 1:100
        for run = 1:trun
            %select a sequence
            dummy                   = pool(randsample(1:tseq,1));
            %distribute the selected seq to phases
            for nphase = phases
                %randomly assign one sequence to both c and b phases.
                s(ns).phase(nphase).run(run) = dummy;
            end
        end
    end
end