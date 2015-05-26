function [s] = seq_feargen_fixcross(s)
%SEQ_FEARGEN_FIXCROSS
%sets up all the fixation cross positions left/right from the face

s.CrossPosition = nan(1,s.tTrial);
tface           = length(unique(s.cond_id) > 0)-2;

radius=590; %in px
cross_direction = [0 180];
center          = [800 600];
for ncond = 1:tface
    ind                            = s.cond_id == ncond;
    s.CrossPosition(ind)           = seq_BalancedDist(ones(1,sum(ind)),cross_direction);
end

%Transitions to/from UCS/Oddball.
s.CrossPosition(isnan(s.CrossPosition)) = seq_BalancedDist(ones(1,sum(isnan(s.CrossPosition))),cross_direction);

s.CrossPosition = s.CrossPosition + rand(1,length(s.cond_id))*30-15;
s.CrossPosition=round([cosd(s.CrossPosition')*radius+center(1) sind(s.CrossPosition')*radius+center(2)]);



end

