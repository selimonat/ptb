function [ok]=seq_feargen_constraints(seq,ucsafter,oddafter,oddbefore,slopeucs,toofarucs)
cons=NaN(5,1);
if ucsafter
cons(1)=IsEventAfter(seq.ucs,0.95);
else
end
if oddafter
cons(2)=IsEventAfter(seq.oddball,0.95);
end

if oddbefore
cons(3)=IsEventBefore(seq.oddball,0.1);
end

if slopeucs
cons(4)=SlopeCheck(seq.ucs);
end

if toofarucs
cons(5)=IsEventTooFar(seq.ucs,40);
end

if any(cons)==true
    ok=0;
else
    ok=1;
end


   function [out]=IsEventAfter(seq,part)
        %returns TRUE if there is any events after PART percentile of
        %trials
        out = sum(find(seq) > part*length(seq)) ~= 0;
    end

    function [out]=IsEventBefore(seq,part)
        %returns TRUE if there is any events before PART percentile of
        %trials
        out = sum(find(seq) < part*length(seq)) ~= 0;
    end

    function [out]=IsEventTooFar(seq,distance)
        %the longest distance where nothing happens.
        out = max(sort(diff(find(seq)))) > distance;
        if isempty(out)
            keyboard
            out=0;
        end
    end

    function [out]=SlopeCheck(seq)
        
        rate     = conv(double(seq),ones(1,30),'valid');
        X        = [(1:length(rate))' ones(length(rate),1)];
        [b bint] = regress( rate(:), X );
        if bint(1) <=0 && bint(1,2)>=0
            out = false;
        else
            out=true;
        end
        
    end
end

    