function [pool]=seq_feargen_eyelab_filterpool(pool)
%[pool]=seq_feargen_eyelab_filterpool(pool)
%
%   Will sort the sequence pool created by seq_feargen_eyelab_fillpool
%   based on efficiency.

%%
stats = [pool(:).stats];
eff   = [stats(:).eff];
eff   = eff(1,:);%global efficiency
eff   = eff(:);
ent   = vertcat(stats(:).ent);
figure;
subplot(3,1,1);hist(eff);title('efficiencies');
subplot(3,1,2);hist(ent(:,3));title('entropy');
subplot(3,1,3);plot(ent(:,3),eff,'o');

[~,i] = sort(eff,1,'descend');
pool  = pool(i);