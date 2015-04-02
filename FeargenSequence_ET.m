function [seq]=FeargenSequence_ET(face_stimuli, csp, tblock,method)


if ~isempty(csp) && length(csp) ~= 1
    csn   = [mod( csp(1) + 8/2-1, 8)+1 mod( csp(2)-8 + 8/2-1, 8)+1+8 ];
elseif ~isempty(csp) && length(csp) == 2
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
while nb <= tblock
    nb = nb + 1;
    seq.cond_id = [seq.cond_id Shuffle(stimuli)];
end
%%
% odd ball cancellation, by default there are as many oddballs as the number of
%blocks. we would like to have much less.
%detect the number of oddball trials
tOddball               = ceil(tblock*length(face_stimuli).*0.015);
fprintf('Will insert %03d oddballs\n',tOddball);
%replace 17 with a randomly selected stimulus face, but exclude csp and csn
%faces
oddball_i              = Shuffle(find(seq.cond_id == oddball));%all odballs
oddball_i              = oddball_i(tOddball+1:end);%to be cancelled
seq.cond_id(oddball_i) = [];%cancel the oddballs that are too much
%% Add the ucs trials, here we have to choices either by keeping the CSP faces seen by the subjects constant or not
if method == 1
    % this method 1 doesn't keep the amount of CSP faces (shocked +
    % non-schocked) equal to the repetition of other stimuli. so overall
    % participants see the CSP face a little bit more.
    tucs = ceil(tblock.*0.33*length(csp));
    fprintf('Will insert %03d tucss\n',tucs);
    %replace 18 with a randomly selected stimulus face, but exclude csp and csn
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
    tucs = ceil(tblock.*0.33);
    fprintf('Will insert %03d tucss\n',tucs);
    seq.ucs                = logical(zeros(1,length(seq.cond_id)));
    for csp_ = csp(:)'
        ucs_i                  = Shuffle(find(seq.cond_id == csp_));%all csp
        ucs_i                  = ucs_i(1:tucs);%
        seq.ucs(ucs_i)           = 1;
    end
    
end
%%
seq.oddball          = seq.cond_id == oddball;
seq.tTrial           = length(seq.cond_id);
%%
%Cond_ID to Stim_ID (which is not the same thing for oddballs for example)
seq.stim_id            = seq.cond_id;%this field is used to chose the face to be shown on the screen.
oddball_i              = seq.cond_id == oddball;
%avoid using CSP and CSN as the oddball stimuli
valid_oddballs         = setdiff(1:16,[csp csn]);
seq.stim_id(oddball_i) = RandSample( valid_oddballs,[1 sum(oddball_i)]);
%
if method == 1%this assignement is not necessary if method == 2
    if length(csp) == 1
        seq.stim_id(seq.ucs) = csp
    elseif length(csp) == 2
        i = Shuffle( find(seq.ucs));
        seq.stim_id(i(1:2:end)) = csp(1);
        seq.stim_id(i(2:2:end)) = csp(2);
    else
        keyboard
    end
end




%% final variables
seq.cross_position   = ones(1,seq.tTrial).*2;
%prestim durations should be smaller than ISI, right now they are [0.4 0.7]
mini_ps              = 0.4;
seq.prestim_duration = mini_ps+rand(1,seq.tTrial).*.3;
%
fprintf('The effective RR is %03d percent \n',sum(seq.ucs)./sum(ismember(seq.cond_id,csp))*100);

%% fix the ISIs
%isis        = [1 2 3 4];%in terms of TRs.
%seq.isi     = BalancedDist(seq.cond_id,isis);
mini_isi     = 0;
seq.isi      = mini_isi+exprnd(.75,[1 seq.tTrial]);
%add an additional [5 6] seconds following oddball and ucs trials
seq.isi(find(seq.ucs + seq.oddball)) = seq.isi(find(seq.ucs + seq.oddball)) + 5;
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