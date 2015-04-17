function [seq]=FeargenSequence_ET(face_stimuli, csp, tblock,method)

% define parameters in the sequence
pOddball       = 0.015;
pReinforcement = 1/3;

% minimum ISI
mini_isi       = 1.5;
% minimum pre stimulus
mini_ps        = 0.4;
% additional seconds following oddball/UCS
addsecs=rand(1)+5;

tItem=length(face_stimuli);

% for the SecondOrderBalancing:



if ~isempty(csp) && length(csp) == 2;
    csn   = [mod( csp(1) + 8/2-1, 8)+1 mod( csp(2)-8 + 8/2-1, 8)+1+8 ];
elseif ~isempty(csp) && length(csp) == 1
    csn   = mod( csp(1) + 8/2-1, 8)+1;
else
    csn   = [];
end



oddball = 18;
ucs     = 17;
if method == 1
    stimuli = [face_stimuli oddball ucs];
else method == 2
    stimuli = [face_stimuli oddball];%ucs's are taken from the CSP indices
end
%% create the block-wise structure of trials
nb = 1;
seq.cond_id = [];
OK=0;
while ~OK
    % create tblock-2 blocks of stimuli (faces +oddball (+ucs))
%     while nb <= tblock-2
%         nb = nb + 1;
%         seq.cond_id = [seq.cond_id Shuffle(stimuli)];
%     end
    m=ones(length(stimuli),length(stimuli));
    m(1:2:end-2,2:2:end-2)=2;
    m(2:2:end-2,1:2:end-2)=2;
    [S,i]=SecondOrderBalancedSequence(m,1);
    % add one block of face_stimuli at beginning and end
    seq.cond_id= [Shuffle(face_stimuli) S Shuffle(face_stimuli)];
    seq.tfacetrials=length(find(seq.cond_id<=length(face_stimuli)));
    %%
    % odd ball cancellation, by default there are as many oddballs as the number of
    %blocks. we would like to have much less.
    %detect the number of oddball trials we need:
% based on number of trials, but only face_stimuli trials
    tOddball               = ceil(seq.tfacetrials.*pOddball);
    fprintf('Will insert %03d oddballs\n',tOddball);
    
    oddball_i              = Shuffle(find(seq.cond_id == oddball));%all oddballs
    oddball_i              = oddball_i(tOddball+1:end);%to be cancelled
    seq.cond_id(oddball_i) = [];%cancel the oddballs that are too much
    %% Add the ucs trials, here we have to choose either by keeping the CSP faces seen by the subjects constant or not
    if method == 1
        % this method 1 doesn't keep the amount of CSP faces (shocked +
        % non-schocked) equal to the repetition of other stimuli. so overall
        % participants see the CSP face a little bit more.
%         tucs = round(tblock.*pReinforcement)*length(csp);
        tucs = ceil(seq.tfacetrials/length(face_stimuli).*pReinforcement*length(face_stimuli)/8);
        fprintf('Will insert %03d tucss\n',tucs);
        %replace 17 with a randomly selected stimulus face, but exclude csp and csn
        %faces
        ucs_i                  = Shuffle(find(seq.cond_id == ucs));%all ucs
        ucs_i                  = ucs_i(tucs+1:end);%to be cancelled
        seq.cond_id(ucs_i)     = [];
        seq.ucs                = seq.cond_id == ucs;
        
    elseif method == 2
        %%
        %this method allocate existing CSP faces randomly to UCS, making the total
        %CSP repetition same as any other stimuli, but unshocked CSP stimuli is
        %less then the rest
        tucs = ceil(tblock.*pReinforcement);
        tucs = ceil(trep.*pReinforcement);
        fprintf('Will insert %03d tucss\n',tucs);
        seq.ucs                = logical(zeros(1,length(seq.cond_id)));
        for csp_ = csp(:)'
            ucs_i                  = Shuffle(find(seq.cond_id == csp_));%all csp
            ucs_i                  = ucs_i(1:tucs);%ucs that we want to keep
            seq.ucs(ucs_i)           = 1;
        end
        
    end
    %%
    seq.oddball          = seq.cond_id == oddball;
    seq.tTrial           = length(seq.cond_id);
    %%
    %Cond_ID to Stim_ID (which is not the same thing for oddballs for
    %example)
    seq.stim_id            = seq.cond_id;%this field is used to chose the face to be shown on the screen.
    oddball_i              = seq.cond_id == oddball;
    %avoid using CSP and CSN as the oddball stimuli
    % Select oddballs from orthogonal faces instead
    % valid_oddballs         = setdiff(1:16,[csp csn]);
    valid_oddballs         = mod([csp csn]+2,16);
    
    seq.stim_id(oddball_i) = RandSample( valid_oddballs,[1 sum(oddball_i)]);
    % now give ucs trials one of the two CSP as stim_id
    if method == 1%this assignement is not necessary if method == 2
        if length(csp) == 1
            seq.stim_id(seq.ucs) = csp;
        elseif length(csp) == 2
            i = Shuffle( find(seq.ucs));
            seq.stim_id(i(1:2:end)) = csp(1);
            seq.stim_id(i(2:2:end)) = csp(2);
            fprintf('Chose %d CSP1, and %d CSP2.',length(i(1:2:end)),length(i(2:2:end)));
            
        else
            keyboard
        end
    end
   
