function [res,stats]=FeargenSequencerAnalyzer(BigPool)

stats = [];
nphase = 1;
tTrial = size(BigPool,1);
for i = 1:size(BigPool,2)
    fprintf('=====\n');
    stim_id = BigPool(:,i);
    
    ucs = BigPool(:,i) == 9;
    oddball = BigPool(:,i) == 10;   
    
        
    res(i,:) = [ucs_check oddball_check common_check];
    
    if sum(res(i,:),2) == 3
                    figure(1)                                
                    rate = conv(double(new),ones(1,30),'valid');                
                    X = [[1:length(rate)]' ones(length(rate),1)];
                [b bint]= regress( rate, X );
                if sum(rate > 4) == 0
                if bint(1)<=0 && bint(1,2)>=0
                    plot(rate,'ko-');  
                hold on
                hold on;
                plot(X*b,'r');
                hold off
                figure(2)                
                plot(oddball,'bo-');
                hold on
                plot(ucs,'ro-')
                hold off;
                bint
                %plot(conv(double(ucs),ones(1,30),'same'),'ro-');
                %plot(conv(double(oddball),ones(1,30),'same'),'bo-');
                %hold off
                drawnow;
                pause;
                end
                end
    end
end



function out = ucs_check
        %returns one if the conditions is met
        out=false;
        if ~isempty(ucs);            
            %CONDITIONING
            
            if nphase == 2
           
                
                %BASELINE AND TEST
            elseif nphase == 1
                %no 3 UCSs in a serie
                if sum(conv(double(ucs),[1 1 1],'same') == 3) == 0;
                    fprintf('UCS+\n')
                    %Exactly zero UCS at the last part
                    if sum(find(ucs) >= 0.9*tTrial) == 0
                        fprintf('UCS++\n')                        
                        %no more than 2 ucs per 10 trials
                        if sum(conv(double(ucs),ones(1,30),'same') > 3) == 0;
                        %    %are UCSs equally balanced between first and second halves
                            if sum(find(ucs) <= ceil(tTrial./2)) == round(sum(ucs)/2);                        
                                fprintf('UCS++++\n')
                                out = true;
                            end
                        end
                    end
                end
            end
            %i dont really know what at the conditioning phase there should
            %be no trials at the end of the phase? if at all, may be this
            %is more relevant for the Baseline and Test Phases
            %%no UCS at the last 90% trials
            %RIGHT NOW THIS IS OFF, It has to be discussed?
        end
        %                     out = true;
    end
    function [out]=oddball_check
        out=false;
        %returns one if the condition is met
        if ~isempty(oddball);
            if nphase == 2
                
             
            elseif nphase == 1
                
                    %if sum(find(oddball) <= ceil(tTrial./2)) == round(sum(oddball)/2);
                    %we don't want to have 3 times oddball stimuli one
                    %after another. 2 times, we cannot avoid because of the
                    %balancing.
                    %if sum(conv(double(oddball),[1 1 1]) == 3) == 0;
                    %if sum(conv(double(oddball),ones(1,20)) > 2) == 0;
                        %the closest distance (excluding the one case
                        %where two ucs's follow each other) is 9 trials
                        x = sort(diff(find(oddball)));
                        if x(2) >= 10
                            fprintf('oddball+\n')
                            out = true;
                        end
                    %end
                    %end
            end
        end
    end

    function [out]=common_check
        out=false;
        %returns one if the condition is met
        if ~isempty(oddball) && ~isempty(ucs) && ucs_check && oddball_check
            new = oddball+ucs;
            if nphase == 2
              
              
                
            elseif nphase == 1%only for the baseline condition
                
                
                %no distance closer than 4 trials (excluding what has to be
                %there in terms of 1 trial distance) and no longer than 30
                %trials, that is something has to happen within the next 30
                %trials...
%                 if sum(conv(double(new),[1 1 1]) == 3) == 0;
%                     x = sort(diff(find(new)));
%                 stats.distance(i) = max(x);
%                 if x(5) >= 5 && (max(x) <= 40)

%                 if sum(conv(double(new),ones(1,30),'valid') > 5) == 0;
%                     if sum(conv(double(new),ones(1,40),'valid') < 1) == 0;
                        fprintf('common+\n')
                        out = true;
%                     end
%                 end
%                 end
%                 end
            end
        end
    end


end




