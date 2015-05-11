function seq_feargen_eyelab_fillpool(varargin)
%seq_feargen_eyelab_fillpool(varargin)
%
%   Generates pool of second order sequences. Will run forever. The results
%   of this pool has first to be selected by efficiency.
%
%   VARARGIN is fed to seq_feargen_eyelab. 
%
%   Example: 
%   seq_feargen_eyelab_fillpool('tshort','constant',[2.5]);
%   would generate sequence pool for test phase.
%
%

path2pool = sprintf('%s/%s_%s.mat',fileparts(which(mfilename)),mfilename,varargin{1});
pool = [];
try %try to get what is already there
load(path2pool);
end

while 1
    pool = [pool seq_feargen_eyelab(varargin{:})]; 
    fprintf('run no %d...\n',length(pool));
    save(path2pool,pool);
end