% OK=sanity_check;
OK=1;    
    
end

%% final variables
seq.cross_position   = ones(1,seq.tTrial).*2;
%prestim durations should be smaller than ISI, right now they are [0.4 0.7]
seq.prestim_duration = mini_ps+rand(1,seq.tTrial).*.3;
%
fprintf('The effective RR is %g percent \n',sum(seq.ucs)./sum(ismember(seq.cond_id,csp))*100);

%% fix the ISIs
%isis        = [1 2 3 4];%in terms of TRs.
%seq.isi     = BalancedDist(seq.cond_id,isis);
dummy=exprnd(.75,[1 seq.tTrial]);
seq.isi      = mini_isi+floor(dummy*2)/2;
%add an additional [addsecs] seconds following oddball and ucs trials

seq.isi(find(seq.ucs + seq.oddball)) = seq.isi(find(seq.ucs + seq.oddball)) + addsecs;
duration = sum(seq.isi)+length(seq.cond_id)*1.5;
fprintf('Total duration is %02g minutes\n',duration./60);


%% viz stuff.
visualization =1;
if visualization == 1
    plot(1:length(seq.ucs==1 ),seq.cond_id,'o-');
    hold on;
    plot(find(seq.ucs == 1),seq.cond_id(seq.ucs == 1),'+r','markersize',10);
    plot(find(seq.oddball == 1),seq.cond_id(seq.oddball == 1),'sg','markersize',10);
    hold off;
end

function [OK]=sanity_check

% if ~isempty(oddball) && ~isempty(ucs)
% % check if number of oddballs is correct
if sum(seq.oddball)==tOddball;
    % % check if number of UCS is correct
    if sum(seq.ucs)==tucs;
        
        % check transition matrix
        %     that's Lea's version
        %         n = length(seq.stim_id)-1;
        %         TM = zeros(tItem,tItem);
        %         for t = 1:n
        %             TM(seq.stim_id(t), seq.stim_id(t + 1)) = TM(seq.stim_id(t), seq.stim_id(t + 1)) + 1;
        %         endi
        %         E=length(seq.stim_id)/(tItem^2);
        %         chi2=sum(sum((TM-E).^2./E));
        
        Seq=seq.stim_id;
        [n c] = hist3([Seq(1:end-1) ;Seq(2:end)]',{1:tItem 1:tItem});
        %only proceed if all bars in n are not bigger than ...3
        if ~any(n>3)
           
                

        % check for time trends
        rate=conv(double(seq.ucs),ones(1,20),'valid')';
        X = [[1:length(rate)]' ones(length(rate),1)];
        [b bint]= regress( rate, X );
        if sum(rate > 4) == 0
            if bint(1)<=0 && bint(1,2)>=0
                %then 0 is in the CI, so it's not significant
                OK=1;
            else
                OK=0;
                fprintf('Time Trend significant...Creating New Sequence.')
            end
        end
    else OK=0;
        fprintf('%d oddballs found instead of %d!',sum(seq.oddball),tOddball)
    end
else OK=0;
    fprintf('%d UCS found instead of %d!',sum(seq.ucs),tucs)
end
end
