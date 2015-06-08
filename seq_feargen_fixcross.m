function [CrossPosition] = seq_feargen_fixcross(s)
%SEQ_FEARGEN_FIXCROSS
%sets up all the fixation cross positions left/right from the face

CrossPosition = nan(1,s.tTrial);
tface           = length(unique(s.cond_id) > 0)-2;

radius=420; %in px
cross_direction = [0 180];
center          = [800 600];
for ncond = 1:tface
    ind                            = s.cond_id == ncond;
    CrossPosition(ind)           = seq_BalancedDist(ones(1,sum(ind)),cross_direction);
end

%Transitions to/from UCS/Oddball.
CrossPosition(isnan(CrossPosition)) = seq_BalancedDist(ones(1,sum(isnan(CrossPosition))),cross_direction);

CrossPosition = CrossPosition + rand(1,length(s.cond_id))*15-7.5;
CrossPosition=round([cosd(CrossPosition')*radius+center(1) sind(CrossPosition')*radius+center(2)]);



end

