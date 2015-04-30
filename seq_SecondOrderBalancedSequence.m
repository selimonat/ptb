function [S,i]=SecondOrderBalancedSequence(repetition,start_condition)
%[S,i]=SecondOrderBalancedSequence(tItem,repetition,start_condition)
%
%   Generates a so-called t1r1 sequence, see Aguirre for fMRI applications.
%   These sequences are balanced for second-order transitions. 
%   The length of repetition determines the number of conditions, and each
%   value in the repetition vector determines how many times a given
%   transition occurs. For example, a vector [5 5 5 1] means that the
%   sequence contains 5 transitions between conditions 1 to 3 and only 1
%   transition to the 4th condition.
%
%   Note that the total number of elements in the sequence will be
%   TITEM*REPETITION+1, the  +1 is needed to make all  transitions
%   possible. This additional trial can be used as a dummy trial.
%   START_CONDITION indicates the starting condition of the 
%   sequence.
%
%   If REPETITION is a matrix, it is considered as a transition matrix as
%   such. Thus arbitrary shaped transition matrices can be used, please
%   note that not all transition matrices will converge to a solution.
%
%   I returns the position of a given transition in the sequence S. For
%   example squeeze(i(1,1,:)) would return the position of the 1 to 1
%   transition in S. The index is for the first element of the transition.
%
%   Example Usage:
%   as a vector:
%   [S,i]=SecondOrderBalancedSequence(ones(1,8)*34,1)
%   as a matrice:
%   m = [1 2 1 2 1;2 1 2 1 2;1 2 1 2 1; 2 1 2 1 2;1 2 1 2 1];;
%   [S,i]=SecondOrderBalancedSequence(m,1); 
%

%%
%T=ones(tItem,tItem) .* repetition;%the old way, equal number of trials
%for each condition...
%new way:
if isvector(repetition);
    c = 0;
    T = [];
    repetition = repetition(:)';
    for x_ = repetition(end:-1:1)
        c  = c+1;
        T(1:length(repetition)-c+1,1:length(repetition)-c+1) = x_;
    end        
else
    fprintf('Matrix given, will treat the 2nd argument as count matrix.\n');
    T = repetition;    
end
%% check whether the count matrix is valid.
    if sum(sum(abs(T - round(T)) == 0)) ~= length(T(:))
        S=[];
        fprintf('The repetition vector should consists of integers\n');
        return
    end
Tori = T;
%%
success = 0;
while ~success%when T sums to 0
    %
    T   = Tori;
    row = ceil(start_condition);%the first stimulus.
    col = randsample(find(T(row,:)),1);%ceil(rand*tItem);%the second stimulus.
    S   = [row col];
    ok  = 1;
    counter = 0;
    while ok%it is OK when next stim is correctly selected
        %store the location of the transition on the sequence
        counter = counter + 1;
        i(row,col,T(row,col)) = counter;
        
        %decrement this value
        T(row,col)=T(row,col)-1;
        
        row=col;%second stimulus becomes the first
        col=[];%we have to select the new second one now        
        col_pool=find(T(row,:));
        if isempty(col_pool)%no more transition possible
            ok=0;
        else
            %pick one of the possible transitions
            %This is the old way, this generates problems when one of the
            %conditions has significantly less repetitions, it results in
            %those conditions with too few repetitions to cluster at the
            %very beginning of the stimulus sequence:
            %next_stim = ceil(rand*length(col_pool));
            %the new methods weights the selection process accroding to the
            %proportion of time a condition is repeated.
            %T(row,col_pool) represents the probabilities
            next_stim = SyntFix_Core(Tori(row,col_pool),1);
            col       = col_pool(next_stim);
            S         = [S col];
        end
        
    end
    
    if sum(T(:))==0
        success=1;
        %remove the zeros due to unequal transition numbers
        i(i == 0) =NaN;
    end
end



% %
% % fprintf('Checking balancing...\n')
% % [n c] = hist3([S(1:end-1) ;S(2:end)]',{1:tItem 1:tItem});
% % imagesc(n);colorbar;drawnow;
% % for i = 1:tItem;co(i) = sum(S == i);end;
% % if ~(sum(n(:) == repetition) == tItem.^2);
% %     fprintf('Sequence unbalanced!!!...\n')
% %     keyboard
% %   %  S = [];
% % else
% %     fprintf('Sequence is balanced...\n')
% % end
% % fprintf('first order histogram:\n')
% % mat2str(co)
% % fprintf('second order balancing:\n');
% % display(n)

    function [i] = SyntFix_Core(saliency,tfix);
        %[i] = SyntFix_Core(s,tfix);
        %
        %Given a matrix SALIENCY representing a topographic saliency, this function
        %simulates fixation locations of TFIX fixations. SALIENCY may be a fixation
        %map, a data-driven saliency map or a click map or any other matrix of 2D.
        %
        %
        %Selim, 31-Jan-2008 20:09:22
        
        
        
        %fixation init
        i   = zeros(tfix,1);
        %%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        %%the reason for 0.66: it makes the (oddball + ucs) probabilities
        %across time as flat as possible over time;
        %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        s   = cumsum(saliency(:).^(0.66));
        s   = [ 0 ; s];
        %we need to add one zero entry to the cumulatif sum, otherwise there is no
        %possibility that the first pixel is ever selected whatever its saliency
        %is. another intuitive reason is that cumsum eats one of the entries
        %therefore possible fixatable position decreases by one.
        %
        %random points.
        r        = rand(1,tfix)*max(s);
        %for each of the random points now we find the spatial location it
        %corresponds to...
        for nf = 1:tfix
            %
            i(nf,1)   = find( s-r(nf)<=0,1,'last');
            %
            %we will take the last negative or zero entry in DUMMY; The index of
            %this entry will be the location that is fixated...
        end
    end
end