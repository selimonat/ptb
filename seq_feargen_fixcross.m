function [CrossPosition] = seq_feargen_fixcross(s)
%SEQ_FEARGEN_FIXCROSS
%sets up all the fixation cross positions left/right from the face

CrossPosition = nan(1,s.tTrial);
% tface           = length(unique(s.cond_id) > 0)-2;
ok = 0;
while ~ok
    radius = 290;%590; %in px
    cross_direction = [0 180];
    center          = [1920 1200]./2;%[800 600];
    for ncond = 1:9
        ind                  = s.cond_id == ncond;
        CrossPosition(ind)   = seq_BalancedDist(ones(1,sum(ind)),cross_direction);
    end
    
    a = histc(CrossPosition,cross_direction);
    if (a(1)/sum(a) < .45) || (a(1)/sum(a) > .55)
        ok = 0;
        fprintf('Not distributed well enough, repeating..\n')
    else
        ok = 1;
    end
end
% %Transitions to/from UCS/Oddball.
% CrossPosition(isnan(CrossPosition)) = seq_BalancedDist(ones(1,sum(isnan(CrossPosition))),cross_direction);
 
CrossPosition = CrossPosition + rand(1,length(s.cond_id))*30-15;
CrossPosition=round([cosd(CrossPosition')*radius+center(1) sind(CrossPosition')*radius+center(2)]);

end

